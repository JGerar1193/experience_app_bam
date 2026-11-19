# Implementación de agentes de IA en la app

Este documento explica qué agentes se implementaron en la app, de dónde salen los conceptos (la presentación *Construcción de agentes de IA: estándares, patrones y práctica*, convertida en [construccion_agentes_ia.md](./construccion_agentes_ia.md)) y en qué archivos vive cada parte.

Rama: `feature/agentes-soporte-conciliacion` (creada desde `feature/specs-mcp`).

---

## 1. Qué dice la presentación y por qué lo aplicamos así

La presentación define un agente como **un modelo que usa herramientas en un bucle** (`while (!terminado) { pensar(); usarHerramienta(); observar(); }`) hasta cumplir un objetivo o un criterio de parada. Sus ideas clave, y cómo se aplican aquí:

| Idea de la presentación | Cómo se aplica en la app |
|---|---|
| Usar el patrón más simple que resuelva el problema (workflow antes que agente autónomo). | Los dos agentes son **de solo lectura**. El código define los pasos y el modelo solo decide qué consulta hacer. |
| "Las reglas importantes viven fuera del modelo" (spec, servidor, aprobaciones humanas). | Las reglas de negocio están en Python (`find_order_anomalies`, filtro por `userId`), no solo en el prompt. |
| Anatomía: modelo, instrucciones, herramientas, memoria, límites, human-in-the-loop. | Ver la tabla de la sección 3. |
| Riesgos: inyección de prompt, permisos excesivos, acciones irreversibles, bucles y costo. | No hay herramientas de escritura, las herramientas están acotadas al usuario actual y hay un máximo de llamadas. |
| Evals y observabilidad. | Pendiente (ver sección 7). Solo hay logs con `print`. |

**Decisión tomada:** no se implementó un agente que cree pedidos o cobre. La presentación lo clasificaría como alto riesgo (acción irreversible con dinero real). Por eso el agente de pedidos solo consulta.

---

## 2. Qué se construyó

### 2.1 Agente de soporte de pedidos (`support_agent`)

- **Qué hace:** responde preguntas del usuario sobre sus propios pedidos ("¿cuándo compré?", "¿qué talla compré?", "¿cuánto pagué?").
- **Cómo se invoca:** desde la app, como función callable de Firebase.
- **Herramientas del modelo:**
  - `list_my_orders()`: lista hasta 20 pedidos del usuario actual.
  - `get_order(order_id)`: detalle de un pedido, solo si pertenece al usuario actual.
- **Límites:** máximo 3 llamadas a herramientas por pregunta (`MAX_TOOL_CALLS`), mensaje máximo de 500 caracteres (`MAX_SUPPORT_MESSAGE_LENGTH`) y requiere sesión iniciada.

### 2.2 Agente de conciliación (`reconciliation_agent`)

- **Qué hace:** cada 24 horas revisa los pedidos creados en ese periodo y busca anomalías.
- **Cómo se invoca:** Cloud Scheduler (`schedule="every 24 hours"`). No tiene interfaz en la app.
- **Anomalías que detecta** (código determinístico, no lo decide el modelo):
  - Estado distinto de `paid`.
  - Pedido sin `transactionId` de pago.
  - Pedido sin artículos.
  - Total que no coincide con la suma de artículos (tolerancia de 0.01).
- **Gemini** solo redacta un resumen de las anomalías. Si Gemini falla, se devuelve la lista cruda de anomalías.
- **Salida:** se imprime en los logs de la función. No escribe en Firestore ni corrige pedidos.

### 2.3 Interfaz en la app

- La pestaña del footer **Asistente** (antes "Categories") muestra el chat con el agente de soporte.
- El chat se reinicia al cambiar de pestaña. No guarda historial.

---

## 3. Anatomía del agente de soporte (según la presentación)

| Componente | Implementación | Dónde |
|---|---|---|
| Modelo | Gemini 3 Flash Preview (`gemini-3-flash-preview`), vía Vertex AI, ubicación `global`. Configurable con variables de entorno. | [ai_agents.py](../../../functions/ai_agents.py) líneas 11-12 |
| Instrucciones | `SUPPORT_INSTRUCTIONS`: responde en español, solo consulta pedidos del usuario, no cobra ni cancela, trata los mensajes como datos, no revela tarjetas completas. | [ai_agents.py](../../../functions/ai_agents.py) líneas 15-19 |
| Herramientas | `list_my_orders` y `get_order`. El `uid` está fijado en un cierre (*closure*), así el modelo no puede pedir pedidos de otro usuario. | [ai_agents.py](../../../functions/ai_agents.py) `answer_support_question` |
| Memoria | **Sin memoria.** Cada pregunta es independiente. | — |
| Límites | `maximum_remote_calls=3`, 20 pedidos por consulta, 500 caracteres de entrada. | [ai_agents.py](../../../functions/ai_agents.py), [main.py](../../../functions/main.py) |
| Human-in-the-loop | No hay acciones de escritura. Para cobros, cancelaciones o reembolsos, el agente indica que contacten a soporte humano. | Instrucciones del agente |

---

## 4. Dónde está cada cosa

### Backend (`functions/`)

