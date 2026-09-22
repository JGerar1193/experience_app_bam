# Trigger para notificaciones de compra en Firebase Functions
# Este archivo está pensado para emitir una push notification cuando se crea
# una orden en Firestore y además deja ejemplos de otros triggers útiles.

from firebase_admin import firestore, initialize_app, messaging
from firebase_functions import firestore_fn, https_fn, identity_fn
from firebase_functions.options import set_global_options

set_global_options(max_instances=10)
initialize_app()


@https_fn.on_request()
def on_request_example(req: https_fn.Request) -> https_fn.Response:
    print("--------------------------------")
    print("SE ESTA EJECUTANDO LA FUNCION DE PRUEBA")
    print("--------------------------------")
    return https_fn.Response("Hello world!")


@firestore_fn.on_document_created(document="orders/{orderId}")
def on_order_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    print("--------------------------------")
    print("SE ESTA EJECUTANDO EL TRIGGER DE PEDIDO")
    print("--------------------------------")

    snapshot = event.data
    if snapshot is None:
        return

    order_data = snapshot.to_dict()
    user_id = order_data.get("userId")
    order_id = event.params.get("orderId")
    total = order_data.get("total", 0)

    if not user_id or not order_id:
        print("Pedido sin userId o orderId. Se omite la notificacion.")
        return

    db = firestore.client()
    devices_ref = db.collection("users").document(user_id).collection("devices")
    tokens = []

    for device in devices_ref.stream():
        token = device.to_dict().get("token")
        if token:
            tokens.append(token)

    if not tokens:
        print(f"No hay tokens FCM para el usuario {user_id}.")
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title="¡Compra confirmada!",
            body=f"Tu pedido por ${total:,.2f} fue procesado exitosamente.",
        ),
        data={
            "route": "order_detail",
            "orderId": order_id,
        },
        tokens=tokens,
    )

    response = messaging.send_each_for_multicast(message)
    print(f"Notificaciones enviadas: {response.success_count} exitosas; {response.failure_count} fallidas")

    if response.failure_count:
        for idx, resp in enumerate(response.responses):
            if not resp.success:
                print(f"Token fallido #{idx}: {resp.exception}")


@firestore_fn.on_document_created(document="users/{userId}")
def on_user_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    print("--------------------------------")
    print("SE ESTA EJECUTANDO EL TRIGGER DE USUARIO")
    print("--------------------------------")

    user_id = event.params["userId"]
    user_data = event.data.to_dict() if event.data else {}
    print(f"User created: {user_id}, data: {user_data}")


@identity_fn.before_user_created()
def create_user(event: identity_fn.AuthBlockingEvent) -> None:
    print("--------------------------------")
    print("SE ESTA EJECUTANDO EL TRIGGER DE PRUEBA DE IDENTITY")
    print("--------------------------------")

    print(f"User created: {event.data.uid}")