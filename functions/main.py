# Cloud Functions de la app: createOrder (cobro + creación de la orden),
# notificación push al crear una orden y triggers de ejemplo.

import json
import urllib.error
import urllib.request

from firebase_admin import firestore, initialize_app, messaging
from firebase_functions import firestore_fn, https_fn
from firebase_functions.options import set_global_options

set_global_options(max_instances=10)
initialize_app()

PAYMENT_API_URL = "https://processpayment-sfdkfoab2q-uc.a.run.app"
print("DEBUG main.py cargado (version diagnostico)")
MAX_QUANTITY = 99


@https_fn.on_request()
def on_request_example(req: https_fn.Request) -> https_fn.Response:
    print("--------------------------------")
    print("SE ESTA EJECUTANDO LA FUNCION DE PRUEBA")
    print("--------------------------------")
    return https_fn.Response("Hello world!")


def _charge(card_number: str, amount: float) -> dict:
    payload = json.dumps({
        "cardNumber": card_number,
        "amount": amount,
        "currency": "USD",
    }).encode("utf-8")
    request = urllib.request.Request(
        PAYMENT_API_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        try:
            return json.loads(error.read().decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            return {"success": False, "message": f"Pago rechazado (HTTP {error.code})"}


def _mask_card(card_number: str) -> str:
    """Conserva BIN (6 primeros) y últimos 4; nunca el número completo."""
    digits = "".join(ch for ch in card_number if ch.isdigit())
    if len(digits) < 12:
        return "****"
    return f"{digits[:6]}{'*' * (len(digits) - 10)}{digits[-4:]}"


@https_fn.on_call()
def create_order(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, "Debes iniciar sesión.")

    data = req.data or {}
    raw_items = data.get("items") or []
    card_number = str(data.get("cardNumber") or "").strip()
    print(f"DEBUG create_order items={raw_items!r}")

    if not raw_items or not isinstance(raw_items, list):
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "El carrito está vacío.")
    if not card_number:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Falta la tarjeta de pago.")

    db = firestore.client()
    user_id = req.auth.uid
    order_items = []
    total = 0.0

    # El precio se toma siempre de Firestore; el cliente nunca decide el total.
    for raw in raw_items:
        product_id = str(raw.get("productId") or "")
        quantity = raw.get("quantity")
        size = str(raw.get("selectedSize") or "")
        color = str(raw.get("selectedColor") or "")

        if not isinstance(quantity, int) or not 1 <= quantity <= MAX_QUANTITY:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Cantidad inválida.")

        snapshot = db.collection("Products").document(product_id).get()
        if not snapshot.exists:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.NOT_FOUND, "Producto no disponible.")

        product = snapshot.to_dict()
        if size not in (product.get("sizes") or []) or color not in (product.get("colors") or []):
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, "Talla o color no válidos.")

        price = float(product.get("price", product.get("Price", 0)))
        total += price * quantity
        product["id"] = snapshot.id
        order_items.append({
            "product": product,
            "quantity": quantity,
            "selectedSize": size,
            "selectedColor": color,
        })

    total = round(total, 2)
    payment = _charge(card_number, total)
    if not payment.get("success"):
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            payment.get("message") or "El pago fue rechazado.",
        )

    order_ref = db.collection("orders").document()
    order_ref.set({
        "userId": user_id,
        "items": order_items,
        "total": total,
        "paymentMethod": "credit_card",
        "selectedCard": _mask_card(card_number),
        "status": "paid",
        "transactionId": payment.get("transactionId"),
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    return {"orderId": order_ref.id, "total": total}


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
