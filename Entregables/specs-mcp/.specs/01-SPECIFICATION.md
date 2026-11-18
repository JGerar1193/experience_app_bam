# Fase 1: especificacion funcional de transferencias internas

## 1. Estado y relacion con las reglas existentes

- Version: 0.3.
- Estado: borrador basado en requisitos confirmados por negocio, con preguntas abiertas explicitas.
- Proposito de esta fase: definir que necesita el cliente y por que, sin elegir arquitectura, tecnologia, almacenamiento ni contratos de API.
- Referencia de reglas: [SPEC-TRANSFER.md](SPEC-TRANSFER.md), version 0.4, RN-001 a RN-028. Las propuestas anteriores siguen pendientes salvo confirmacion expresa.
- Plan separado: [PLAN-TRANSFER.md](PLAN-TRANSFER.md). Entorno confirmado: Node.js, NestJS, PostgreSQL y ACID; el como se define en el plan.
- Los requisitos de este documento incorporan GTQ y la comision confirmada; no se mantienen QTZ ni la propuesta anterior de comision cero para conversiones.

## 2. Problema y valor esperado

Los clientes individuales del banco necesitan transferir valor a otras cuentas internas aunque la cuenta destino use otra moneda. No deben abrir una cuenta adicional en la moneda origen para recibir la transferencia ni realizar por separado una conversion manual.

Mantener el proceso dentro del banco busca agilizar el envio y dar certeza antes de autorizar: el cliente debe conocer cuanto se debitara, que tasa del dia se aplicara, que comision se cobrara y cuanto recibira el destinatario. La transparencia es esencial porque una transferencia ejecutada no se puede cancelar por el cliente.

El resultado esperado es una transferencia interna completa, sin saldos negativos, con evidencia contable y un comprobante verificable. No se atribuye aun una mejora cuantitativa de tiempo: el objetivo y la linea base estan pendientes.

## 3. Actores y alcance

| Actor | Necesidad o responsabilidad |
| --- | --- |
| Cliente ordenante | Persona individual con cuenta interna, autorizada para enviar desde ella, que indica el importe origen y confirma las condiciones. |
| Destinatario | Persona individual con cuenta interna previamente guardada por el ordenante mediante un alias personal; recibe el importe neto en la moneda de su cuenta. |
| Banco | Proporciona identidad de titulares, referencia cambiaria del dia, ejecucion interna, proteccion de fondos, contabilidad y comprobante. |

Se admiten USD, EUR, COP y GTQ, tanto en la misma moneda como entre monedas distintas. QTZ no es un codigo operativo valido. No se incluyen cuentas de empresas ni destinos externos. Las transferencias entre cuentas del mismo titular requieren confirmacion de alcance y no se asumen habilitadas.

## 4. Historias de usuario

| ID | Historia | Valor |
| --- | --- | --- |
| HU-001 | Como cliente, quiero guardar una cuenta destino con un alias y ver el nombre completo de su titular al agregarla. | Identificar al destinatario y reducir errores de envio. |
| HU-002 | Como cliente, quiero seleccionar un destinatario guardado e indicar el importe en la moneda de mi cuenta. | Enviar sin calcular manualmente la conversion ni abrir otra cuenta. |
| HU-003 | Como cliente, quiero revisar debito, tasa, comision y credito neto antes de confirmar. | Autorizar con conocimiento del costo y del resultado. |
| HU-004 | Como cliente, quiero que solo se complete la transferencia si puede ejecutarse integra y sin sobregiros. | Proteger mis fondos y los del destinatario. |
| HU-005 | Como cliente, quiero un comprobante con numero de transaccion y desglose de importes. | Consultar y acreditar lo realmente ejecutado. |

## 5. Recorrido principal

1. Antes de transferir, el cliente busca al destinatario por numero de cuenta mediante la API bancaria. Si existe, se muestra su nombre completo y despues se pide asignar un alias; si no se encuentra, se muestra error sin guardar el destino. Un fallo del servicio se distingue de una cuenta no encontrada y no permite guardar sin verificar.
2. El cliente selecciona su cuenta origen y el destinatario desde sus alias guardados.
3. Indica cuanto desea enviar en la moneda origen. La moneda destino corresponde a la cuenta guardada, no a una nueva cuenta que deba abrirse.
4. La herramienta calcula el resultado con las tasas de la API bancaria segun su contrato real pendiente y verifica el limite universal equivalente a USD 200.00, incluso en igual moneda. No impone cruces GTQ sin acuerdo. Muestra la vigencia sin extender el congelamiento mas alla de 60 segundos.
5. Antes de confirmar, presenta el nombre completo y alias destino, las cuentas identificables, debito, monedas, tasa si aplica, bruto, comision y neto, y advierte que la transferencia ejecutada no se puede cancelar.
6. El cliente confirma explicitamente esas condiciones. Una cotizacion vencida exige actualizar el resumen y volver a confirmar.
7. El banco completa todos los efectos o ninguno, preservando los saldos y generando contabilidad de partida doble.
8. Solo si se completo, el cliente recibe un comprobante y puede volver a consultarlo sin repetir el envio. Si no se conoce aun el resultado, no se presenta como exito ni se invita a iniciar otra transferencia como si la primera no existiera.

