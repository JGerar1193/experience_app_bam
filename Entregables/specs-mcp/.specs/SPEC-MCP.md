# SPEC-MCP: acceso de agentes a transferencias internas

## 1. Estado, autoridad y alcance

- Version: 0.2. Fecha: 2026-11-05. Estado: contrato objetivo para revision y demo tecnica implementada segun seccion 9; no habilita operaciones reales.
- Fuente normativa: [SPEC-TRANSFER.md](SPEC-TRANSFER.md) v0.4. Este documento la complementa; no cambia reglas, estados, formulas, limites ni decisiones pendientes. Ante contradiccion, se bloquea la operacion y se corrige el contrato, sin elegir la interpretacion mas permisiva.
- Dependencias: [PLAN-TRANSFER.md](PLAN-TRANSFER.md), [TASKS-TRANSFER.md](TASKS-TRANSFER.md) y [contratos del backend](../backend/src/contracts/transfer.schema.json).
- Objetivo: permitir consultar saldos propios, seleccionar destinatarios guardados, cotizar, reservar, confirmar, abandonar y recuperar resultados mediante Model Context Protocol (MCP).
- Las secciones 2 a 8 definen el contrato objetivo bancario, aun no implementado. Existe un servidor MCP de demostracion separado, descrito en la seccion 9; el backend bancario sigue sin servicios monetarios operativos.
- No se promete que un modelo obedecera instrucciones. La garantia exigida es que ninguna llamada, incluso maliciosa o directa sin agente, produzca un efecto que viole las reglas: controles ejecutables en servidor, autorizacion y restricciones transaccionales.
- La conformidad requiere evidencia de pruebas y revision de seguridad/contabilidad. Un prompt, una anotacion MCP o esta especificacion por si solos no constituyen una barrera de seguridad.

## 2. Arquitectura y frontera de confianza

Flujo: cliente MCP autenticado -> adaptador MCP -> servicios de aplicacion NestJS -> unica frontera ACID PostgreSQL de saldos, reservas, transferencias, idempotencia, auditoria y libro mayor.

| Componente | Responsabilidad | Prohibicion |
| --- | --- | --- |
| Agente | Proponer llamadas y presentar informacion recibida. | Autorizarse a si mismo, fijar tasas, declarar resultados durables o demostrar consentimiento mediante texto propio. |
| Cliente/interfaz de confianza | Autenticar al usuario y mostrar el resumen canonico para obtener consentimiento explicito. | Delegar al modelo la emision de evidencia de consentimiento o sustituir importes del resumen. |
| Adaptador MCP | Validar contratos, derivar identidad, verificar permisos y despachar a servicios autorizados. | Escribir saldos/asientos, ejecutar SQL arbitrario o duplicar formulas monetarias. |
| Backend monetario | Revalidar elegibilidad y permisos; calcular, persistir y ejecutar todas las decisiones monetarias. | Confiar en validaciones previas del adaptador como sustituto de controles propios. |
| PostgreSQL | Preservar restricciones y commit atomico bajo concurrencia y fallos. | Permitir al rol MCP alterar balances, diarios, reservas o auditoria por fuera de la via autorizada. |

MCP no crea un segundo escritor ni una Saga. Si el adaptador reside en el mismo proceso, usa los mismos servicios de aplicacion, no una implementacion paralela. Si reside separado, utiliza una API autenticada del backend, sin credenciales de escritura directa a la base.

## 3. Reglas obligatorias del MCP

### MCP-001. Identidad y aislamiento

El actor procede exclusivamente del contexto autenticado validado por el servidor. Cada llamada comprueba permisos sobre la herramienta y el recurso, incluyendo lecturas, comprobantes y recuperacion por clave. Un identificador UUID, un alias o conocer una clave no otorgan acceso. No se aceptan `actorId`, propietario, rol ni identidad elegida por el agente.

En despliegue remoto se exige TLS y autorizacion MCP/OAuth conforme a la version del protocolo adoptada, validando emisor, audiencia del recurso, vencimiento y scopes. No se reenvia un token destinado a otro servicio. La delegacion al backend requiere credenciales con audiencia correcta y contexto de usuario verificable, nunca solo un encabezado de actor confiado.

Un transporte stdio solo se permite como proceso local dedicado, con identidad vinculada por un lanzador confiable fuera de argumentos de herramientas. No se ejecuta con una identidad bancaria compartida entre usuarios. Stdio no demuestra por si solo autenticacion ni consentimiento. El responsable de seguridad debe aprobar el mecanismo en G-007.

