# TASKS-TRANSFER: tareas atomicas y verificables

## 1. Estado y fuentes

- Version: 0.8. Estado: T-001, T-002, T-003, T-008, T-009, T-010, T-011, T-012 y T-014 TERMINADAS; restantes tareas pendientes. PostgreSQL 18 validado previamente en solo lectura; Azure pendiente de ejecucion remota.
- Fuentes: [SPEC-TRANSFER.md](SPEC-TRANSFER.md) v0.4, [01-SPECIFICATION.md](01-SPECIFICATION.md) v0.3 y [PLAN-TRANSFER.md](PLAN-TRANSFER.md) v0.3.
- Alcance de esta entrega: descomponer el plan, no crear aun el proyecto NestJS, instalar dependencias o mover fondos.
- Actualizacion de ejecucion: autorizado T-008 tras confirmar una instancia PostgreSQL 18 local de pruebas; arnes en backend. La restriccion de no generar codigo describia la entrega inicial del backlog, no esta fase autorizada. No se implementan transferencias monetarias.
- Pedir este backlog no aprueba automaticamente DT-001 a DT-007 ni resuelve las puertas del plan. Las decisiones aprobadas de negocio no se reabren: transferencia gratis, conversion 1% con techo entero destino, limite USD 200 sobre origen y monedas con dos decimales.
- Todas las tareas empiezan PENDIENTE. Una tarea pasa a LISTA cuando sus dependencias estan terminadas y sus puertas estan resueltas; EN_CURSO cuando se toma; BLOQUEADA si falta una decision o recurso; TERMINADA solo con evidencia de su definicion de terminado.

## 2. Metodo y definicion de terminado comun

Para cada tarea de software: escribir primero el caso TEST indicado, comprobar que falla por ausencia del comportamiento esperado, implementar el menor cambio y comprobar que pasa. Un fallo de entorno o sintaxis no demuestra un RED valido. Refactorizar despues, sin modificar reglas aprobadas. Reutilizar los mismos archivos de prueba por modulo cuando convenga; los identificadores TEST son grupos de casos, no obligan a crear un archivo por identificador.

T-001 a T-007 son decisiones/documentacion: su verificacion previa REV es una lista de criterios por resolver, no una prueba automatizada ficticia. Solo se cierran con decision explicita del responsable; una propuesta escrita por el agente no cuenta como aprobacion.

Definicion de terminado comun para software:

1. Alcance de la tarea cubierto, con evidencia RED y GREEN del mismo caso y revision del cambio.
2. Pruebas focalizadas y regresiones del modulo pasan; cambios monetarios usan PostgreSQL real para restricciones, bloqueos y commit.
3. Sin nuevos errores de tipos/lint; migraciones se prueban en base aislada, nunca revirtiendo datos productivos.
4. Contratos y reglas referenciados conservados; si cambian, actualizar fuentes y obtener aprobacion antes de implementar otra politica.
5. Sin credenciales o datos personales en fixtures/logs. Fixtures claramente sinteticos; ninguna llamada a produccion en pruebas.
6. Matriz de trazabilidad y estado actualizados con comando/resultado reproducible; sin saltarse tests para declarar exito.

Pruebas de dinero no usan Number para decisiones; las de concurrencia no usan SQLite ni mocks de bloqueos. Barreras de sincronizacion y conexiones independientes sustituyen esperas arbitrarias. El reloj sustituible solo existe en el entorno de pruebas; nunca se acepta la hora monetaria del cliente.

## 3. Puertas y dependencias

| Puerta | Se cierra con | Decision requerida | Que bloquea |
| --- | --- | --- | --- |
| G-001 | T-001 | CERRADA el 2026-10-29 por aprobacion explicita del usuario: contratos propios, DT-001 a DT-003 y baseline en seccion 13 del plan. | Habilita preparar T-008; no demuestra disponibilidad de PostgreSQL ni cierra G-002 a G-007. |
| G-002 | T-002 | CERRADA 2026-11-03: HALF_UP a dos decimales; comision sobre bruto cuantizado con techo entero; referencia USD para pares no USD de igual moneda; resumen/reserva por hasta 60 segundos desde emision; vigencia decidida en la escritura final tras bloqueos. | T-011 y T-026. |
| G-003 | T-003 | CERRADA 2026-11-03: el usuario confirma que este backend sera el escritor unico y que saldos, reservas y ledger usaran la misma PostgreSQL y transaccion, sin otro escritor de esos saldos. | T-015 y promesa ACID end-to-end dentro de esta frontera. |
| G-004 | T-004 | ABIERTA 2026-11-03: no hay contrato/proveedor de tasas definido; unidades, cobertura, pares, referencia USD, version y vigencia siguen sin evidencia. | Adaptador real y produccion; no bloquea fixtures normalizados. |
| G-005 | T-005 | PARCIAL 2026-11-03: alias unico por cliente case-insensitive tras trim, cuentas propias deshabilitadas en fase 1 y TTL de lookup de cinco minutos aprobados; falta contrato real del directorio y formato de cuenta. | Alta real y elegibilidad definitivas; edicion de alias sigue pendiente. |
| G-006 | T-006 | PENDIENTE DE EVIDENCIA 2026-11-03: el usuario indica que existe mapeo aprobado, pero falta incorporarlo en forma sanitizada y validar cuentas, signos, aperturas, residuos y cuadratura por moneda. | Libro definitivo, contabilizacion y conciliacion. |
| G-007 | T-007 | BLOQUEADA 2026-11-03: no hay responsable de seguridad/identidad ni politicas de fase 1 definidas. | Seguridad definitiva y salida productiva. |