No se fija en esta fase el instante exacto de la reserva dentro de la experiencia. Debe proteger fondos sin permitir confirmaciones vencidas ni retenciones indefinidas.

## 6. Requisitos funcionales

| ID | El sistema debe | Referencia |
| --- | --- | --- |
| RF-001 | Restringir la operacion a personas individuales con cuentas internas habilitadas y permitir debitar solo cuentas autorizadas del cliente. | RN-002, RN-023 |
| RF-002 | Buscar el destino por numero de cuenta mediante la API bancaria; si existe, mostrar su nombre completo y despues pedir alias para guardarlo; si no existe, mostrar error y no guardarlo. No confundir indisponibilidad con no encontrado. | RN-023 |
| RF-003 | Permitir seleccionar el destino por su alias guardado, sin confundir alias de distintos clientes ni resolver un alias ambiguo a una cuenta arbitraria. | RN-023 |
| RF-004 | Aceptar un importe positivo con dos decimales en moneda origen y trabajar solo con USD, EUR, COP y GTQ; no exigir una cuenta destino en moneda origen. | RN-001, RN-003 |
| RF-005 | Mostrar el calculo previo con la API de tasas del banco segun la politica de pares/cruces aprobada y congelar las condiciones por un periodo no mayor de 60 segundos, mostrando su vencimiento. | RN-006, RN-007, RN-026 |
| RF-006 | No cobrar por transferir; cobrar solo por convertir: 1% del bruto con techo a unidades enteras de moneda destino, descontado del credito sin aumentar el debito origen. En igual moneda no hay conversion ni comision. | RN-005, RN-009, RN-010 |
| RF-007 | Mostrar antes de confirmar el titular y alias destino, cuentas identificables, monedas, debito, tasa aplicable, bruto, porcentaje e importe de comision, neto y advertencia de no cancelacion posterior. | RN-024 |
| RF-008 | Exigir consentimiento explicito sobre las condiciones mostradas y una nueva confirmacion cuando cambien importe, destino o cotizacion; nunca ejecutar con una tasa nueva silenciosamente. | RN-008, RN-024 |
| RF-009 | Reservar solo fondos disponibles y garantizar que ninguna cuenta quede negativa, incluso con solicitudes simultaneas. | RN-004, RN-011, RN-012 |
| RF-010 | Completar debito, credito neto, comision y contabilidad como una unica operacion de negocio, sin efectos parciales definitivos. | RN-013, RN-017, RN-018 |
| RF-011 | Rechazar una confirmacion vencida y liberar las reservas no consumidas sin dobles liberaciones ni retenciones indefinidas. | RN-007, RN-014, RN-015 |
| RF-012 | Evitar duplicados ante doble confirmacion o reintentos y permitir recuperar el resultado de una solicitud cuya respuesta se perdio. | RN-016, RN-021 |
| RF-013 | Impedir que el cliente cancele una transferencia ya ejecutada; no ofrecer una reversion automatica como alternativa equivalente. | RN-020, RN-024 |
| RF-014 | Permitir consultar dentro de la plataforma el comprobante con numero unico, fecha, estado, cuentas identificables, alias/titular destino, monedas, debito, tasa cuando aplique, bruto, comision de conversion y neto originales; no se requiere PDF ni envio externo. | RN-025 |
| RF-015 | Conservar evidencia de cada operacion y movimientos contables que sumen cero por moneda, permitiendo su reconciliacion sin editar el historial. | RN-017, RN-019, RN-022 |
| RF-016 | Impedir ejecutar cuando falte la referencia vigente necesaria para convertir o verificar el limite universal, sin sustituirla silenciosamente por datos antiguos. | RN-026, RN-027 |
| RF-017 | Permitir solo transferencias con equivalente menor o igual a USD 200.00 por operacion, incluidas las de igual moneda, valorando el importe origen antes de comision sin redondear para admitir excesos. | RN-027 |
| RF-018 | Permitir salir antes de confirmar y liberar cualquier reserva una sola vez; una transferencia ejecutada es irreversible en este flujo. Una salida durante una confirmacion en curso exige recuperar su resultado, no asumir cancelacion. | RN-014, RN-028 |