### MCP-002. Superficie cerrada y validacion estricta

Solo se registran las herramientas de la seccion 4. Entradas y salidas tienen schemas versionados, propiedades adicionales prohibidas, tipos estrictos, formatos y limites de longitud/paginacion. No hay coercion, valores por defecto que cambien una orden ni eliminacion silenciosa de propiedades. Se valida tambien la coherencia semantica entre campos.

No se exponen herramientas de SQL, shell, HTTP arbitrario, administracion, carga de codigo, cambio de politica, ajustes de saldo o reversion. Las URLs de proveedores y destinos de red son configuracion del servidor, no argumentos del modelo. Las credenciales y los tokens nunca son argumentos ni resultados MCP.

### MCP-003. Datos exactos y autoridad monetaria

USD, EUR, COP y GTQ son las unicas monedas. Los importes de entrada son strings decimales positivos con exactamente dos decimales, segun el contrato canonico; cero se permite en saldos, no como importe de transferencia. Se rechazan numeros JSON, exponentes, precision excedente y desbordamientos. No se usa punto flotante binario para decisiones monetarias.

El backend usa el valor monetario exacto existente y su limite de almacenamiento. La presentacion serializa strings sin perdida. El agente no puede aportar saldo, moneda de una billetera, tasa, comision, referencia USD, vencimiento, estado final o asientos.

### MCP-004. Consultas de saldo sin efectos

Solo se consultan billeteras propias autorizadas. Cada resultado contiene `walletId`, moneda, estado operativo, `posted`, `reserved`, `available`, `asOf` UTC y version de lectura. Los tres importes son strings exactos; se cumple `available = posted - reserved`, todos no negativos, con una lectura consistente del backend.

El saldo es una observacion, no una promesa de reserva ni permiso de gasto. Una reserva vencida sigue incluida si su liberacion aun no es durable. El adaptador no la resta por el reloj ni ejecuta una liberacion como efecto oculto de consultar. Una nueva reserva siempre vuelve a comprobar disponible atomicamente.

### MCP-005. Destinatarios y elegibilidad

Solo se admiten personas individuales, billeteras internas distintas y habilitadas; las cuentas propias estan deshabilitadas en fase 1. El agente selecciona un alias previamente guardado del actor, normalizado con trim y comparacion case-insensitive, y obtiene su `recipientId` estable. No se permite coincidencia aproximada ni elegir automaticamente entre resultados ambiguos.

Cotizar y reservar validan la pertenencia del destinatario y la identidad interna del destino; confirmar revalida autorizacion y elegibilidad de las billeteras. El alias o nombre no autoriza el debito. El MCP no da de alta destinatarios ni busca numeros de cuenta en esta fase: se utiliza el flujo bancario verificado existente cuando este implementado. El titular procede del directorio bancario, nunca del agente.

### MCP-006. Resumen y referencia congelados

Cotizar no reserva fondos. El backend produce un resumen inmutable identificado por `quoteId`, vinculado al actor, billeteras, destinatario, monedas e importe origen y utilizable por una sola transferencia. Nueva cotizacion implica nuevo identificador y nueva aceptacion.

El resumen contiene todos los campos RN-024: origen identificable, alias, titular completo validado, monedas, debito, tasa y sentido cuando corresponda, bruto, porcentaje e importe de comision, neto, emision, vencimiento y advertencia de irreversibilidad. Se preservan snapshot, fuente, version de politica y valores exactos/finales necesarios para auditoria; no se recalculan en MCP.

Conversion: bruto HALF_UP a dos decimales; comision 1% sobre bruto final, con CEILING a unidades enteras destino; neto = bruto - comision, rechazando neto <= 0. Reserva y debito son exactamente el importe origen. Igual moneda: bruto = neto = origen y comision cero; no se presenta una tasa comercial FX. El campo `rate` exigido por el contrato actual se conserva como identidad tecnica, no como conversion cobrada.

La referencia bancaria vigente y aprobada se usa para conversion y para el limite exacto de USD 200.00 sobre origen antes de comision, sin redondear para admitir excesos. EUR/EUR, COP/COP y GTQ/GTQ tambien requieren referencia origen/USD; USD/USD no requiere snapshot. No se inventan cruces, inversas ni fallback a ejemplos o datos vencidos. Se bloquea antes de reservar si faltan datos necesarios.

### MCP-007. Tiempo autoritativo

