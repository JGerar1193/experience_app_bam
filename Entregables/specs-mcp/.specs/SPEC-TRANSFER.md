# SPEC-TRANSFER: transferencias internas entre billeteras

## 1. Estado y proposito

- Version: 0.4.
- Estado: borrador para validacion de negocio; no implica aprobacion de las politicas propuestas.
- Objetivo: transferir fondos entre billeteras internas, con o sin conversion de moneda, reserva de saldo, ausencia de sobregiros y trazabilidad contable.
- Requisitos confirmados: USD, EUR, COP y GTQ; clientes individuales del banco; destinatarios previamente guardados por alias; conversion entre monedas; comision cero en la misma moneda y 1% descontado del importe a acreditar entre monedas distintas; saldo nunca negativo; tasa congelada por un maximo de 60 segundos; atomicidad mediante ACID o Saga con compensacion; partida doble; comprobante y ausencia de cancelacion posterior a la ejecucion.
- Especificacion funcional de fase 1: [01-SPECIFICATION.md](01-SPECIFICATION.md). Describe el que y el por que; este documento conserva las reglas transversales y propuestas tecnicas previas, que no se consideran automaticamente aprobadas.
- Decision tecnica aprobada: Node.js con NestJS, PostgreSQL y ACID para saldos, reservas, transferencia y libro mayor. No se usa Saga en este alcance.
- Plan tecnico separado: [PLAN-TRANSFER.md](PLAN-TRANSFER.md), borrador para revision; los pendientes del proveedor y las propuestas monetarias restantes no quedan aprobados automaticamente.
- Las reglas marcadas como propuestas requieren validacion antes de produccion.

## 2. Alcance y vocabulario

Las billeteras origen y destino representan cuentas internas del banco de personas individuales y pueden pertenecer a usuarios diferentes. Cada billetera tiene una unica moneda y un saldo expresado en esa moneda. Se permiten transferencias entre billeteras distintas de la misma moneda o de monedas diferentes, sin exigir que el destinatario abra una cuenta de la moneda origen. Las transferencias entre cuentas propias quedan deshabilitadas en fase 1.

| Termino | Definicion |
| --- | --- |
| Saldo contabilizado | Saldo de la billetera derivado de movimientos definitivos del libro mayor. |
| Saldo reservado | Suma de reservas activas que aun no se han consumido ni liberado. |
| Saldo disponible | Saldo contabilizado menos saldo reservado. |
| Cotizacion | Condiciones inmutables de conversion, con tasa, importes, precision y vencimiento. |
| Reserva o bloqueo | Retencion de fondos de una transferencia; no es un debito contable definitivo. |
| Bloqueo administrativo | Restriccion operativa de la billetera, diferente de una reserva. |
| Contabilizacion | Persistencia atomica del debito, credito y asientos correspondientes. |
| Reversion | Nueva operacion compensatoria vinculada a la transferencia original; nunca una edicion del historial. |

GTQ es el codigo aprobado para el quetzal guatemalteco y sustituye la denominacion inicial QTZ. QTZ y UYU no se aceptan como monedas de operacion.

## 3. Reglas de negocio

