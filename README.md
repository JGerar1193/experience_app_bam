# experience_app

Aplicación Flutter de e-commerce con Firebase (Auth, Firestore, Storage, Cloud Functions y notificaciones).

## Requisitos

- Flutter SDK (con Dart compatible con `pubspec.yaml`)
- Firebase CLI (`npm i -g firebase-tools`)
- Python 3.14 para Cloud Functions (runtime definido en `firebase.json`)

## Configuración

```bash
flutter pub get
flutter analyze
flutter test
```

## Modelo de seguridad

- **Pagos:** el cobro se hace solo en la Cloud Function `create_order` (`functions/main.py`). El total se calcula en el servidor a partir de `Products`; el cliente no envía precios.
- **Roles:** `users/{uid}.role` (`user` o `admin`). Los clientes no pueden cambiar su propio rol. Las reglas de Firestore y Storage usan este campo para restringir la gestión de productos.
- **Pedidos:** se crean únicamente desde la función; el cliente solo puede leer sus pedidos.
- **Tarjetas:** en la app solo se guardan BIN y últimos 4 dígitos. Las tarjetas de prueba son las únicas que se pueden usar en el checkout.
- **Autenticación:** solo Firebase Auth. Recuperación de contraseña por correo.

## Despliegue

```bash
firebase deploy --only firestore:rules,storage
firebase deploy --only functions
```

Las reglas están en [firestore.rules](firestore.rules) y [storage.rules](storage.rules).

## Limitaciones conocidas

- No hay control de inventario: los productos no tienen campo de stock.
- No hay flujo de reembolsos.
- La función `create_order` envía el número de tarjeta de prueba al servicio de pagos configurado en `PAYMENT_API_URL`.