## 7. Calculo visible y ejemplos

Reglas confirmadas de negocio:

- Debito origen = importe indicado por el cliente.
- En igual moneda: comision = 0 y credito destino = importe origen.
- En distinta moneda: bruto exacto = importe origen * tasa; bruto final = HALF_UP(bruto exacto, 2); comision de conversion = CEILING(1% del bruto final) a unidades enteras destino; neto = bruto final - comision final. No hay un cargo adicional por transferir.
- La comision se expresa y descuenta en moneda destino; nunca se cobra otra vez aumentando el debito origen.
- USD, EUR, COP y GTQ usan dos decimales. Importes previos al techo de comision de 0.10/0.101/1.00/1.01 producen 1.00/1.00/1.00/2.00. Aprobado el 2026-11-03: bruto HALF_UP y comision sobre bruto cuantizado. El importe origen no se redondea a enteros; se conservan exactos, finales y diferencias.
- El maximo es USD 200.00 sobre el importe origen antes de comision, usando la misma referencia congelada sin redondear el equivalente para admitir excesos. Descontar comision no permite eludir el limite.
- En pares no USD de igual moneda no hay conversion ni comision, pero se requiere referencia vigente origen/USD para verificar el limite; USD/USD no requiere snapshot. El resumen vence 60 segundos despues de emitirse y reservar no reinicia el plazo.
- El JSON de pares bancarios compartido es solo ilustrativo; quedan pendientes contrato real, cobertura de las cuatro monedas y politica de cruces. No se presupone reciprocidad ni coherencia con GTQ.

| Caso ilustrativo | Debito | Tasa | Bruto destino | Comision | Neto acreditado |
| --- | --- | --- | --- | --- | --- |
| USD a COP | USD 10.00 | 4000 COP/USD | COP 40000.00 | 1% = COP 400.00 | COP 39600.00 |
| EUR a EUR | EUR 25.00 | No aplica conversion | EUR 25.00 | 0% = EUR 0.00 | EUR 25.00 |

Las tasas del ejemplo son ilustrativas; la fuente real es la API bancaria. No hay minimo de comision adicional: el techo entero implica que una comision positiva inferior a una unidad se cobra como 1.00 destino. Se rechaza neto <= 0 sin aumentar el debito origen.

Ejemplo normalizado ilustrativo: con 8.00 GTQ/EUR y 7.50 GTQ/USD, EUR 187.50 equivale a USD 200.00 y se admite; EUR 187.51 supera USD 200.00 y se rechaza. No es una comision ni obliga a convertir efectivamente a USD. No se fija limite acumulado diario o mensual.

## 8. Estados observables y excepciones

La referencia de estados es la seccion 4 de [SPEC-TRANSFER.md](SPEC-TRANSFER.md). Funcionalmente:

- CREADA: solicitud registrada; no significa dinero transferido.
- RESERVADA: fondos retenidos; el destinatario aun no recibe un credito definitivo.
- CONTABILIZADA: transferencia ejecutada, comprobante disponible y sin cancelacion por el cliente.
- RECHAZADA: no ejecutada por una validacion fallida; se informa el motivo pertinente sin exponer datos de terceros no autorizados.
- EXPIRADA: no ejecutada por vencimiento; la reserva se libera y otra cotizacion necesita consentimiento nuevo.
- CANCELADA: abandono permitido antes de confirmar con liberacion de la reserva; no se ofrece para una transferencia realizada ni se promete si ya se esta confirmando.
- REVERTIDA: extension administrativa propuesta, excluida del alcance funcional aprobado de esta fase.

Un timeout no prueba rechazo ni exito. Se debe poder recuperar el resultado de la misma operacion antes de intentar otro envio. No se emite comprobante de transferencia completada para un intento rechazado, reservado o expirado.

## 9. Escenarios de aceptacion