1. **RN-001. Monedas permitidas.** Solo se aceptan USD, EUR, COP y GTQ. Una solicitud con otra moneda se rechaza sin modificar fondos.
2. **RN-002. Identidad y autorizacion.** El actor debe estar autenticado y autorizado para debitar la billetera origen. Ambas billeteras deben existir, ser distintas y estar habilitadas al reservar y al confirmar. El cliente no puede imponer un propietario o saldo arbitrario.
3. **RN-003. Importes exactos.** Los importes deben ser positivos y representables con dos decimales para USD, EUR, COP y GTQ; se procesan con enteros en unidades minimas o decimales exactos, nunca con punto flotante binario. Se rechazan importes de entrada con precision excedente, en lugar de redondearlos silenciosamente.
4. **RN-004. Invariantes de saldo.** Para cada billetera, saldo contabilizado >= 0, saldo reservado >= 0 y saldo disponible = saldo contabilizado - saldo reservado >= 0. Todo camino de debito, incluida una reversion, debe preservar estos invariantes.
5. **RN-005. Debito y comision.** El debito total y la reserva son exactamente el importe origen indicado. La transferencia en si es gratuita. Solo convertir entre distintas monedas cobra 1% del bruto, con techo a unidades enteras destino, descontado del credito sin aumentar el debito origen. En igual moneda no hay conversion ni comision. El resumen muestra bruto, comision de conversion y neto. La comision tiene su propia linea contable.
6. **RN-006. Cotizacion congelada.** Para conversiones, el servidor emite una cotizacion inmutable con identificador, par de monedas, tasa, sentido, importes, fecha de emision y vencimiento. Debe cumplirse 0 < (expires_at - issued_at) <= 60 segundos. La tasa expresa unidades destino por una unidad origen. El cliente no puede modificarla.
7. **RN-007. Tiempo y vencimiento.** La cotizacion solo es valida si el tiempo autoritativo del servidor es estrictamente menor que expires_at. A los 60 segundos exactos, para una vigencia de 60 segundos, ya no es valida. No se usa el reloj del cliente. El control de vigencia forma parte de la decision transaccional final de contabilizacion; reservar o iniciar una peticion no prolonga la vigencia.
8. **RN-008. Alcance de la cotizacion.** Politica propuesta: cada cotizacion se vincula al actor, las dos billeteras, las monedas y el importe origen, y solo puede asociarse a una transferencia. Obtener otra cotizacion genera otro identificador y requiere aceptar sus condiciones; nunca se reemplaza una tasa silenciosamente.
9. **RN-009. Conversion y redondeo.** Bruto exacto = importe origen * tasa. El bruto final se redondea a dos decimales con HALF_UP. La comision es CEILING(bruto final * 0.01) a unidades enteras de moneda destino; importes previos al techo de 0.10, 0.101, 1.00 y 1.01 producen comisiones de 1.00, 1.00, 1.00 y 2.00. El importe origen no se redondea a enteros. Neto = bruto final - comision final, sin otro redondeo; rechazar neto <= 0. Conservar valores exactos, finales y diferencias de cuantizacion como razones exactas. Igual moneda: bruto = neto = origen y comision = 0. Los residuos requieren tratamiento contable sin mezclar monedas para cuadrar un asiento.
10. **RN-010. Misma moneda.** No se requiere cotizacion comercial FX: importe destino y bruto = neto = importe origen, con comision cero en esta version. EUR/EUR, COP/COP y GTQ/GTQ requieren referencia vigente origen/USD para verificar el limite universal; USD/USD no requiere snapshot. El resumen vence a los 60 segundos de emitirse y reservar no extiende ese plazo.
11. **RN-011. Reserva atomica.** Comprobar disponible y crear la reserva es una sola transaccion. Solo se reserva si disponible >= debito total. Un resumen no reserva fondos por si mismo. La reserva vence en expires_at del resumen aceptado, aunque se cree despues de su emision; reservar no reinicia ni extiende su vigencia.
12. **RN-012. Concurrencia.** Se usa bloqueo de filas, actualizacion condicional o aislamiento equivalente que preserve los invariantes. Todas las operaciones que afectan fondos comparten el mismo mecanismo. Los bloqueos de varias billeteras siguen un orden determinista. Un conflicto reintentable no puede duplicar reservas ni asientos.
13. **RN-013. Confirmacion ACID.** Una unica transaccion comprueba estado, autorizacion, billeteras, reserva y vigencia; debita origen, acredita destino, inserta todos los asientos, consume la reserva y cambia el estado a CONTABILIZADA. Cualquier fallo revierte el conjunto. No se expone credito destino sin el debito y el asiento completos, ni viceversa.
14. **RN-014. Carrera entre decisiones.** Confirmar, cancelar y expirar compiten por la misma version o bloqueo transaccional. Solo una transicion desde RESERVADA puede ganar. Si la cotizacion vence antes de la decision final de contabilizacion, no se contabiliza y se libera la reserva de forma atomica con la expiracion.
15. **RN-015. Liberacion y expiracion.** Cancelar o expirar libera la reserva exactamente una vez y no genera una transferencia contable. Un proceso de recuperacion debe completar expiraciones pendientes tras reinicios. Aunque el proceso se retrase, una reserva vencida no se puede confirmar. Las consultas no deben presentar fondos vencidos como liberados si el mecanismo transaccional aun los considera reservados.
16. **RN-016. Idempotencia.** Cada comando monetario requiere una clave de idempotencia, con alcance actor + tipo de comando + clave y huella de sus parametros. Misma clave y mismos parametros recuperan la misma operacion sin repetir efectos; misma clave y parametros diferentes generan conflicto. Un resultado desconocido por timeout se consulta o reintenta con la misma clave, no con una nueva.
17. **RN-017. Partida doble.** Cada transferencia contabilizada genera un diario con al menos dos lineas y referencias unicas a la transferencia. Para cada moneda del diario, suma de debitos = suma de creditos; equivalentemente, la suma de importes con signo es cero. No se suman USD, EUR, COP y GTQ como magnitudes intercambiables.
18. **RN-018. Cuentas de cambio.** Una conversion utiliza cuentas puente de cambio por moneda, ademas de las cuentas de billetera. Se registran la tasa y la cotizacion aplicadas. El plan de cuentas debe permitir rastrear la exposicion cambiaria; cuadrar el diario no demuestra por si solo liquidez o rentabilidad.
19. **RN-019. Historial inmutable.** Los asientos definitivos no se editan ni eliminan. La auditoria registra actor, comando, estado anterior y nuevo, motivo, timestamps UTC, correlacion, cotizacion y referencia al diario. La evidencia de cada transicion y de la idempotencia se guarda atomicamente con su efecto. Los logs de aplicacion no sustituyen al libro mayor.
20. **RN-020. Correccion excepcional sin sobregiro.** Una transferencia ejecutada no puede ser cancelada ni revertida por el cliente. La siguiente alternativa administrativa es solo una propuesta pendiente, fuera del flujo de fase 1: reversion total autorizada con importes originales y asientos inversos, incluida la comision, sin nueva tasa. Requiere billeteras habilitadas y disponible suficiente en el destino para devolver el neto recibido. Sin fondos, se rechaza sin cambios. Cualquier correccion futura conserva el historial, preserva los invariantes y tiene idempotencia propia.
21. **RN-021. Fallos recuperables.** Un fallo tecnico previo al commit deja la transferencia en su ultimo estado durable; desde RESERVADA permite reintentar mientras siga vigente, o expirar/cancelar. Una respuesta perdida despues del commit no cambia CONTABILIZADA a FALLIDA. Debe poder consultarse el resultado durable.
22. **RN-022. Reconciliacion.** Se verifica por moneda que los diarios cuadran, que los saldos coinciden con el libro mayor y que las reservas activas coinciden con el saldo reservado. Cada CONTABILIZADA tiene exactamente un diario original y cada REVERTIDA uno compensatorio adicional. Toda discrepancia genera una incidencia auditable; no se corrige editando asientos.
23. **RN-023. Clientes y destinatarios.** Solo participan personas individuales con cuentas internas del banco. Para agregar un destino, el cliente ingresa su numero de cuenta y se consulta la API bancaria correspondiente. Si se encuentra, se muestra el nombre completo del titular y despues se solicita el alias; si no se encuentra, se informa el error y no se guarda el destinatario. Una indisponibilidad de la API no equivale a cuenta inexistente y tampoco autoriza el alta sin verificar. El destino debe estar guardado antes de transferir y se selecciona por su alias personal, sin ambiguedad. El alias es unico por cliente despues de trim y normalizacion case-insensitive; no reemplaza la identificacion interna ni autoriza el debito.
24. **RN-024. Confirmacion transparente.** Antes de autorizar se muestran origen, alias, nombre completo del titular destino, monedas, importe a debitar, tasa cuando aplique, bruto convertido, porcentaje e importe de comision, credito neto y vigencia. Se advierte que una transferencia ejecutada no puede cancelarse. Si cambian las condiciones o vence la cotizacion, se requiere una nueva revision y confirmacion explicita; no se ejecuta con otra tasa sin consentimiento.
25. **RN-025. Comprobante.** Cada transferencia contabilizada tiene un comprobante consultable dentro de la plataforma, sin requerir PDF o envio externo, con numero unico, fecha, estado, cuentas identificables, alias y titular destino, monedas, debito, tasa cuando aplique, bruto, porcentaje e importe de comision de conversion y neto. Refleja las condiciones ejecutadas; no se recalcula con tasas nuevas ni repite la transferencia.
26. **RN-026. Referencia cambiaria del dia.** La fuente es la API bancaria. El JSON compartido es solo ilustrativo de pares y no confirma contrato ni coherencia con GTQ. Pendientes: unidades, precision, vigencia y politica de directos/cruces. Si se acuerdan referencias coherentes q(M) en GTQ por unidad con q(GTQ)=1, tasa = q(origen)/q(destino) y equivalente USD = importe * q(origen)/q(USD). No invertir ni derivar tasas comerciales sin acuerdo. La referencia diaria no extiende los 60 segundos. Sin datos vigentes, completos y positivos para conversion o limite se impide ejecutar, incluso en igual moneda no USD. Los valores del ejemplo no se usan en produccion.
27. **RN-027. Limite universal por transferencia.** El equivalente del importe origen antes de comision debe ser menor o igual a USD 200.00, incluso en igual moneda. Usar la misma referencia congelada que el resumen sin redondear para admitir excesos. Exactamente USD 200.00 se permite; cualquier exceso se rechaza antes de reservar. Descontar comision de conversion no permite eludir el limite. No se fija limite acumulado diario o mensual.
28. **RN-028. Abandono previo e irreversibilidad.** El cliente puede salir antes de confirmar; se cancela la solicitud y se libera cualquier reserva activa exactamente una vez. Una transferencia ejecutada es irreversible dentro del flujo del producto y no se puede cancelar. Salir o cerrar la pantalla durante una confirmacion en curso no prueba cancelacion: se debe recuperar el resultado durable y resolver cualquier carrera conforme a RN-014. Las correcciones administrativas siguen fuera de alcance y no se habilitan por esta regla.