Resumen y cotizacion tienen vigencia positiva de hasta 60 segundos; en igual moneda el resumen vence a los 60 segundos de emitirse. La reserva hereda exactamente ese vencimiento. Ni reservar, consentir, reintentar, cambiar sesion ni iniciar confirmacion extiende el plazo.

Solo decide el reloj autoritativo del backend. Se exige `serverNow < expiresAt` en la decision transaccional final, despues de los bloqueos; igualdad significa vencimiento. El timeout MCP y el reloj del cliente no alteran la vigencia. Cotizacion vencida requiere otro resumen y nueva revision/confirmacion explicita, nunca sustitucion silenciosa.

### MCP-008. Consentimiento humano no falsificable por el agente

Antes de confirmar, una interfaz de confianza muestra el resumen canonico completo y la advertencia RN-024, sin depender de un resumen redactado por el modelo. El usuario acepta explicitamente esas condiciones. El agente no puede conceder, fabricar ni renovar esa aceptacion; un mensaje de chat, `confirmed: true`, un argumento `acceptIrreversible: true` o una anotacion de herramienta no bastan como evidencia.

Un servicio confiable registra la aceptacion fuera de las herramientas disponibles al agente. La evidencia se vincula a actor, cliente autorizado, `transferId`, `quoteId`, huella del resumen inmutable, version de politica y vencimiento no posterior al resumen. El backend verifica autenticidad, vinculacion, vigencia y ausencia de revocacion antes del efecto final. Cambiar cualquier condicion invalida el consentimiento para la nueva operacion.

Se prefiere un registro de consentimiento consultable por el backend: el agente solo conoce identificadores de transferencia, no secretos portadores. La reclamacion/consumo del consentimiento y la confirmacion monetaria se resuelven en la misma frontera ACID. No se consume definitivamente si hay rollback, ni puede autorizar otra transferencia. Un reintento idempotente puede recuperar el resultado ya confirmado sin exigir un nuevo consentimiento vencido, pero requiere autenticacion y permiso de lectura actuales.

Este mecanismo es una nueva exigencia del acceso por agente y requiere aprobar su contrato e implementarlo en el backend. El schema `ConfirmRequest` actual no prueba presencia humana. No se habilita confirmacion MCP hasta cerrar esa diferencia; un popup controlado solo por el modelo no la resuelve.

### MCP-009. Reserva y contabilizacion exclusivamente ACID

Reservar valida disponible y crea exactamente una reserva por transferencia en una transaccion. Todas las vias que afectan fondos comparten bloqueos o actualizaciones condicionales y orden determinista de billeteras. El MCP no interpreta una consulta previa de saldo como comprobacion suficiente.

Confirmar revalida actor, billeteras, destinatario, condiciones aceptadas, estado RESERVADA, reserva ACTIVA y tiempo final. Debito, credito, comision, residuos conforme al plan aprobado, diario, consumo de reserva/consentimiento, estado CONTABILIZADA, idempotencia y auditoria comparten un commit. Cualquier fallo revierte el conjunto.

El diario tiene al menos dos lineas y cuadra por moneda, sin sumar monedas distintas. Conversion usa cuentas puente por moneda y linea separada de comision. Saldos y reservas conservan todos los invariantes RN-004. MCP no puede habilitar este camino sin mapeo contable aprobado e incorporado.

### MCP-010. Estados, abandono y recuperacion

Se conservan exclusivamente los estados y transiciones habilitados de SPEC-TRANSFER. Confirmar, abandonar y expirar compiten por la misma version/bloqueo: solo gana una transicion desde RESERVADA. Cancelar o expirar libera exactamente una vez, sin diario monetario; el recuperador completa expiraciones pendientes tras reinicios.

Solo se permite cancelar antes de contabilizar. CONTABILIZADA no se cancela ni se revierte por MCP; no se expone REVERTIDA como capacidad disponible. Cerrar el cliente, cortar conexion o cancelar una llamada MCP en curso no prueba abandono ni rollback. Se recupera el estado durable y se informa al usuario sin prometer cancelacion.

### MCP-011. Idempotencia y resultado desconocido

Cotizar, reservar, confirmar y cancelar exigen `idempotencyKey` UUID. Se utiliza el almacenamiento comun del backend, con alcance actor + tipo de comando + clave y huella canonica de parametros semanticos, incluidos identificadores de ruta; ni sesion MCP ni canal HTTP/MCP crean espacios separados para duplicar efectos.