La tabla de tareas tiene una columna de dependencias con predecesores directos. Las puertas se heredan transitivamente: depender de T-015 implica esperar G-003. Ninguna tarea depende de una posterior; por construccion, el grafo es aciclico. No ejecutar integraciones reales como alternativa a resolver su puerta.

Ruta inicial: T-001 -> T-008 -> T-009/T-010/T-012 -> T-014; T-002 -> T-011 queda habilitada con G-002 cerrada. T-001 a T-007 pueden aclararse de forma independiente, coordinando los cambios documentales. Mientras G-004 siga abierta, T-012 y T-014 permiten pruebas con datos sinteticos, pero T-013 y T-039 no se consideran completadas.

## 4. Catalogo de tareas

Cada fila tiene una unidad de entrega y un criterio local; ademas aplica la definicion comun. Las dependencias separadas por coma son todas obligatorias.

| Tarea | Entrega atomica | Dependencias | Prueba o revision previa | Definicion local de terminado |
| --- | --- | --- | --- | --- |
| T-001 | Registrar decision tecnica del plan y baseline de herramientas. | Ninguna | REV-001: checklist de endpoints/schemas, DT-001 a DT-003, versiones y forma de ejecutar CI, aun sin aprobar. | Responsable acepta o modifica cada decision; versiones y comandos futuros quedan documentados; G-001 cerrada, sin generar codigo aun. |
| T-002 | Cerrar politica monetaria y temporal restante. | Ninguna | REV-002: calcular casos de bruto a mitad de centavo, comision cerca de entero, neto no positivo y confirmacion en el segundo 60. | Negocio aprueba una sola formula y semantica temporal; actualizar RN-009/DT-004/DT-005 y escenarios afectados sin cambiar techo ni porcentaje; G-002 cerrada. |
| T-003 | Documentar autoridad transaccional del dinero. | Ninguna | REV-003: localizar todos los escritores del saldo y comprobar si debito, credito y libro comparten commit. | Responsable del core confirma frontera y via unica; si no cabe en PostgreSQL local, revisar plan antes de ejecutar tareas de fondos; G-003 cerrada. |
| T-004 | Aprobar contrato real de tasas y fixtures sanitizados del proveedor. | Ninguna | REV-004: verificar unidades, cobertura de las cuatro monedas, timestamps, version, directos/cruces y referencia USD sin usar el JSON ilustrativo como real. | Contrato y politica de valoracion firmes, incluidos faltantes y errores; no inventar inversas; G-004 cerrada. |
| T-005 | Cerrar contrato de directorio y politica de destinatarios. | Ninguna | REV-005: cuenta existente/ausente/servicio caido, alias duplicado, evidencia vencida y cuentas propias. | Contrato/formato del directorio, TTL, alias y elegibilidad acordados; decisiones de alias/cuentas propias/TTL parcialmente aprobadas el 2026-11-03; falta G-005 para el contrato real. |
| T-006 | Aprobar mapeo contable y aperturas. | Ninguna | REV-006: validar ejemplo USD/COP de cinco lineas, apertura, mismo par y residuos; cada moneda debe cuadrar. | Responsable contable valida cuentas, signos y tratamiento de residuos; G-006 cerrada, sin habilitar reversiones administrativas. |
| T-007 | Acordar controles de identidad, privacidad y retencion. | Ninguna | REV-007: revisar enumeracion de cuentas, comprobante de otro cliente, datos en logs y borrado de claves antiguas. | Seguridad fija controles, acceso, plazos y politica antireprocesamiento; G-007 cerrada. |
| T-008 | Crear arnes minimo NestJS y PostgreSQL aislado. | T-001 | TEST-008: prueba de arranque y consulta a base de test, inicialmente sin aplicacion ni configuracion. | Proyecto compila; Jest/Supertest y PostgreSQL real funcionan con comandos documentados; test falla claramente si la base no esta disponible, sin conectar a produccion. |
| T-009 | Extraer y validar bundle de contratos propios. | T-008 | TEST-009: Ajv 2020-12 compila schemas; entradas con tasa/propietario extra, precision excedente y UUID invalido se rechazan. | Una fuente versionada de schemas resuelve refs; formatos y validacion estricta activos; no se confunden schemas propios con contrato bancario. |
| T-010 | Implementar valor monetario exacto y unidades minimas. | T-008 | TEST-010: parsear 0.01, 200.00; rechazar negativos, cero como origen, exponentes, precision extra y overflow de almacenamiento; round-trip exacto. | Cuatro monedas a dos decimales, conversion a BIGINT sin perdida y serializacion string; sin decisiones monetarias con Number. |
| T-011 | Implementar funcion pura de conversion y comision. | T-002, T-010 | TEST-011: cuatro pares iguales sin cargo; comisiones previas 0.10/0.101/1.00/1.01 -> 1.00/1.00/1.00/2.00; neto <= 0 rechazado; casos del bruto aprobados en REV-002. | Una formula aprobada, versionada y exacta; origen no se redondea a enteros; bruto = neto + comision en destino. |
| T-012 | Definir puerto de tasas y snapshots normalizados sinteticos. | T-008, T-010 | TEST-012: fixtures completos, positivos y versionados; faltantes, tasa cero/negativa y vigencia ausente no habilitan valoracion. | Puerto independiente del proveedor y fixtures para 16 pares; explicitar modelo elegido solo para test, sin asumir contrato real. |
| T-013 | Implementar adaptador de tasas bancario real. | T-004, T-012 | TEST-013: pruebas de contrato con respuestas sanitizadas reales, faltantes, timeout y precios direccionales; no derivar ni invertir sin permiso. | Mapper preserva precision, unidades y vigencia; politica aprobada en G-004 aplicada, sin hardcode del ejemplo ni fallback antiguo silencioso. |
| T-014 | Implementar comparador de limite universal. | T-010, T-012 | TEST-014: USD 199.99/200.00/200.01 y fixture EUR 187.50/187.51 con 8.00 GTQ/EUR y 7.50 GTQ/USD; incluir mismo par y cocientes periodicos. | Comparar origen antes de comision con USD 200 sin redondear para admitir excesos; ausencia de referencia bloquea valoracion. |
| T-015 | Crear esquema y via protegida de balances. | T-003, T-008 | TEST-015: migracion en base vacia, CHECK contra reservado negativo/excesivo y saldo negativo; rol de aplicacion no puede saltarse la via autorizada. | Wallet/saldo por moneda, disponible derivado y restricciones probadas; datos de saldo no se introducen sin respaldo contable en operaciones posteriores. |
| T-016 | Crear almacenamiento de consultas y destinatarios. | T-005, T-015 | TEST-016: evidencia ligada al cliente, alias conforme a politica y conflicto de unicidad en alta concurrente. | Migracion, referencias estables y restricciones segun G-005; no aceptar titular arbitrario ni compartir alias entre clientes. |
| T-017 | Crear almacenamiento inmutable de snapshots y resumenes. | T-012, T-015 | TEST-017: persistir y leer importes/tasas sin cambios; rechazar alteracion de condiciones una vez emitidas. | Guardar fuente/version, politica, titular/alias historicos, exactos/finales y vigencia; snapshot null solo USD/USD. |
| T-018 | Crear esquema de transferencias, reservas e idempotencia. | T-015, T-017 | TEST-018: duplicar quote_id, hold por transferencia o clave de comando produce conflicto; referencias invalidas se rechazan. | Migraciones con unicidad y relaciones; estados validos sin habilitar REVERTIDA; coherencia de hold se completara en comandos transaccionales. |
| T-019 | Crear esquema de libro mayor e invariantes diferidos. | T-006, T-015, T-018 | TEST-019: diario desbalanceado por moneda o vacio falla al commit, aun si el total numerico mezclado parece cero; escritura concurrente e intento de editar diario definitivo fallan. | Cuentas compatibles, bloqueo de encabezado y validacion diferida; partida doble e inmutabilidad comprobadas con PostgreSQL real. |
| T-020 | Crear escritura de auditoria transaccional. | T-007, T-018 | TEST-020: revertir transaccion elimina evento del efecto no confirmado; actor/correlacion/motivo completos y eventos definitivos no editables. | Auditoria append-only en la misma transaccion; logs tecnicos no sustituyen historia monetaria. |
| T-021 | Implementar reclamacion y resultado idempotente por comando. | T-009, T-018 | TEST-021: dos conexiones con misma clave/payload recuperan una respuesta; payload/ruta diferente da conflicto; rollback no deja exito, espera agotada indica en curso. | Huella canonica y respuesta durable comparten commit del efecto; no perder proteccion historica segun G-007, pendiente su control de retencion en T-037. |
| T-022 | Implementar adaptador real de directorio. | T-005, T-008 | TEST-022: encontrado, no encontrado e indisponible se distinguen; validar banco, tipo individual y estado. | Cuenta estable y titular del banco, datos exactos y errores seguros; ninguna llamada bajo locks de fondos. |
| T-023 | Implementar POST /v1/recipient-lookups. | T-009, T-016, T-021, T-022 | TEST-023: cuenta existente muestra nombre antes de pedir alias; ausente 404, caida 503; lookupId es propio y tiene vencimiento. | Contrato y autenticacion basica; consulta no guarda destinatario ni acepta titular del cliente; sin numero de cuenta en URL. |
| T-024 | Implementar POST /v1/recipients. | T-009, T-016, T-021, T-023 | TEST-024: guardar alias con lookup valido; rechazar lookup ajeno/vencido, alias invalido y alta concurrente duplicada. | Destino guardado antes de transferir con identificacion estable y politica G-005; respuesta sin datos no autorizados. |
| T-025 | Implementar GET /v1/recipients paginado. | T-009, T-016, T-024 | TEST-025: lista solo propia, seleccion inequivoca por alias, cursor/limit validos y sin fuga de destinatarios ajenos. | Cursor opaco, orden estable y contrato RecipientList; no agregar edicion o borrado fuera de alcance. |
| T-026 | Implementar POST /v1/transfer-quotes. | T-009, T-011, T-012, T-014, T-016, T-017, T-021, T-024 | TEST-026: resumen exacto completo, limite excedido, cuentas no elegibles, t+60, cambio importe/destino y nueva confirmacion; cotizar no reserva. | Condiciones inmutables de hasta 60 segundos segun G-002, transparencia y snapshot unico; usa puerto con fixture en test. Conexion al proveedor real se verifica en T-039. |
| T-027 | Implementar POST /v1/transfers para reservar. | T-015, T-017, T-018, T-020, T-021, T-026 | TEST-027: reservar exactamente disponible deja cero; excederlo falla; fallo entre saldo/hold/transferencia revierte todo; quote usado no reserva otra vez. | Reserva ACID por debito origen, sin diario definitivo; orden de locks y reloj de servidor; respuesta/auditoria atomicas. |
| T-028 | Implementar constructor de asientos y apertura respaldada. | T-011, T-019 | TEST-028: igual moneda tiene dos lados iguales; USD 10 a COP 40000 bruto genera neto 39600, cargo 400 y cinco lineas balanceadas; apertura tambien cuadra. | Constructor puro por plan contable G-006; no inicializar saldos sin libro; residuos conforme a politica aprobada. |
| T-029 | Implementar POST /v1/transfers/{id}/confirm. | T-019, T-020, T-021, T-027, T-028 | TEST-029: consentimiento/quoteId obligatorios, hold activa, debito-credito-comision-diario atomicos; t+60 rechazado y ningun efecto parcial. | CONTABILIZADA solo con diario y hold consumida; reloj revalidado tras locks y al decidir; doble clave no duplica; vencimiento tardio revierte y resuelve expiracion sin debito. |
| T-030 | Implementar POST /v1/transfers/{id}/cancel. | T-020, T-021, T-027 | TEST-030: abandono previo repetido libera una vez; estado contabilizado no cancelable; simular estado definitivo con fixture coherente. | CANCELADA y liberacion comparten commit sin diario; no prometer cancelacion si confirmar ya gano. |
| T-031 | Implementar worker recuperable de expiracion. | T-020, T-027, T-029, T-030 | TEST-031: vencidas expiran una vez, vigentes no; reinicio y dos workers no duplican liberacion; transferencia contabilizada no se modifica. | SKIP LOCKED y orden de locks comun, lote/configuracion documentados; consultas no anuncian liberacion aun no persistida. |
| T-032 | Implementar consultas de transferencia y de operacion por clave. | T-009, T-021, T-027, T-029, T-030, T-031 | TEST-032: recuperar por id y por clave cuando se perdio transferId; ajeno devuelve 404, en curso no se presenta como rechazo definitivo. | GET /v1/transfers/{id} y GET /v1/operations/{operation}/by-key/{key} autorizados; cada envoltorio devuelve schema del comando correcto. |
| T-033 | Implementar GET /v1/transfers/{id}/receipt. | T-007, T-009, T-029, T-032 | TEST-033: comprobante con numero unico e importes originales tras cambiar tasa/alias; reservado/expirado no tiene comprobante exitoso; acceso ajeno falla. | Consulta en plataforma con debito, bruto, comision real y neto, cuentas identificables, titular/alias y fecha; sin PDF ni nuevo movimiento. |
| T-034 | Verificar carreras monetarias en PostgreSQL real. | T-029, T-030, T-031 | TEST-034: escribir barreras primero y demostrar que detectan una via sin bloqueo: dos reservas de 80 sobre 100, confirmacion contra abandono/expiracion y transferencias opuestas. | Solo ganadores compatibles; nunca sobregiro/doble liberacion; orden de locks respeta plan y pruebas terminan sin bloqueo permanente. |
| T-035 | Verificar fallos y recuperacion de commit desconocido. | T-029, T-031, T-032, T-034 | TEST-035: fallo inyectado antes/despues de cada escritura, respuesta perdida tras commit y errores 40001/40P01/timeout; caso sin recuperacion debe fallar. | Rollback completo o resultado durable recuperable; reintentos acotados del plan revalidan tiempo; no nuevo envio para resolver timeout. |
| T-036 | Implementar reconciliacion de fondos, reservas y diario. | T-019, T-020, T-029, T-031 | TEST-036: fixture coherente pasa; discrepancias controladas de saldo, reserva, diario faltante o duplicado generan incidencia. | Informa por moneda y transferencia sin corregir con UPDATE historico; estados administrativos excluidos no se exigen. |
| T-037 | Aplicar controles de seguridad y retencion aprobados. | T-007, T-023, T-024, T-025, T-026, T-027, T-029, T-030, T-032, T-033 | TEST-037: enumeracion, identidad suplantada, accesos cruzados, datos en logs y replay de clave antigua tras mantenimiento. | Rate limiting, masking, permisos y politica G-007 efectivos; no se elimina proteccion contra duplicados; sin habilitar reversiones. |
| T-038 | Cerrar suite de contrato HTTP de los diez endpoints. | T-009, T-023, T-024, T-025, T-026, T-027, T-029, T-030, T-032, T-033 | TEST-038: matriz endpoint x exito/error/schema, incluidos parametros de ruta y query, propiedades extra y ErrorResponse. | Todas las solicitudes/respuestas validan; mensajes seguros y codigos estables; semantica entre campos verificada ademas del JSON Schema. |
| T-039 | Ejecutar recorrido integrado con los 16 pares. | T-013, T-022, T-029, T-031, T-033, T-034, T-035, T-036, T-037, T-038 | TEST-039: recorrido alta-resumen-reserva-confirmacion-comprobante con contratos reales sanitizados en sandbox, matriz completa y fallas de proveedor. | Fixtures monetarios sinteticos para todos los pares y evidencia de integracion sandbox; no declarar cobertura real COP/GTQ si el proveedor no la da. Sin movimientos productivos. |
| T-040 | Cerrar trazabilidad y gate de entrega. | T-039 | TEST-040: comprobador de cobertura falla si falta requisito, caso aplicable, dependencia o evidencia; pipeline falla al inyectar una regresion conocida de schema/saldo. | Todas las puertas cerradas, casos aplicables verdes, build/tipos/lint/CI y revision contable/seguridad con evidencia; sin pendientes bloqueantes ni afirmaciones de rendimiento sin objetivo acordado. |