## 4. Estados de las transferencias

| Estado | Significado | Efecto sobre fondos |
| --- | --- | --- |
| CREADA | Solicitud durable aceptada para evaluar; aun sin reserva. | Ninguno. |
| RESERVADA | Validaciones aprobadas y fondos bloqueados. | Disminuye disponible; contabilizado no cambia. |
| CONTABILIZADA | Transferencia confirmada y diario persistido. | Debito origen, credito destino y consumo de reserva atomicos. |
| RECHAZADA | Solicitud invalida o sin fondos antes de reservar. | Ninguno. |
| CANCELADA | Solicitud cancelada antes de contabilizar. | Reserva liberada, si existia. |
| EXPIRADA | Se agoto la vigencia sin contabilizar. | Reserva liberada, si existia. |
| REVERTIDA | Se contabilizo una reversion total autorizada. | Efecto original compensado por un nuevo diario. |

Transiciones permitidas:

- CREADA -> RESERVADA, RECHAZADA, CANCELADA o EXPIRADA.
- RESERVADA -> CONTABILIZADA, CANCELADA o EXPIRADA.
- CONTABILIZADA -> REVERTIDA es una extension administrativa propuesta, no habilitada al cliente ni incluida en la fase 1; requiere aprobar RN-020.
- RECHAZADA, CANCELADA, EXPIRADA y REVERTIDA son terminales.
- CONTABILIZADA es definitiva para el movimiento original: expirar la cotizacion despues no lo deshace.
- CANCELADA describe el abandono permitido antes de confirmar; nunca una cancelacion de una transferencia ya contabilizada. Si confirmar y abandonar compiten, se recupera el resultado durable.
- No existe un estado FALLIDA ambiguo que oculte si hubo movimiento de dinero. Los intentos fallidos se auditan aparte.