| ID | Dado / Cuando / Entonces | Cobertura |
| --- | --- | --- |
| CA-001 | Dado un cliente individual; cuando busca un numero de cuenta por la API bancaria; entonces si existe se muestra el nombre completo y despues se pide alias para guardar; si no existe se muestra error sin guardar, y si falla la API se informa indisponibilidad sin fingir cuenta inexistente. | HU-001, RF-001, RF-002 |
| CA-002 | Dado un alias no guardado, de otro cliente o ambiguo; cuando intenta elegirlo como destino; entonces no se inicia una transferencia a una cuenta arbitraria ni se afectan saldos. | HU-001, RF-003 |
| CA-003 | Dadas cuenta origen USD y destino COP previamente guardado; cuando indica USD 10.00 con tasa ilustrativa 4000; entonces ve debito USD 10.00, bruto COP 40000.00, comision COP 400.00 y neto COP 39600.00, sin requerir otra cuenta USD al destinatario. | HU-002, HU-003, RF-004, RF-006, RF-007 |
| CA-004 | Dadas dos cuentas EUR; cuando envia EUR 25.00; entonces ve y se ejecutan debito EUR 25.00, comision cero y credito EUR 25.00. | HU-003, RF-006, RF-010 |
| CA-005 | Dadas las cuatro monedas aprobadas; cuando se evaluan los 16 pares posibles; entonces cuatro pares de igual moneda no cobran comision y los doce pares distintos descuentan 1% del bruto en destino, con precision aprobada. | HU-002, RF-004, RF-006 |
| CA-006 | Dado un resumen vigente; cuando llega a la confirmacion; entonces ve titular y alias destino, importes, tasa aplicable, costo, neto y advertencia de no cancelacion, y nada se ejecuta sin su consentimiento explicito. | HU-003, RF-007, RF-008 |
| CA-007 | Dada una cotizacion congelada por 60 segundos; cuando confirma en t+59 y sigue vigente al decidir la ejecucion; entonces se respetan tasa y comision mostradas. En t+60 o despues, no se ejecuta y otra cotizacion necesita nueva confirmacion. | HU-003, RF-005, RF-008, RF-011 |
| CA-008 | Dado un resumen revisado; cuando cambia el importe o destinatario; entonces las condiciones anteriores no autorizan la nueva operacion y debe revisar y confirmar el nuevo resumen. | HU-003, RF-008 |
| CA-009 | Dado saldo disponible insuficiente o dos solicitudes que juntas lo exceden; cuando se intenta reservar; entonces no se permite sobregiro y solo se aceptan operaciones respaldadas por disponible. | HU-004, RF-009 |
| CA-010 | Dada una ejecucion; cuando ocurre un fallo en cualquiera de sus efectos monetarios o contables; entonces no queda debito, credito o comision parcial definitiva y las reservas se recuperan segun su vigencia. | HU-004, RF-010, RF-011 |
| CA-011 | Dada una doble confirmacion o respuesta perdida; cuando el cliente recupera o reintenta la misma operacion; entonces no se duplican debito, credito ni comision y se obtiene el resultado original. | HU-004, RF-012 |
| CA-012 | Dada una transferencia ejecutada; cuando el cliente intenta cancelarla; entonces se rechaza sin modificar fondos ni historial. | HU-003, RF-013 |
| CA-013 | Dada la operacion de CA-003 completada; cuando consulta su comprobante, aun despues de cambiar la tasa del dia; entonces ve el mismo numero unico y los importes originales USD 10.00, COP 400.00 de comision y COP 39600.00 netos, con el resto de datos RF-014, sin otro envio. | HU-005, RF-014 |
| CA-014 | Dada una conversion contabilizada; cuando se revisa su evidencia; entonces se identifica la transferencia y su comision y los movimientos suman cero por cada moneda, sin mezclar unidades. | HU-004, RF-015 |
| CA-015 | Dada una empresa, cuenta externa, moneda no permitida, importe invalido o ausencia de tasa del dia vigente; cuando intenta operar; entonces no se ejecuta y se informa el motivo. | HU-004, RF-001, RF-004, RF-016 |
| CA-016 | Dada referencia vigente; cuando solicita USD 200.00 origen o su equivalente exacto; entonces puede continuar si cumple las demas reglas; cualquier exceso se rechaza antes de reservar, aun entre monedas iguales. | HU-004, RF-017 |
| CA-017 | Dada referencia normalizada ilustrativa 8.00 GTQ/EUR y 7.50 GTQ/USD; cuando indica EUR 187.50 o EUR 187.51; entonces el primero cumple el limite y el segundo se rechaza sin redondear para admitirlo. | HU-004, RF-005, RF-017 |
| CA-018 | Dada una solicitud no confirmada con fondos reservados; cuando sale y repite el abandono; entonces se libera una sola vez sin ejecutar ni generar diario. Si ya se confirmo o esta en curso, se recupera el resultado sin prometer cancelacion. | HU-004, RF-011, RF-012, RF-018 |
| CA-019 | Dadas comisiones antes del techo de 0.10, 0.101, 1.00 y 1.01; cuando se cuantizan; entonces se cobran 1.00, 1.00, 1.00 y 2.00 destino. Igual moneda no cobra; si la conversion deja neto <= 0 se rechaza sin movimientos. | HU-003, RF-006 |
| CA-020 | Dada una transferencia EUR/EUR sin datos vigentes para valorar EUR/USD; cuando intenta continuar; entonces se impide ejecutar aunque no haya conversion de destino ni comision, porque no puede verificarse el limite USD. | HU-004, RF-016, RF-017 |