T-032 agrupa las dos lecturas del mismo resultado durable para no duplicar la logica de recuperacion; no incluye modificaciones monetarias. T-039 no sustituye pruebas focalizadas: verifica composicion y contrato real. Si una fila crece mas alla de un cambio revisable, subdividirla conservando sus identificadores de trazabilidad antes de implementarla.

## 5. Matriz de trazabilidad funcional

Cada fila explicita la cadena RN -> RF -> CA/EA -> tarea -> prueba. Todas las RF tienen cobertura. Los rangos no sustituyen las referencias individuales de esta matriz.

| Requisito | Reglas | Aceptacion | Tareas | Pruebas |
| --- | --- | --- | --- | --- |
| RF-001 | RN-002, RN-023 | CA-001, CA-015, EA-017, EA-027 | T-022, T-023, T-026, T-037 | TEST-022, TEST-023, TEST-026, TEST-037 |
| RF-002 | RN-023 | CA-001, EA-029 | T-023, T-024 | TEST-023, TEST-024 |
| RF-003 | RN-023 | CA-002, EA-024 | T-024, T-025 | TEST-024, TEST-025 |
| RF-004 | RN-001, RN-003 | CA-003, CA-005, CA-015, EA-003, EA-015 | T-010, T-026, T-039 | TEST-010, TEST-026, TEST-039 |
| RF-005 | RN-006, RN-007, RN-026 | CA-007, CA-017, EA-007, EA-008, EA-009 | T-013, T-014, T-026, T-029 | TEST-013, TEST-014, TEST-026, TEST-029 |
| RF-006 | RN-005, RN-009, RN-010 | CA-003, CA-004, CA-005, CA-019, EA-001, EA-002, EA-016 | T-011, T-028, T-039 | TEST-011, TEST-028, TEST-039 |
| RF-007 | RN-024 | CA-006 | T-026, T-029, T-038 | TEST-026, TEST-029, TEST-038 |
| RF-008 | RN-008, RN-024 | CA-007, CA-008, EA-010, EA-028 | T-017, T-026, T-029 | TEST-017, TEST-026, TEST-029 |
| RF-009 | RN-004, RN-011, RN-012 | CA-009, EA-004, EA-005, EA-006 | T-015, T-027, T-034 | TEST-015, TEST-027, TEST-034 |
| RF-010 | RN-013, RN-017, RN-018 | CA-004, CA-010, EA-013, EA-022 | T-019, T-028, T-029, T-035 | TEST-019, TEST-028, TEST-029, TEST-035 |
| RF-011 | RN-007, RN-014, RN-015 | CA-007, CA-010, CA-018, EA-008, EA-009, EA-011, EA-012, EA-021 | T-029, T-030, T-031, T-034 | TEST-029, TEST-030, TEST-031, TEST-034 |
| RF-012 | RN-016, RN-021 | CA-011, EA-014, EA-020 | T-021, T-032, T-035 | TEST-021, TEST-032, TEST-035 |
| RF-013 | RN-020, RN-024 | CA-012, EA-025 | T-029, T-030, T-037 | TEST-029, TEST-030, TEST-037 |
| RF-014 | RN-025 | CA-013, EA-026 | T-033 | TEST-033 |
| RF-015 | RN-017, RN-019, RN-022 | CA-014, EA-022, EA-023 | T-019, T-020, T-028, T-036 | TEST-019, TEST-020, TEST-028, TEST-036 |
| RF-016 | RN-026, RN-027 | CA-015, CA-020, EA-027, EA-033 | T-012, T-013, T-014, T-026 | TEST-012, TEST-013, TEST-014, TEST-026 |
| RF-017 | RN-027 | CA-016, CA-017, CA-020, EA-030, EA-031 | T-014, T-026, T-039 | TEST-014, TEST-026, TEST-039 |
| RF-018 | RN-014, RN-028 | CA-018, EA-032 | T-030, T-031, T-034 | TEST-030, TEST-031, TEST-034 |