El estado de reserva es ACTIVA, CONSUMIDA o LIBERADA. CONSUMIDA solo corresponde a CONTABILIZADA; CANCELADA y EXPIRADA no pueden conservar una reserva activa. El identificador y el diario de la reversion se conservan separados de los originales.

## 5. Flujo funcional y datos minimos

1. Seleccionar un destinatario previamente guardado por alias e indicar el importe origen. Solicitar cotizacion cuando las monedas sean diferentes y mostrar el resumen RN-024 con comision y neto.
2. Crear la transferencia con clave de idempotencia, actor, billeteras, importe y cotizacion cuando aplique.
3. Validar y reservar el debito total en una transaccion; devolver estado y vencimiento.
4. Obtener confirmacion explicita del resumen y de la imposibilidad de cancelar despues de ejecutar; confirmar con otro comando idempotente mientras la reserva y la cotizacion sigan vigentes.
5. Contabilizar todo en una unica transaccion y devolver la referencia del diario.
6. Permitir consultar por identificador o recuperar el resultado mediante la clave del comando ante un timeout.
7. Entregar el comprobante RN-025. Permitir abandonar antes de confirmar y liberar su reserva; expirar reservas no consumidas, reconciliar y recuperar operaciones despues de interrupciones. Nunca cancelar una transferencia ya contabilizada.