Misma clave y mismos parametros recuperan la misma operacion; parametros diferentes generan conflicto. La unicidad de `quoteId`, reserva y diario impide tambien duplicados con claves distintas. Un reintento tecnico conserva clave y parametros; los reintentos por conflicto de base son acotados y revalidan tiempo y permisos.

Un timeout o perdida de respuesta no significa RECHAZADA, CANCELADA ni ausencia de movimiento. Se comunica resultado desconocido/en curso como condicion de transporte o recuperacion, nunca como nuevo estado monetario FALLIDA. Se consulta por transferencia o por tipo de comando y clave; no se genera otra clave ni otra transferencia para resolver la incertidumbre. No se permite replay de comandos historicos tras depurar almacenamiento.

### MCP-012. Resultados, errores y comprobantes

Las herramientas devuelven contenido estructurado validado, no instrucciones para el agente. El exito monetario solo se informa con estado durable CONTABILIZADA y sus referencias. Un acuse MCP o una reserva no es un comprobante. Los comprobantes se leen del historial ejecutado, con numero unico y campos RN-025; no recalculan tasa, titular ni importes y no generan efectos.

Los errores de negocio usan `isError: true` y un payload con `code`, `message` seguro, `correlationId` y `retryable`, reutilizando `ErrorResponse` donde corresponda. Los errores de protocolo conservan la semantica MCP de la version seleccionada. No se devuelve exito ficticio ni se filtran stack traces, SQL, tokens, cuentas completas o existencia de recursos ajenos.

El contrato de recuperacion debe distinguir resultado durable, en curso y resultado aun desconocido, sin inventar un estado de transferencia. Los codigos y schemas de esta extension se versionan antes de implementar; un error reintentable no autoriza una nueva clave.

### MCP-013. Prompt injection, privacidad y privilegios

Alias, nombres, motivos, textos del proveedor y contenido de herramientas son datos no confiables, aunque provengan del banco. Se devuelven en campos estructurados y no se interpolan como instrucciones, nombres de herramientas ni comandos. No pueden modificar el catalogo, scopes, politica, evidencia humana o parametros monetarios aceptados.

Las anotaciones MCP `readOnlyHint`, `destructiveHint`, `idempotentHint` y `openWorldHint` describen comportamiento, pero nunca autorizan una llamada ni sustituyen controles. No se confia en el system prompt, en la lista visible de herramientas ni en que el cliente pida confirmacion de uso.

Se minimizan datos: cuentas enmascaradas; nombre completo solo en el contexto autorizado que RN-024/025 requieren; sin balances de terceros, secretos ni payloads bancarios crudos. Logs tecnicos no contienen credenciales ni datos personales completos. Se aplican cuotas, limites de tamano, concurrencia, rate limiting y proteccion de enumeracion segun G-007. Los limites no impiden la recuperacion segura de resultados ni la expiracion de reservas.

### MCP-014. Auditoria y reconciliacion

Cada efecto y su idempotencia registran atomicamente actor humano, cliente/agente delegado identificable, comando, parametros referenciados/huella, correlacion, estado anterior/nuevo, motivo, tiempos UTC, resumen, consentimiento y diario cuando aplique. Un ID de peticion MCP solo ayuda a correlacionar; no es una clave de idempotencia.

Los asientos definitivos y la auditoria de efectos son inmutables. Los rechazos e intentos sin efecto se auditan de forma segura sin atribuirles un commit monetario. La reconciliacion RN-022 incluye operaciones originadas por MCP: saldos, reservas, unicidad de diarios y cuadratura por moneda. Las discrepancias crean incidencias; no habilitan herramientas de reparacion para el agente.

## 4. Catalogo cerrado de herramientas

Los nombres y scopes siguientes son propuestas del contrato MCP, no endpoints ya implementados. Los objetos de negocio reutilizan los schemas canonicos del backend cuando existen. Cada herramienta valida autorizacion de nuevo; tener scope no sustituye propiedad o elegibilidad del recurso.