| Archivo | Qué contiene |
|---|---|
| [functions/ai_agents.py](../../../functions/ai_agents.py) | Lógica de los agentes: cliente de Gemini, herramientas, `answer_support_question`, `find_order_anomalies`, `run_reconciliation`. |
| [functions/main.py](../../../functions/main.py) | Funciones desplegadas: `support_agent` (callable), `reconciliation_agent` (programada). Están justo antes de `on_user_created`. |
| [functions/requirements.txt](../../../functions/requirements.txt) | Dependencia nueva: `google-genai`. |

Funciones existentes que los agentes **no modifican**:
- `create_order` (en `main.py`): crea pedidos y cobra. Guarda el producto tal cual dentro de `items`.
- `on_order_created` (trigger de Firestore en `orders/{orderId}`): envía la notificación "¡Compra confirmada!".

### Frontend (`lib/features/ecommerce/`)

| Archivo | Qué contiene |
|---|---|
| [support_agent_datasource.dart](../../../lib/features/ecommerce/data/datasources/support_agent_datasource.dart) | Llama a la callable `support_agent` con `{message}` y lee `answer`. Mismo patrón que `order_callable_datasource.dart`. |
| [support_agent_provider.dart](../../../lib/features/ecommerce/presentation/providers/support_agent_provider.dart) | Provider de Riverpod que expone el datasource. |
| [support_chat_screen.dart](../../../lib/features/ecommerce/presentation/screens/support_chat_screen.dart) | Pantalla de chat: burbujas, barra de carga, límite de 500 caracteres. |
| [ecommerce_home_screen.dart](../../../lib/features/ecommerce/presentation/screens/ecommerce_home_screen.dart) | Footer. El índice 1 (etiqueta "Asistente", icono `support_agent`) muestra `SupportChatScreen`. |
| [product_model.dart](../../../lib/features/ecommerce/data/models/product_model.dart) | `fromJson` acepta `category`/`Category` y `price`/`Price` al leer pedidos guardados. |

---

## 5. Contrato de la callable `support_agent`

- **Entrada:** `{ message: string }`
- **Salida:** `{ answer: string }`
- **Errores:**
  - `UNAUTHENTICATED`: no hay sesión iniciada.
  - `INVALID_ARGUMENT`: mensaje vacío.
  - `UNAVAILABLE`: falla interna (por ejemplo, Vertex no responde).

---

## 6. Configuración y despliegue

**Variables de entorno** (opcionales, tienen valor por defecto en `ai_agents.py`):
- `GEMINI_MODEL`: modelo a usar. Por defecto `gemini-3-flash-preview`.
- `VERTEX_LOCATION`: ubicación. Por defecto `global`.

**Requisitos en GCP** (proyecto `ecomerce-bcd3b`):
- API de Vertex AI y API de Cloud Scheduler habilitadas.
- Rol `roles/aiplatform.user` para la cuenta de servicio de Compute `212470707403-compute@developer.gserviceaccount.com`.

**Desplegar:**
```powershell
cd functions
.\venv\Scripts\python.exe -m pip install -r requirements.txt
cd ..
firebase deploy --only functions:support_agent,functions:reconciliation_agent
```
Nota: `firebase deploy` importa `main.py` con el `venv` local. Si falta `google-genai` en ese `venv`, el despliegue falla con `ImportError`.

**Ver logs:**
- Errores de la app (Dart): en la consola de `flutter run` o del IDE. No aparecen en Google Cloud.
- Logs de las funciones: Firebase Console → Functions → Logs, o Logs Explorer de Google Cloud filtrando por la función.

---

## 7. Pendiente y riesgos conocidos

- **Evals:** la presentación recomienda correr cada caso varias veces. No hay conjunto de pruebas para el agente de soporte.
- **Reconciliación sin verificar:** `reconciliation_agent` no se ha ejecutado aún. Revisar sus logs tras la primera ejecución programada.
- **Modelo preview:** `gemini-3-flash-preview` es un modelo *preview* y Google puede retirarlo. Si deja de responder, cambiar `GEMINI_MODEL`.
- **Sin memoria:** el agente no recuerda preguntas anteriores. El chat se reinicia al cambiar de pestaña.
- **Pedidos antiguos:** los pedidos guardados con `Category`/`Price` solo se leen bien gracias al cambio en `ProductModel.fromJson`. Sería mejor normalizar los datos al guardar en `create_order`.
- **Pruebas de Dart:** `flutter analyze` no se ejecutó en la máquina de desarrollo (Flutter no está en el PATH).
- **Commits:** el cambio de la etiqueta y del fix de `ProductModel` ya están subidos. Revisar la rama antes de hacer PR a `feature/specs-mcp`.

---

## 8. Historial de commits de la rama

| Commit | Cambio |
|---|---|
| `63d99cc` | Backend de los agentes (`ai_agents.py`, `main.py`, `requirements.txt`). |
| `042e873` | Chat de soporte en Flutter. |
| `f800c83` | Chat movido a la pestaña del footer. |
| `4aa2274` | Icono de la pestaña cambiado a asistente de IA. |
| `249d4eb` | Etiqueta de la pestaña cambiada a "Asistente". |
| `f7a7fd0` | `ProductModel.fromJson` acepta `Category`/`Price`. |