| Entidad | Datos minimos |
| --- | --- |
| Billetera | id, propietario, moneda, estado operativo, version de concurrencia. |
| Saldo | billetera, contabilizado, reservado, version; disponible calculado. |
| Destinatario guardado | cliente, alias personal, cuenta destino, titular validado por el banco y estado. |
| Cotizacion | id, actor, billeteras, monedas, importe origen, tasa decimal, referencia del dia, sentido, bruto exacto/final, precision, redondeo, porcentaje e importe de comision, neto, issued_at, expires_at. |
| Transferencia | id, actor, billeteras, monedas, importes, debito total, comision, neto, copia del alias y titular al ejecutar, cotizacion opcional, estado, version, timestamps, motivo. |
| Reserva | id, transferencia unica, billetera origen, importe, estado, created_at, expires_at. |
| Diario y lineas | id de diario, transferencia, tipo original/reversion, moneda, cuenta, debito o credito positivo, timestamp y referencias. |
| Idempotencia | actor, comando, clave, huella de parametros, operacion asociada y resultado durable. |
| Auditoria | actor, accion, entidad, estado anterior/nuevo, motivo, correlacion y timestamp UTC. |

Las restricciones de unicidad impiden multiples reservas por transferencia, multiples diarios originales y multiples reversiones totales. Un indice o restriccion de saldo no sustituye al control transaccional entre estas entidades.

## 6. Ejemplo contable verificable

Supuesto ilustrativo: las billeteras son pasivos del banco y tasa USD/COP = 4,000 COP por USD. El cliente indica USD 10.00: se debitan USD 10.00, bruto COP 40,000.00, comision 1% = COP 400.00 y credito neto COP 39,600.00. Este ejemplo no fija una tasa comercial.

Antes de reservar: origen contabilizado USD 15.00, reservado USD 0.00, disponible USD 15.00; destino contabilizado COP 0.00. Al reservar: origen contabilizado USD 15.00, reservado USD 10.00, disponible USD 5.00; destino sin cambios.

| Cuenta | Moneda | Debe | Haber |
| --- | --- | --- | --- |
| Pasivo billetera origen | USD | 10.00 | 0.00 |
| Puente de cambio USD | USD | 0.00 | 10.00 |
| Puente de cambio COP | COP | 40000.00 | 0.00 |
| Pasivo billetera destino | COP | 0.00 | 39600.00 |
| Ingreso por comision | COP | 0.00 | 400.00 |

Resultado: USD suma cero y COP suma cero por separado. Tras confirmar: origen contabilizado/disponible USD 5.00, reservado USD 0.00; destino contabilizado/disponible COP 39,600.00. Una transferencia de la misma moneda debita el pasivo origen y acredita el pasivo destino sin cuentas de cambio ni comision. La propuesta de reversion administrativa invierte Debe y Haber del diario original, incluida la comision; no es una cancelacion disponible al cliente.