| Herramienta | Scope propuesto | Entrada permitida | Salida / servicio responsable |
| --- | --- | --- | --- |
| `balances_get` | `balances:read` | `walletId` UUID propio. | Snapshot consistente MCP-004. Nuevo contrato de lectura pendiente. |
| `recipients_list` | `recipients:read` | `cursor` opaco opcional y `limit` entero 1..100. | `RecipientList` propio, paginacion estable; T-025. |
| `transfer_quote` | `transfers:quote` | `sourceWalletId`, `recipientId`, `sourceAmount`, `idempotencyKey`. | `QuoteResponse` inmutable; `QuoteRequest` mas clave de comando; T-026. |
| `transfer_reserve` | `transfers:reserve` | `quoteId`, `idempotencyKey`. | `TransferResponse`, sin contabilizar; T-027. |
| `transfer_confirm` | `transfers:confirm` | `transferId`, `quoteId`, `idempotencyKey`. | `TransferResponse`; T-029 mas verificacion backend de consentimiento MCP-008. Sin argumento de autoaceptacion. |
| `transfer_cancel` | `transfers:cancel` | `transferId`, `idempotencyKey`, `reason` opcional limitado a `USER_ABANDONED`. | Resultado durable segun T-030; no cancela CONTABILIZADA. |
| `transfer_get` | `transfers:read` | `transferId`. | `TransferResponse` propio; T-032. |
| `operation_get` | `transfers:read` | `operation` limitado a `quote-create`, `transfer-reserve`, `transfer-confirm`, `transfer-cancel`; `idempotencyKey`. | Recuperacion propia por comando/clave; T-032 y extension MCP-012 para incertidumbre. |
| `receipt_get` | `transfers:read` | `transferId`. | `ReceiptResponse` propio y definitivo; T-033. |

Lecturas no aceptan claves de escritura ni producen movimientos. Las claves de comandos son argumentos MCP separados del cuerpo canonico cuando corresponda a encabezados HTTP; la huella y semantica son las mismas del backend. No se anidan campos libres en ningun argumento.

La seleccion por alias ocurre mediante el listado autorizado y se fija por `recipientId`; el MCP no transforma un nombre libre en cuenta destino. No hay herramienta de ejecucion en un solo paso que evite resumen, reserva o consentimiento. Cotizaciones pueden persistirse y ser idempotentes, aunque no muevan fondos; las anotaciones deben reflejar esa diferencia respecto de una lectura pura.

## 5. Recorrido autorizado

1. El cliente autentica al usuario; MCP deriva actor y permisos fuera del control del agente.
2. El agente consulta saldo propio y destinatarios guardados; el usuario selecciona alias sin ambiguedad e importe origen.
3. `transfer_quote` obtiene el resumen canonico. Si falla referencia, limite, elegibilidad o validacion, no se reserva ni se inventan condiciones.
4. `transfer_reserve` retiene exactamente el debito del resumen vigente, sin reiniciar su reloj. La interfaz confiable muestra las condiciones completas antes de autorizar la contabilizacion; reservar no autoriza confirmar.
5. El usuario acepta explicitamente en la interfaz confiable. El backend registra evidencia ligada a esa transferencia/resumen vigente; no se solicita ningun secreto por chat.
6. `transfer_confirm` solo contabiliza si el backend valida esa evidencia y todas las invariantes en su decision ACID final. Si vence mientras se revisa, se expira/libera y se requiere nuevo resumen y aceptacion.
7. El agente recupera resultado durable y comprobante. Ante timeout consulta/reintenta el mismo comando; ante abandono solicita cancelacion y comprueba quien gano la carrera.

## 6. Trazabilidad normativa

Todas las reglas originales siguen siendo obligatorias en los servicios de backend, incluso si una llamada evita MCP.

| Reglas de SPEC-TRANSFER | Controles MCP | Evidencia exigida |
| --- | --- | --- |
| RN-001, RN-003 | MCP-002, MCP-003 | Contratos estrictos, precision, monedas y overflow. |
| RN-002, RN-023 | MCP-001, MCP-005, MCP-013 | Aislamiento por actor, elegibilidad, alias guardado y permisos revalidados. |
| RN-004, RN-011, RN-012 | MCP-004, MCP-007, MCP-009 | Saldo consistente y pruebas concurrentes PostgreSQL sin sobregiro. |
| RN-005, RN-009, RN-010 | MCP-003, MCP-006 | Calculo exacto delegado; misma moneda sin cargo. |
| RN-006, RN-007, RN-008 | MCP-006, MCP-007, MCP-008 | Condiciones inmutables, reloj final, vinculacion y aceptacion. |
| RN-013, RN-017, RN-018 | MCP-009, MCP-014 | Commit unico, puente y comision, diario balanceado por moneda. |
| RN-014, RN-015, RN-028 | MCP-007, MCP-010, MCP-011 | Carreras, abandono, liberacion unica y recuperacion. |
| RN-016, RN-021 | MCP-011, MCP-012 | Reintento por clave, resultado durable y respuesta perdida. |
| RN-019, RN-022 | MCP-014 | Auditoria atomica e inmutable y reconciliacion. |
| RN-020 | MCP-002, MCP-010 | Sin herramienta de reversion ni cancelacion poscontabilizacion. |
| RN-024 | MCP-006, MCP-008 | Resumen confiable completo y evidencia humana no falsificable por modelo. |
| RN-025 | MCP-012 | Comprobante historico propio sin efectos. |
| RN-026, RN-027 | MCP-006, MCP-007 | Referencia bancaria aprobada y limite exacto antes de reserva. |