RF-007 y CA-006 cubren en backend la entrega del resumen completo y el consentimiento exigido por contrato. Este backlog no demuestra que una pantalla inexistente muestre efectivamente la advertencia. La implementacion y validacion visual del cliente requieren un alcance de interfaz aprobado por separado; no se declara cumplida la experiencia completa por pasar solo un test HTTP.

## 6. Cobertura adicional de reglas y exclusiones

| Regla | Tarea principal | Prueba principal |
| --- | --- | --- |
| RN-001 | T-010 | TEST-010 |
| RN-002 | T-037 | TEST-037 |
| RN-003 | T-010 | TEST-010 |
| RN-004 | T-034 | TEST-034 |
| RN-005 | T-011 | TEST-011 |
| RN-006 | T-026 | TEST-026 |
| RN-007 | T-029 | TEST-029 |
| RN-008 | T-026 | TEST-026 |
| RN-009 | T-011 | TEST-011 |
| RN-010 | T-011 | TEST-011 |
| RN-011 | T-027 | TEST-027 |
| RN-012 | T-034 | TEST-034 |
| RN-013 | T-035 | TEST-035 |
| RN-014 | T-034 | TEST-034 |
| RN-015 | T-031 | TEST-031 |
| RN-016 | T-021 | TEST-021 |
| RN-017 | T-019 | TEST-019 |
| RN-018 | T-028 | TEST-028 |
| RN-019 | T-020 | TEST-020 |
| RN-020 | T-030 | TEST-030 |
| RN-021 | T-035 | TEST-035 |
| RN-022 | T-036 | TEST-036 |
| RN-023 | T-023 | TEST-023 |
| RN-024 | T-026 | TEST-026 |
| RN-025 | T-033 | TEST-033 |
| RN-026 | T-013 | TEST-013 |
| RN-027 | T-014 | TEST-014 |
| RN-028 | T-030 | TEST-030 |