El plan de cuentas definitivo, la financiacion de las cuentas puente y el tratamiento de residuos requieren validacion contable. Las cuentas puente no son billeteras de usuario y su signo contable no representa un sobregiro permitido a un usuario.

## 7. Escenarios de aceptacion

Cada escenario debe convertirse en una prueba automatizada cuando exista implementacion. Los tiempos se controlan mediante un reloj de servidor sustituible en pruebas.

| ID | Dado / Cuando / Entonces | Reglas |
| --- | --- | --- |
| EA-001 | Dadas dos billeteras USD y disponible 100.00 en origen; al reservar y confirmar 25.00; entonces origen disminuye 25.00, destino aumenta 25.00, reserva queda consumida y existe un solo diario USD balanceado. | RN-004, 010, 013, 017 |
| EA-002 | Dado el ejemplo USD/COP de la seccion 6; al confirmar dentro de vigencia; entonces se obtienen exactamente sus saldos y cinco lineas, incluida la comision COP 400.00, balanceadas por moneda. | RN-005, 006, 009, 013, 018 |
| EA-003 | Dadas billeteras de las cuatro monedas; al ejecutar la matriz de 16 pares origen/destino, incluidas misma moneda y ambos sentidos de conversion; entonces todos usan las precisiones configuradas, conservan invariantes y cuadran por moneda. | RN-001, 003, 009, 010, 017 |
| EA-004 | Dado disponible 10.00; al intentar reservar 10.01; entonces se rechaza sin reserva, cambios de saldo ni diario. | RN-004, 005, 011 |
| EA-005 | Dado disponible 10.00; al reservar exactamente 10.00; entonces disponible queda cero, nunca negativo, y la confirmacion es posible dentro de vigencia. | RN-004, 011 |
| EA-006 | Dado saldo 100.00 y ninguna reserva; al competir dos transferencias de 80.00; entonces como maximo una reserva tiene exito y no se supera 100.00 reservado. | RN-004, 012 |
| EA-007 | Dada una cotizacion de 60 segundos; al confirmar en t+59 segundos; entonces se aplica la tasa congelada aunque la tasa de mercado haya cambiado. | RN-006, 007 |
| EA-008 | Dada una cotizacion de 60 segundos; al confirmar exactamente en t+60 o despues, aunque se haya reservado antes; entonces no se contabiliza, se expira y se libera la reserva una sola vez. | RN-007, 014, 015 |
| EA-009 | Dada una cotizacion emitida en t; al reservar en t+50; entonces vence en t+60, no en t+110; solicitar vigencia mayor de 60 segundos no produce una cotizacion valida. | RN-006, 011 |
| EA-010 | Dada una cotizacion o importe manipulado, asociado a otra billetera, o reutilizado para otra transferencia; al solicitar reserva; entonces se rechaza sin efectos monetarios. | RN-002, 006, 008 |
| EA-011 | Dada una reserva activa; al cancelar dos veces o reejecutar su expiracion; entonces solo se libera el importe original una vez y no se generan asientos. | RN-014, 015, 016 |
| EA-012 | Dada una reserva activa; al competir confirmacion y cancelacion/expiracion; entonces solo una gana y no hay transferencia contabilizada con reserva liberada por cancelacion. | RN-013, 014 |
| EA-013 | Dada una confirmacion en curso; al inyectar un fallo entre debito, credito, escritura del diario y cambio de estado; entonces se revierte todo, se conserva el estado durable previo y un reintento vigente puede completar una sola contabilizacion. | RN-013, 021 |
| EA-014 | Dada una respuesta perdida despues del commit; al reintentar el mismo comando, incluso concurrentemente, con la misma clave y parametros; entonces se recupera la misma operacion sin duplicar movimientos. Cambiar parametros con esa clave produce conflicto. | RN-016, 021 |
| EA-015 | Dados importe cero, negativo, precision excedente, resultado destino cero, UYU u otra moneda no permitida; al solicitar transferencia; entonces se rechaza sin modificar fondos. | RN-001, 003, 009 |
| EA-016 | Dadas comisiones calculadas antes del techo de 0.10, 1.00 y 1.01; al cuantizar la comision de conversion; entonces se cobran 1.00, 1.00 y 2.00. Se conserva la diferencia y neto = bruto - comision; casos dependientes del bruto esperan su aprobacion. | RN-003, 009 |
| EA-017 | Dado un actor sin permiso o una billetera bloqueada antes de reservar o confirmar; al ejecutar el comando; entonces se rechaza sin contabilizar. Si habia reserva, queda cancelable y expirable, nunca retenida indefinidamente. | RN-002, 015 |
| EA-018 | Extension administrativa pendiente, no exigible en fase 1: dada su aprobacion y destino con disponible suficiente; al revertir autorizadamente dos veces con la misma clave; entonces existe un solo diario compensatorio que incluye la comision, se restauran los saldos y el original permanece intacto. | RN-016, 019, 020 |
| EA-019 | Extension administrativa pendiente, no exigible en fase 1: dada su aprobacion y destino sin disponible suficiente; al intentar revertir; entonces no hay sobregiro, asientos parciales ni cambio del estado original y se audita el rechazo. | RN-004, 020 |
| EA-020 | Dada una transferencia contabilizada; al vencer su cotizacion o ejecutar el recuperador; entonces no se libera saldo ni se deshace el movimiento. | RN-014, 015, 021 |
| EA-021 | Dada una interrupcion con reservas pendientes; al reiniciar el recuperador; entonces expira las vencidas una sola vez y permite continuar las vigentes sin duplicar fondos ni diarios. | RN-015, 016, 021 |
| EA-022 | Dado un diario con debitos y creditos que no cuadran en alguna moneda; al intentar contabilizarlo; entonces se rechaza la transaccion completa. | RN-013, 017 |
| EA-023 | Dadas operaciones confirmadas, canceladas, expiradas y revertidas; al reconciliar; entonces saldos, reservas y diarios coinciden y cada operacion puede reconstruirse con sus referencias de auditoria. Una discrepancia inyectada genera incidencia. | RN-019, 022 |
| EA-024 | Dado un destinatario previamente guardado; al seleccionarlo por alias; entonces se muestra el alias y el nombre completo validado por el banco. Un alias no registrado o ambiguo no permite avanzar ni mover fondos. | RN-023, 024 |
| EA-025 | Dada una transferencia contabilizada; al pedir su cancelacion como cliente; entonces se rechaza sin modificar saldos, asientos o estado. Antes de ejecutar se mostro esa advertencia. | RN-020, 024 |
| EA-026 | Dada la transferencia de EA-002; al consultar su comprobante despues de cambiar la tasa del dia; entonces conserva numero unico, debito USD 10.00, comision COP 400.00 y neto COP 39600.00, sin nuevos movimientos. | RN-025 |
| EA-027 | Dado un solicitante empresa, una cuenta externa o una conversion sin tasa del dia vigente; al intentar transferir; entonces se impide ejecutar sin debitar ni acreditar. | RN-023, 026 |
| EA-028 | Dada una cotizacion revisada; al vencer o cambiar importe o destino; entonces se requiere otro resumen y confirmacion explicita antes de ejecutar con condiciones nuevas. | RN-008, 024 |
| EA-029 | Dada una busqueda por numero de cuenta; al consultar la API; entonces si existe se muestra titular completo y despues se solicita alias, y si no existe se muestra error sin guardar destino. Una falla de API impide el alta y se distingue de no encontrado. | RN-023 |
| EA-030 | Dada valoracion vigente sobre el importe origen antes de comision; al solicitar equivalentes USD 199.99, USD 200.00 y USD 200.01; entonces se permiten los dos primeros y se rechaza el tercero antes de reservar, incluidos pares de igual moneda. | RN-026, 027 |
| EA-031 | Dada, como fixture normalizado, q(EUR)=8.00 GTQ/EUR y q(USD)=7.50 GTQ/USD; al valorar EUR 187.50 y EUR 187.51; entonces el primero equivale a USD 200.00 y se permite, y el segundo supera el limite y se rechaza sin redondearlo a USD 200.00. | RN-026, 027 |
| EA-032 | Dada una solicitud aun no confirmada con reserva activa; al salir y repetir el abandono; entonces queda CANCELADA y la reserva se libera una sola vez sin diario. Si ya hay confirmacion en curso, se informa su resultado durable, sin prometer cancelacion. | RN-014, 015, 028 |
| EA-033 | Dado un par no USD, incluso de igual moneda; al faltar la tasa necesaria para valorar el limite o recibirse datos incompletos, vencidos o no positivos; entonces no se ejecuta sin validar el limite, ni se usa otra referencia silenciosamente. | RN-026, 027 |