## 7. Aceptacion y pruebas negativas

Cada caso se automatiza cuando exista implementacion. Para fondos, concurrencia y commit se usa PostgreSQL real aislado, reloj de servidor controlable en pruebas y datos sinteticos, nunca produccion. Un mock MCP no demuestra atomicidad. Tambien se ejecutan los EA aplicables del SPEC original, incluida la matriz de 16 pares; EA-018/019 siguen fuera de fase 1.

| Caso | Accion / condicion | Resultado exigido |
| --- | --- | --- |
| AM-001 | Identidad ausente/vencida, token con audiencia incorrecta o `actorId` adicional. | Rechazo antes de acceder a datos o modificar fondos. |
| AM-002 | Actor B usa billetera, destinatario, transferencia, clave o comprobante de A. | Sin datos ni efectos; no se revela existencia del recurso. |
| AM-003 | Importe numero JSON, cero, negativo, exponente, tres decimales, overflow, QTZ o UYU. | Rechazo estricto sin normalizacion silenciosa ni reserva. |
| AM-004 | Lectura durante reservas concurrentes o con reserva vencida aun no liberada. | Snapshot consistente; no se anuncia disponible que PostgreSQL sigue reteniendo. |
| AM-005 | Alias desconocido/ambiguo, cuenta propia, empresa, externa o billetera bloqueada. | No se avanza a ejecucion; no se elige otro destinatario automaticamente. |
| AM-006 | Cotizar los 16 pares y el ejemplo USD 10.00 -> COP 40000.00 bruto con tasa sintetica 4000. | Bruto, comision COP 400.00 y neto COP 39600.00 exactos; misma moneda sin cargo; cotizar no reserva. |
| AM-007 | USD 199.99/200.00/200.01 y EUR 187.50/187.51 con fixture q(EUR)=8 y q(USD)=7.50. | Se admiten los limites exactos, se rechazan excesos sin redondear; tambien en igual moneda. |
| AM-008 | Falta referencia no USD, datos incompletos/vencidos o intento de imponer tasa/fee. | No se reserva ni confirma; no hay fallback ni uso del ejemplo como dato real. |
| AM-009 | Reserva en t+50, confirmacion en t+59 o t+60; otra espera de locks atraviesa el vencimiento. | Vence en t+60 desde emision; solo confirma si sigue vigente en la escritura final. |
| AM-010 | Agente envia autoaceptacion o llama directamente a confirmacion sin evidencia confiable. | Rechazo sin contabilizacion, incluso con `acceptIrreversible: true` en una llamada HTTP. |
| AM-011 | Evidencia ajena, revocada, vencida o de otro importe, quote, destino, politica o transferencia. | No contabiliza; nuevo resumen requiere nuevo consentimiento. |
| AM-012 | Dos reservas de 80.00 contra disponible 100.00; disponible exacto frente a insuficiente. | Como maximo una reserva de 80.00; exacto se permite; nunca sobregiro. |
| AM-013 | Misma clave/parametros simultaneamente por MCP y HTTP; luego parametros cambiados. | Un efecto/resultado durable; cambio produce conflicto. Otra clave no reutiliza quote ni diario. |
| AM-014 | Competencia confirmar/cancelar/expirar y cancelacion de llamada MCP durante commit. | Una transicion ganadora; se recupera estado durable sin prometer rollback. |
| AM-015 | Fallo entre debito, credito, diario, auditoria y consumo de consentimiento/reserva. | Rollback total; evidencia no queda consumida por fallo; reintento vigente puede completar una sola vez. |
| AM-016 | Respuesta perdida tras commit y reintento despues de vencer resumen/consentimiento. | Con permiso actual se recupera la misma CONTABILIZADA; no se exige otro debito ni se cambia a FALLIDA. |
| AM-017 | Reinicio con reservas vencidas, dos recuperadores y abandono repetido. | Liberacion exactamente una vez; sin diario ni cambio de contabilizadas. |
| AM-018 | Intento de diario desbalanceado por moneda, edicion historica o acceso directo a saldo con rol MCP. | Operacion completa rechazada por controles backend/base; sin bypass de escritura. |
| AM-019 | Comprobante tras cambio de tasas o alias; intento de cancelar transferencia ejecutada. | Comprobante original sin efectos; cancelacion rechazada; reversion no expuesta. |
| AM-020 | Alias/nombre contiene instrucciones, URL, SQL o texto que pide ignorar limites. | Se trata como dato; catalogo, permisos y condiciones aceptadas no cambian. |
| AM-021 | Cliente intenta usar herramienta no registrada, sobrecarga, pagina enorme o recuperar clave historica tras mantenimiento. | Rechazo/limites seguros; sin replay de efectos ni bloqueo del recuperador interno. |
| AM-022 | Conciliar operaciones MCP y provocar discrepancia controlada. | Cuadratura por moneda, saldos y reservas verificables; incidencia auditable sin editar historia. |