- EA-018 y EA-019: NO APLICABLES al alcance actual; corresponden a reversion administrativa no aprobada. No hay tareas de implementacion para ellos y no se marcan verdes por omision.
- EA-023: se ejecuta con CONTABILIZADA, CANCELADA y EXPIRADA habilitadas; REVERTIDA queda excluida. La evidencia de conciliacion indicara ese alcance.
- EA-016: el techo entero y el redondeo/base de comision quedaron aprobados al cerrar G-002; TEST-011 cubre los casos del bruto y la comision.
- UI, PDF, notificaciones, Saga, proveedores externos y reversiones administrativas no se agregan como tareas implicitas.
- G-004 abierta impide declarar cobertura productiva de conversion/limite no USD; fixtures completos no prueban cobertura del banco real.

## 7. Orden de ejecucion y registro de evidencia

1. Mantener T-001 como baseline cerrado; coordinar T-003 a T-007 con sus responsables y no iniciar tareas que dependan de puertas abiertas.
2. Habilitar T-008 y la base de contratos/dinero/puertos sinteticos T-009, T-010 y T-012. Esas tareas no dependen de tasas reales.
3. Cerrar puertas y avanzar en orden de dependencias hacia resumen, reserva, libro y confirmacion.
4. Completar abandono, expiracion, consultas y comprobante antes de evaluar recuperacion de extremo a extremo.
5. Cerrar concurrencia, fallos, reconciliacion, seguridad y contratos; despues integracion y gate final.