## 10. No-objetivos

- Abrir cuentas adicionales para completar la transferencia, atender empresas o enviar a otros bancos/proveedores externos.
- Seleccionar un importe neto destino como modalidad de entrada; el cliente define el importe origen.
- Transferir a destinos no guardados previamente, usar UYU o aceptar QTZ como identificador de moneda.
- Cancelar o revertir por iniciativa del cliente una operacion ejecutada; definir correcciones administrativas sin aprobacion adicional.
- Transferencias programadas, lotes, credito, sobregiros y reversiones parciales.
- Construir gestion general de cuentas o destinatarios mas alla del alta y seleccion necesarias para este recorrido.
- Elegir infraestructura, mecanismos de atomicidad, implementacion contable, proveedor de tasas o diseno visual. Se mantienen los invariantes acordados, no una solucion tecnica obligatoria en este documento.
- Fijar objetivos de rendimiento, obligaciones regulatorias o politicas de retencion sin informacion de negocio.

## 11. Preguntas abiertas y validacion

| ID | Decision pendiente | Impacto |
| --- | --- | --- |
| PA-001 | Parcialmente resuelta: busqueda por numero de cuenta en API bancaria, nombre completo y despues alias; error si no se encuentra. Aprobada unicidad por cliente con trim y normalizacion case-insensitive; pendiente politica de edicion y contrato real del servicio. | El flujo y la unicidad estan confirmados; faltan formato/validaciones de cuenta y contrato tecnico. |
| PA-002 | Resuelta el 2026-11-03: las transferencias entre cuentas propias quedan deshabilitadas en fase 1. | Alcance de actores y pruebas. |
| PA-003 | Resuelta el 2026-11-03: bruto HALF_UP a dos decimales y comision sobre bruto cuantizado, con techo entero. | La formula aprobada se prueba en TEST-011, incluidos casos limite y neto no positivo. |
| PA-004 | Fuente resuelta: API bancaria. El JSON es ilustrativo; pendientes contrato real, unidades/precision, cobertura, cruces, zona horaria y vigencia. | No usar el ejemplo inconsistente como tasas reales ni inventar COP, inversas o metadatos. |
| PA-005 | Resueltos USD 200.00 por operacion sobre importe origen antes de comision, sin redondear para admitir excesos. Resumen/reserva de igual moneda por 60 segundos desde emision, sin reinicio al reservar. | No se fija limite acumulado diario o mensual. |
| PA-006 | Resuelta: se permite salir antes de confirmar, liberando la reserva; despues de ejecutar es irreversible en el flujo del producto. | Recuperar el resultado si salir compite con una confirmacion; no prometer cancelacion de algo ya ejecutado. |
| PA-007 | Resuelta consulta del comprobante dentro de la plataforma sin PDF ni envio externo. Pendientes privacidad y plazo de consulta/retencion. | Devolver datos originales con control de acceso. |
| PA-008 | Objetivo medible de agilizacion: tiempo esperado, volumen/concurrencia y linea base del proceso actual. | Criterios de rendimiento y medicion del beneficio. |
| PA-009 | Si existiran correcciones administrativas excepcionales y bajo que autorizaciones y tratamiento de comisiones. | Extension fuera de fase 1; nunca equivale a cancelacion del cliente. |

Las preguntas no convierten los requisitos confirmados en opcionales. La especificacion funcional puede revisarse con este borrador; para cerrar los escenarios afectados se deben resolver las preguntas correspondientes y validar los ejemplos monetarios. La fase tecnica posterior explicara como satisfacerlos y definira las pruebas ejecutables. En esta fase no se afirma que exista una implementacion ni que los escenarios ya hayan pasado.