## 8. Puertas de construccion y salida

1. Aprobar esta propuesta, version MCP/SDK oficial y transporte de despliegue; fijar schemas de saldo, consentimiento y recuperacion de incertidumbre sin duplicar los contratos monetarios existentes. Los nuevos scopes y la interfaz confiable requieren revision de seguridad, no se consideran aprobados por escribirlos aqui.
2. Completar servicios monetarios pendientes del backlog: saldos protegidos, persistencia, idempotencia, destinatarios, resumen, reserva, confirmacion, cancelacion, expiracion, consultas, comprobantes, seguridad y reconciliacion. El adaptador no los sustituye ni declara terminadas esas tareas.
3. Resolver G-004 (proveedor real de tasas), G-005 (directorio/formato), G-006 (evidencia y mapeo contable) y G-007 (identidad, delegacion, consentimiento, privacidad, limites y retencion). No se abren escrituras productivas con dependencias ausentes. Un entorno sintetico debe estar aislado y rotulado como tal, sin fallback desde produccion.
4. Implementar primero controles backend comunes a todos los canales, en particular evidencia humana MCP-008: proteger solo la herramienta MCP dejaria abierta la confirmacion directa. Ningun nuevo alcance de UI o identidad se declara resuelto sin su aprobacion e implementacion.
5. Construir un adaptador delgado con SDK oficial MCP mantenido y schemas estrictos; probar `initialize`, descubrimiento, llamadas y errores con cliente compatible. No se registra ninguna herramienta sin su permiso, servicio y pruebas correspondientes.
6. Verificar AM-001 a AM-022 y EA aplicables, contratos, tipos, lint, build y CI; pruebas de concurrencia/fallos sobre PostgreSQL real, revision contable y de seguridad con evidencia. No se considera seguro o listo para produccion por funcionar solo el recorrido feliz.

Hasta cumplir estas puertas, el contrato bancario no se considera implementado ni su garantia operacional verificada. La demo siguiente no satisface esas puertas ni cierra tareas monetarias del backlog.

## 9. Perfil temporal DEMO-LOCAL

El usuario autoriza el 2026-11-05 avanzar con reglas temporales para ver el funcionamiento tecnico basico. Este perfil se limita a fondos y personas ficticios, no modifica SPEC-TRANSFER ni aprueba politicas bancarias pendientes. No debe presentarse como implementacion conforme a todas las RN. Las excepciones siguientes solo aplican al ejecutable demo, nunca como fallback de un entorno real.