Cuando se ejecute una tarea, agregar una fila a este registro sin reemplazar la evidencia previa:

| Tarea | Estado | Evidencia RED o REV pendiente | Evidencia GREEN o decision aprobada | Responsable / bloqueo |
| --- | --- | --- | --- | --- |
| Sin ejecucion | PENDIENTE | Registro inicial: no habia comandos ni pruebas de backend ejecutados al crear el backlog. | No aplica. | Evidencia historica conservada; no significa que una puerta este cerrada. |
| T-001 | EN_CURSO | REV-001, 2026-10-29: inventario de herramientas con Get-Command y --version. Node.js v26.4.0, npm 11.17.0 y Git 2.53.0.windows.1 disponibles; docker y psql no encontrados en PATH. | Inventario realizado; baseline, CI y decisiones del plan pendientes de aprobacion explicita. No hay prueba RED/GREEN de backend. | G-001 abierta. No se instalaron dependencias ni se inicio T-008. La ausencia de psql no demuestra ausencia de servidor PostgreSQL. |
| T-001 | TERMINADA | REV-001: inventario conservado arriba y consulta de fuentes oficiales de Node/Nest/PostgreSQL el 2026-10-29. | Usuario aprobo baseline y contratos propios; eligio PostgreSQL local/dedicado y Azure Pipelines. Seccion 13 del plan registra versiones mayores, fijacion futura de parches, scripts objetivo y orden CI. | G-001 CERRADA. DT-001 a DT-003 aprobadas. G-002 a G-007 abiertas; T-008 aun no iniciada, requiere verificar PostgreSQL de pruebas y compatibilidad del baseline. |
| T-008 | EN_CURSO | 2026-10-29: test unitario de salud falla por respuesta vacia; tests de guardas PostgreSQL fallan por configuracion sin implementar. Un fallo previo de carga ESM se corrigio y no se conto como RED funcional. | Node 26.13.0 temporal, NestJS 12.3.2, TypeScript 6.0.3 y lockfile instalados. Diez tests unitarios y un test HTTP pasan; typecheck, lint y build pasan. | Integracion PostgreSQL falla antes de conectar por TEST_PGDATABASE ausente. Usuario confirma instancia 18, pero no se verifica version ni SELECT 1 aun. Configuracion real local pendiente; Azure YAML pendiente de ejecucion remota. T-008 no TERMINADA; T-009 y dependientes no iniciadas. |