## 8. No-objetivos

- Transferencias a otros bancos, billeteras externas, efectivo, tarjetas o liquidacion con proveedores externos; las transferencias internas del banco si estan incluidas.
- Empresas, personas juridicas, UYU, QTZ, criptomonedas y otras monedas distintas de USD, EUR, COP y GTQ.
- Sobregiros, credito, prestamos, saldos negativos temporales o excepciones administrativas al invariante.
- Reservas parciales, pagos fraccionados, transferencias por lotes y reversiones parciales.
- Cancelaciones posteriores a la ejecucion por parte del cliente; las correcciones administrativas quedan pendientes y fuera de fase 1.
- Implementar un proveedor real de tasas, estrategias de cobertura, spreads comerciales o un motor de tesoreria.
- Definir obligaciones tributarias, regulatorias, KYC/AML o certificaciones de cumplimiento.
- Elegir lenguaje, framework, base de datos, endpoints definitivos o construir interfaces de usuario.
- Implementar una Saga distribuida en esta version. Si se divide la frontera transaccional, se requiere una ampliacion que defina pasos, fondos pendientes no gastables, compensaciones idempotentes, recuperacion y garantia de no sobregiro en cada paso; no basta con llamar atomica a una Saga.

## 9. Decisiones pendientes y criterio de cierre