| Regla temporal | Decision tecnica y limitacion |
| --- | --- |
| TMP-001. Aislamiento | Proceso local stdio iniciado con `--demo`. No escucha HTTP, no usa PostgreSQL, no lee archivos de credenciales ni llama APIs bancarias. No existe modo productivo. |
| TMP-002. Identidad ficticia | Cada proceso representa a Alice Demo y solo permite debitar sus cuatro billeteras. Bob Demo es destinatario previamente guardado en cada moneda. Sin OAuth, usuarios reales ni aislamiento multiusuario; quien controla el proceso local controla la demo. |
| TMP-003. Estado efimero | Saldos, cotizaciones, resultados e idempotencia viven en memoria. Reiniciar borra todo y restaura aperturas ficticias: USD 1000.00, EUR 1000.00, COP 1000000.00 y GTQ 10000.00. No hay recuperacion durable. |
| TMP-004. Tasas sinteticas | Referencias enteras proporcionales: USD=12000, EUR=12800, COP=3, GTQ=1600. Tasa destino/origen = referencia origen / referencia destino. Fuente `synthetic-demo-not-a-bank`; sin caducidad bancaria ni proveedor real. Cada cotizacion si vence a los 60 segundos segun el reloj del proceso. |
| TMP-005. Calculo conservado | Se reutilizan Money y calculateConversion: importes string, bigint, cuatro monedas, HALF_UP, comision de conversion 1% con techo entero destino, neto positivo, misma moneda sin cargo y limite exacto equivalente USD 200.00. Cotizar no cambia fondos. |
| TMP-006. Ejecucion simplificada | `transfer_execute` reemplaza reserva/confirmacion separadas. Comprueba cotizacion vigente/no usada y fondos, calcula ambos saldos y actualiza sin await en un solo proceso. No hay reserva, cancelacion, bloqueo distribuido, transaccion PostgreSQL, diario, contabilidad de comision ni reconciliacion; no se afirma ACID bancario. |
| TMP-007. Aceptacion de maquina | `acceptIrreversible: true` es un reconocimiento tecnico que el agente puede enviar. NO prueba consentimiento humano y NO cumple MCP-008/RN-024 para dinero real. El flujo humano confiable queda pendiente; no se simula seguridad mediante un codigo que el propio agente pueda obtener. |
| TMP-008. Duplicados y capacidad | Cotizar/ejecutar exigen UUID de idempotencia en la frontera MCP. Misma clave/parametros recupera resultado; cambios generan conflicto; una cotizacion solo se ejecuta una vez. Se guardan exitos por proceso, no errores durables. Maximo 1000 cotizaciones por proceso; al agotarse se rechaza, no se purgan claves para reutilizarlas. Ante timeout se reintenta con la misma clave mientras viva el proceso. Tras reinicio no hay forma de recuperar una operacion anterior. |
| TMP-009. Contrato visible | Todas las respuestas exitosas incluyen `demo: true`, `mode: synthetic-in-memory` y `data`, con schemas de entrada/salida estrictos. Errores de negocio: `isError: true` y texto JSON con codigo seguro; no usan el schema estructurado de exito. Recibos `DEMO-*` no son comprobantes bancarios. Los schemas demo son distintos de los contratos bancarios; no los reemplazan. |

### Herramientas implementadas

| Herramienta | Argumentos | Efecto |
| --- | --- | --- |
| `balances_get` | `walletId` opcional. | Lista saldos ficticios de Alice; reservado siempre 0.00. |
| `recipients_list` | Objeto vacio. | Devuelve Bob en las cuatro monedas con ID y alias. |
| `transfer_quote` | `sourceWalletId`, `recipientId`, `sourceAmount`, `idempotencyKey` UUID. | Resumen sintetico completo y `quoteId`; sin fondos reservados. |
| `transfer_execute` | `quoteId`, `idempotencyKey` UUID, `acceptIrreversible: true`. | Debita Alice y acredita neto a Bob una sola vez en memoria; devuelve transferencia y numero DEMO. |
| `transfer_get` | `transferId` UUID. | Recupera resultado del proceso actual. |
| `receipt_get` | `transferId` UUID. | Copia del resultado historico sintetico, sin recalcular condiciones. |

IDs origen: `demo-alice-usd`, `demo-alice-eur`, `demo-alice-cop`, `demo-alice-gtq`. Destinos: `demo-bob-usd`, `demo-bob-eur`, `demo-bob-cop`, `demo-bob-gtq`. El saldo de Bob no se expone como si fuera propio de Alice. USD 10.00 a COP cotiza bruto 40000.00, comision 400.00 y neto 39600.00.

### Construccion y verificacion

Implementacion: [motor demo](../backend/src/mcp/demo-transfers.ts), [herramientas MCP](../backend/src/mcp/server.ts) y [entrada stdio](../backend/src/mcp/main.ts). Configuracion del cliente VS Code: [mcp.json](../.vscode/mcp.json). Instrucciones reproducibles: [README del backend](../backend/README.md).

Las [pruebas unitarias](../backend/test/unit/mcp-demo.spec.ts) cubren calculo, 16 pares, limite, vencimiento, saldo e idempotencia. La [prueba MCP extremo a extremo](../backend/test/e2e/mcp.spec.ts) usa Client y StdioClientTransport oficiales contra un subproceso real: initialize, descubrimiento, seis herramientas, exito, reintento, comprobante, propiedades extra, tipos invalidos y rechazo de lectura de saldos ajenos. Estas pruebas verifican el perfil temporal, no AM-001 a AM-022 ni las puertas bancarias.