| T-008 | EN_CURSO | Revalidacion 2026-10-29: tipos, lint, build, diez unitarios y un HTTP pasan tras imports explicitos de Jest y ajuste de puerto YAML. | Archivo local ignorado preparado sin credenciales. Integracion vuelve a fallar antes de conectar, ahora por TEST_PGUSER vacio. YAML Azure parseado y sin errores del editor, no ejecutado remotamente. | Pendiente configurar conexion local y demostrar PostgreSQL 18/SELECT 1. npm audit reporta cinco avisos bajos de Jest/deepmerge; documentados, sin downgrade forzado. T-008 permanece abierta. |

| T-008 | TERMINADA | Evidencia RED previa conservada arriba. Usuario configuro credenciales localmente y creo la base de pruebas; no se leyeron ni mostraron secretos en la conversacion. | 2026-10-29: npm run test:integration -- --runInBand pasa, una suite/un test. Verifica server_version_num entre 180000 y 189999, SELECT 1 y transaction_read_only=on. Se suma a tipos, lint, build, diez unitarios y un HTTP ya verificados. | Arnes local validado sin cambios de datos. Azure YAML validado estaticamente, ejecucion remota aun pendiente y no declarada verde. Cinco avisos bajos de dependencias documentados. T-009, T-010 y T-012 quedan disponibles segun sus dependencias; G-002 a G-007 siguen abiertas. |

| T-009 | TERMINADA | 2026-10-29: caso QuoteRequest valido falla por validador aun no implementado, sin fallo de tipos ni infraestructura; luego pasa el mismo caso con Ajv. | 39 casos TEST-009 verdes; 49 unitarios totales, un HTTP y un PostgreSQL pasan; typecheck, lint y build pasan. JSON extraido comparado como estructuralmente identico al bundle del plan antes de reemplazarlo por enlace; build incluye y carga el JSON. | Fuente unica en backend/src/contracts/transfer.schema.json, 14 contratos y refs resueltos con Ajv 2020-12 estricto y formatos. Sin coercion, defaults o eliminacion de campos; errores sin valores del payload. Reglas de dominio, rutas y proveedores siguen en sus tareas. G-002 a G-007 abiertas; T-010 es el siguiente incremento disponible. |

| T-010 | TERMINADA | 2026-10-29: caso de un centavo falla por parser no implementado, sin fallo de tipos ni infraestructura; luego pasa el mismo caso. | 67 casos TEST-010 y 116 unitarios totales pasan; typecheck, lint y build pasan. Tras ajustes del analizador se repiten los 67 casos y los tres gates, todos verdes. | Money inmutable en backend/src/money/money.ts; cuatro monedas y dos decimales, bigint exacto, rango no negativo de PostgreSQL BIGINT, entrada decimal/DB canonica y JSON con strings. Cero valido como saldo, rechazado como origen. Sin cambios de dependencias, credenciales o datos. HTTP/PostgreSQL no se reejecutan en este incremento aislado. T-012 disponible; T-011 depende aun de T-002/G-002. |

| T-012 | TERMINADA | 2026-10-29: tras corregir un error de tipos del test, el caso de snapshot completo falla por validador aun no implementado; ese es el RED funcional, no el fallo de compilacion previo. | 55 casos TEST-012 y 171 unitarios totales pasan; typecheck, lint y build pasan. Tras ajuste String.raw se repiten los 55 casos y los tres gates, verdes. | RateProvider.snapshot asincrono y RateSnapshot en backend/src/rates; 16 pares completos con razones exactas positivas, version/fuente/politica y vigencia UTC, copia defensiva y freeze profundo. Fixtures/proveedor sintetico solo en test/support; sin API bancaria ni registro en Nest. G-004 sigue abierta; no se imponen inversas ni cruces GTQ al banco. Sin cambios de dependencias, credenciales o datos. T-014 disponible; T-011 requiere T-002 y T-013 requiere T-004. |

| T-014 | TERMINADA | 2026-11-03: `cd backend; npm run test:unit -- --runInBand transfer-limit.spec` con comparador intencionalmente incorrecto falla por comportamiento (5 de 7 casos); el fallo inicial por modulo ausente durante compilacion no se conto como RED. | El mismo comando pasa 7/7 tras restaurar la implementacion. `cd backend; npm run test:unit -- --runInBand` pasa 178 pruebas; `npm run typecheck`, `npm run lint` y `npm run build` pasan. | `backend/src/money/transfer-limit.ts` compara centavos con el limite USD 200 por multiplicacion cruzada bigint y tasa vigente origen/USD; USD no necesita snapshot y una moneda distinta sin snapshot se rechaza. Fixtures sinteticos cubren 199.99/200.00/200.01 USD, EUR 187.50/187.51, cociente periodico y falta de referencia. No usa proveedor real; G-004 sigue abierta y T-013/T-039 esperan contrato real. Las entradas T-002/T-003 posteriores cerraron G-002/G-003; T-015 solo espera su base aislada escribible y rol app. |