Antes de implementar deben aprobarse:

1. Resuelto el 2026-11-03: bruto HALF_UP a dos decimales; comision sobre bruto cuantizado con techo a unidades enteras destino; neto = bruto menos comision y se rechaza si no es positivo.
2. Contrato real de API bancaria, politica de pares directos/cruces, precision, zona horaria y vigencia. JSON ilustrativo incompleto; no se extiende cotizacion vencida.
3. Resuelto el 2026-11-03: resumen/reserva de igual moneda vence a los 60 segundos desde emision y no se prolonga al reservar. Transferencia gratis y conversion con 1% y techo entero ya confirmadas.
4. Plan de cuentas, cuentas puente, tratamiento de redondeos y gestion de liquidez/exposicion por moneda.
5. Si existira correccion administrativa, roles, tratamiento de la comision y proceso ante fondos insuficientes. No hay cancelacion de operaciones ejecutadas para el cliente.
6. Limites acumulados, alcance de bloqueos, retencion de auditoria/idempotencia y objetivo de liberacion. USD 200.00 sobre importe origen ya aprobado. No permitir reprocesar comandos historicos como nuevos.
7. Resuelto el 2026-11-03: cuentas propias deshabilitadas en fase 1 y alias unico por cliente con trim y normalizacion case-insensitive. Pendientes: contrato real del directorio, formato de cuenta y politica de edicion de alias. La busqueda por numero de cuenta y el abandono previo a confirmar ya estan aprobados.

El spec queda listo al aprobar decisiones que afectan importes, estados o contabilidad. Se aceptara cuando EA-001 a EA-033 aplicables pasen y contabilidad valide el ejemplo. Casos EA-016 dependientes del bruto esperan su redondeo. EA-018 y EA-019 solo con extension administrativa aprobada; EA-023 cubre estados habilitados. Se requieren concurrencia, reloj controlado, fallos y reconciliacion. No se afirma implementacion ni pruebas ejecutadas.