| T-003 | TERMINADA | REV-003, 2026-11-03: se identifico la frontera de escritura y se confirmo que no hay otro escritor de esos saldos. | El responsable confirma este backend como escritor unico; saldos, reservas, transferencias, ledger y auditoria monetaria quedan en la misma PostgreSQL y sus efectos comparten una transaccion. G-003 cerrada. | T-015 habilitada. La prueba de migracion requiere una base PostgreSQL aislada y escribible; la conexion actual de T-008 es de solo lectura y no se reutilizara para DDL. |

| T-002 | TERMINADA | REV-002, 2026-11-03: se compararon HALF_UP/HALF_EVEN en 100.005, base de comision cuantizada/exacta, referencia USD para pares no USD iguales y punto de decision temporal. | El usuario aprobo HALF_UP a dos decimales; comision sobre bruto cuantizado con CEILING a unidades enteras; igual moneda sin cotizacion FX pero con referencia origen/USD para pares no USD; resumen/reserva por hasta 60 segundos desde emision sin reiniciar al reservar; vigencia decidida en la escritura final condicional despues de bloqueos. Se actualizaron RN-009/010/011, DT-004/005 y PA-003/005. G-002 cerrada. | Formula implementada y probada en T-011. G-003 cerrada en T-003; G-004 a G-007 siguen abiertas. |

| T-011 | TERMINADA | 2026-11-03: el primer intento detecto modulo ausente durante compilacion y no se conto como RED. Con el esqueleto tipado, `cd backend; npm run test:unit -- --runInBand conversion.spec` falla en los 13 casos por comportamiento no implementado. | El mismo comando pasa 13/13. `cd backend; npm run test:unit -- --runInBand` pasa 191 pruebas; `npm run typecheck`, `npm run lint` y `npm run build` pasan. | `backend/src/money/conversion.ts` calcula bruto exacto, HALF_UP a centavos, comision de 1% sobre bruto cuantizado con techo a unidades enteras, neto positivo y diferencias exactas como razones bigint. Los cuatro pares iguales no cobran conversion ni comision. G-002 cerrada. Calculo puro; no implica persistencia, ledger ni ejecucion de transferencias. |

| T-015 | BLOQUEADA | TEST-015 aun no se ejecuta: el unico harness PostgreSQL existente conecta con `default_transaction_read_only=on`, por lo que no se usa para migraciones ni escrituras. | T-003/G-003 y T-008 estan terminadas; el usuario puede provisionar una base PostgreSQL 18 vacia y aislada con usuario DDL, y un rol `NOLOGIN` de aplicacion separado. | Recurso pendiente: base escribible desechable y rol app disponibles/configurados localmente. Sin esos recursos no ejecutar DDL ni declarar validada la proteccion de privilegios. |

| T-004 | BLOQUEADA | REV-004, 2026-11-03: el usuario confirma que no hay proveedor/contrato real de tasas definido; no se puede validar cobertura, unidades, pares/cruces, valoracion USD, version ni vigencia. | Ninguna. Los snapshots de T-012/T-014 son sinteticos y no se usan como contrato. | Recurso/decision pendiente: seleccionar API bancaria y obtener contrato oficial/respuestas sanitizadas. G-004 permanece abierta; no implementar adaptador real. |

| T-005 | BLOQUEADA | REV-005, 2026-11-03: proveedor y formato real de cuenta no definidos. | Usuario aprobo alias unico por cliente con trim/case-insensitive, cuentas propias deshabilitadas en fase 1 y TTL de lookup de cinco minutos. | G-005 permanece abierta hasta contrato/formato de directorio; politica de edicion de alias sigue pendiente. |

| T-006 | BLOQUEADA | REV-006 no puede verificarse aun: falta recibir el mapeo contable sanitizado que el usuario indica que ya esta aprobado. | Se conoce que existe responsable/mapeo aprobado, pero aun no hay evidencia de cuentas logicas, signos, apertura, residuos y exposicion FX en el repositorio. | G-006 permanece pendiente de evidencia; no diseñar ledger ni aperturas con cuentas inventadas. |

| T-007 | BLOQUEADA | REV-007 pendiente: el usuario confirma que no hay responsable ni politicas de seguridad/identidad asignadas. | Ninguna. | Recurso pendiente: asignar responsable y acordar identidad, privacidad, rate limiting, masking, retencion y acceso a comprobantes. G-007 abierta. |

La validacion de este Markdown comprueba estructura, identificadores, enlaces, cobertura documental y dependencias; no equivale a ejecutar TEST-008 a TEST-040 ni aprobar REV-001 a REV-007. La evidencia de ejecucion real se registra por tarea en la tabla anterior.