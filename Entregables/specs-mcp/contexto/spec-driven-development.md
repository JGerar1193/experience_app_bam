<!-- Slide number: 1 -->
INGENIERÍA DE SOFTWARE • PARADIGMAS MODERNOS
Evolución hacia Spec-Driven Development (SDD)

Del diseño guiado por pruebas y por dominio a las especificaciones ejecutables con agentes de IA. Guía paso a paso con un caso práctico completo.
.specs/
├── CONSTITUTION.md
├── SPEC-012.md
├── PLAN-012.md
└── TASKS-012.md
src/    tests/

### Notes:
Presentación: cómo pasamos de TDD, BDD y DDD a Spec-Driven Development. La sesión combina teoría con un caso práctico completo (checkout idempotente) y termina con un taller.

<!-- Slide number: 2 -->
AGENDA
Ruta de la sesión

01
02
03
Fundamentos
TDD, BDD y DDD con ejemplos de código y de negocio.
El problema
Por qué los agentes de IA fallan: context drift.
Spec-Driven Development
Definición, niveles, fases, artefactos y cómo escribir una buena spec.

04
05
06
Caso práctico
Checkout idempotente de punta a punta: spec, plan, tareas, ejecución y cambios.
Adopción
Comparativa, herramientas, antipatrones y cuándo usar SDD.
Taller
Reto, pasos con tiempos y rúbrica de evaluación.

Objetivo: al final podrás redactar una SPEC, un PLAN y un TASKS que un agente de IA pueda ejecutar sin adivinar, y verificar su trabajo con pruebas.
2

### Notes:
Mostrar la ruta completa. El objetivo de aprendizaje es concreto: al final cada estudiante debe poder redactar SPEC, PLAN y TASKS que un agente pueda ejecutar sin adivinar.

<!-- Slide number: 3 -->
PANORÁMICA
El espectro de metodologías *-DD

TDD

BDD

DDD

SDD

![preencoded.png](Image0.jpg)

![preencoded.png](Image1.jpg)

![preencoded.png](Image2.jpg)

![preencoded.png](Image3.jpg)
Test-Driven Development
Behavior-Driven Development
Domain-Driven Design
Spec-Driven Development
Ciclo Red-Green-Refactor a nivel unitario.

Origen
Kent Beck, 2002

Artefacto central
Test unitario

Pregunta clave
¿Esta función hace lo esperado?
Comportamiento descrito en un lenguaje común.

Origen
Dan North, 2006

Artefacto central
Escenario Gherkin

Pregunta clave
¿Se comporta como espera el usuario?
Modelado centrado en la complejidad del negocio.

Origen
Eric Evans, 2003

Artefacto central
Modelo de dominio

Pregunta clave
¿El software refleja el negocio?
Especificación estructurada como fuente de verdad.

Origen
Popularizado en 2025 con agentes de IA

Artefacto central
Spec, plan y tareas (.md)

Pregunta clave
¿Construimos lo pactado?
De verificar funciones (TDD) a pactar el sistema completo antes de que un agente escriba código (SDD).
3

### Notes:
Cada metodología responde una pregunta distinta y nació en un contexto distinto. SDD no inventa todo desde cero: reutiliza las ideas de las otras tres y las adapta al trabajo con agentes de IA.

<!-- Slide number: 4 -->
01
BLOQUE 01
Fundamentos: TDD, BDD y DDD
Las tres ideas que SDD reutiliza: verificar, describir comportamiento y modelar el negocio.

<!-- Slide number: 5 -->
FUNDAMENTOS
Test-Driven Development (TDD): el ciclo
Diseño guiado por la verificación previa de cada unidad mínima de código. El test se escribe antes que el código y define qué significa "funciona".

Escribe un test para UN comportamiento
Ejecútalo y confirma que falla por la razón correcta (no por un error de sintaxis o de importación).

RED
Las tres leyes de TDD

1
No escribas código de producción salvo para hacer pasar un test que falla.

Escribe el código mínimo que lo haga pasar
Se vale una solución ingenua; el siguiente test forzará a generalizar.

GREEN

2
No escribas más test del necesario para que falle (que no compile también es fallar).

Mejora la estructura sin cambiar el comportamiento
Elimina duplicación y mejora nombres. Los tests siguen en verde tras cada cambio.

3
No escribas más código del necesario para pasar el test actual.

REFACTOR
↻  Repite en ciclos cortos de 2 a 10 minutos.
5

### Notes:
TDD es diseño guiado por verificación. Insistir en "falla por la razón correcta": un test que falla por un error de sintaxis no prueba nada. Las tres leyes evitan escribir código especulativo.

<!-- Slide number: 6 -->
FUNDAMENTOS • EJEMPLO
TDD paso a paso: un ciclo completo en código

1 · RED

2 · GREEN

3 · REFACTOR

// descuento.test.ts
test('10% con cupón VIP', () => {
  expect(aplicarDescuento(100, 'VIP'))
    .toBe(90);
});

$ npm test
[FAIL] aplicarDescuento
       is not defined
// descuento.ts
export function aplicarDescuento(
  total: number, cupon?: string) {
  if (cupon === 'VIP')
    return total * 0.9;
  return total;
}

$ npm test
[PASS] 1 passed
// descuento.ts
const CUPONES: Record<string, number>
  = { VIP: 0.10 };

export function aplicarDescuento(
  total: number, cupon?: string) {
  const pct = CUPONES[cupon ?? ''] ?? 0;
  return total * (1 - pct);
}
[PASS] 1 passed
El test falla porque la función no existe: es la razón correcta.
Código mínimo. No anticipa cupones que ningún test pide.
Misma conducta, mejor estructura. El test sigue en verde.

Siguiente ciclo: escribe el test para un cupón inválido (aplicarDescuento(100, 'XYZ') → 100) y repite RED → GREEN → REFACTOR.
6

### Notes:
Recorrer las tres columnas en orden. En GREEN el código es deliberadamente simple. En REFACTOR el comportamiento no cambia: por eso no se agregan cupones nuevos sin un test que los pida primero.

<!-- Slide number: 7 -->
ALINEACIÓN DE NEGOCIO
Behavior-Driven Development (BDD): escenarios ejecutables

Cómo se trabaja, paso a paso
# language: es
Característica: Pago con tarjeta
  Como comprador
  Quiero pagar mi carrito con tarjeta
  Para recibir mi pedido

  Escenario: Pago aprobado
    Dado un carrito con total de 120.000 COP
    Y una tarjeta con fondos suficientes
    Cuando confirmo el pago
    Entonces veo "Pago aprobado"
    Y el pedido queda en estado PAGADO

  Escenario: Fondos insuficientes
    Dado una tarjeta sin fondos
    Cuando confirmo el pago
    Entonces veo "Pago rechazado"
    Y no se crea ningún pedido
Conversación de "los tres amigos". Negocio, desarrollo y QA discuten ejemplos concretos de la historia.

1
Escribir los escenarios. Dado (estado inicial), Cuando (acción), Entonces (resultado observable), en el lenguaje del negocio.

2
Automatizar. Cada paso se enlaza a código (step definitions) con Cucumber, Behave o Reqnroll.

3
Ejecutar. El escenario falla hasta que la funcionalidad existe; luego queda como documentación viva.

4

Tip: un escenario = un comportamiento. Evita pasos de interfaz como "hago clic en #btn-pagar".
7

### Notes:
Gherkin admite palabras clave en español con "# language: es". Cada línea Dado/Cuando/Entonces se conecta con código mediante step definitions. Insistir en describir comportamiento, no clics en la interfaz.

<!-- Slide number: 8 -->
ALINEACIÓN DE NEGOCIO
Domain-Driven Design (DDD): los bloques de construcción

Lenguaje ubicuo
Los mismos términos en conversaciones, código y documentación.
Bounded Context
Límite explícito dentro del cual un término tiene un único significado.
Entidad
Objeto con identidad propia que persiste en el tiempo.

Ej.: "Transferencia", no "TxnDTO".

Ej.: "Cuenta" en Billeteras ≠ "Cuenta" en Contabilidad.

Ej.: Billetera W-123, aunque cambie su saldo.

Value Object
Definido solo por sus atributos; inmutable y comparable por valor.
Agregado
Grupo de objetos con una raíz que protege las invariantes.
Evento de dominio
Algo relevante para el negocio que ya ocurrió.

Ej.: Dinero(50000, "COP").

Ej.: Billetera garantiza saldo ≥ 0.

Ej.: TransferenciaCompletada.
8

### Notes:
Todos los ejemplos usan el dominio de pagos y billeteras, el mismo del taller final. Resaltar que las invariantes de los agregados son justo lo que después se escribe en la spec y en la constitución.

<!-- Slide number: 9 -->
ALINEACIÓN DE NEGOCIO
DDD en práctica: del negocio al mapa de contextos

Cómo llegar ahí, paso a paso

Pagos
cobra y autoriza

Billeteras
saldo ≥ 0
1.  Event Storming: lista los eventos del negocio en pasado (PagoAprobado, SaldoDebitado…).
2.  Agrupa eventos y comandos relacionados: cada grupo es un candidato a contexto.
3.  Define el glosario de cada contexto y resuelve palabras con dos significados.
4.  Identifica agregados y escribe sus invariantes ("saldo nunca negativo").
5.  Decide cómo se comunican: eventos, API o capa anticorrupción.
PagoAprobado

PagoRechazado
SaldoDebitado

Notificaciones
email / push

Contabilidad
partida doble

Conexión con SDD: el glosario y las invariantes pasan directo a la spec y a la constitución.
Cada caja es un bounded context con su propio glosario; las flechas son eventos de dominio.
9

### Notes:
El mapa muestra contextos que se comunican por eventos. El paso a paso de la derecha es lo mínimo para que el glosario y las invariantes estén listos antes de escribir la spec.

<!-- Slide number: 10 -->
02
BLOQUE 02
El problema: código asistido por IA
Los agentes escriben sintaxis correcta, pero pierden el contexto del sistema.

<!-- Slide number: 11 -->
PUNTO DE INFLEXIÓN
Context Drift: por qué fallan los agentes de IA

Olvida decisiones

Inventa APIs
Context Drift

![preencoded.png](Image0.jpg)

![preencoded.png](Image1.jpg)
En la tercera sesión vuelve a usar la librería que descartaste en la primera.
Llama funciones, endpoints o campos que no existen en tu código.
Degradación progresiva de la coherencia cuando el agente trabaja con un contexto incompleto, efímero o contradictorio.

Desborda el alcance

Falsos "listo"

![preencoded.png](Image2.jpg)

![preencoded.png](Image3.jpg)
No falla por falta de sintaxis: falla porque no sabe (o ya olvidó) qué se decidió.
Refactoriza archivos que no pediste y rompe otra funcionalidad.
Declara la tarea terminada sin ninguna prueba que lo demuestre.

Causas: ventana de contexto limitada  •  prompts efímeros que no quedan en el repo  •  requisitos implícitos en la cabeza del desarrollador  •  ningún criterio objetivo de "terminado"
11

### Notes:
El fallo típico de un agente no es de sintaxis sino de contexto. Pedir a la clase ejemplos propios de cada síntoma. Las causas de abajo son justamente lo que SDD ataca.

<!-- Slide number: 12 -->
PUNTO DE INFLEXIÓN
Prompt efímero vs. especificación versionada
Vibe coding (prompt efímero)
Spec-Driven Development

1.  "Hazme un checkout con pagos"

1.  SPEC revisada y aprobada por negocio

2.  El agente genera código plausible

2.  PLAN con contratos y decisiones técnicas

3.  Aparece un bug en producción

3.  TASKS atómicas, cada una con su test

4.  Nuevo prompt con un parche puntual

4.  El agente implementa UNA tarea

5.  El contexto original ya se perdió

5.  Los tests deciden si está terminada

6.  Deuda: nadie sabe qué reglas debía cumplir

6.  Spec y código se fusionan en el mismo PR

El conocimiento vive en el chat → se pierde

El conocimiento vive en el repo → se versiona
12

### Notes:
Comparar los dos flujos con el mismo pedido. En el primero, cada parche se apoya en un contexto que se va perdiendo. En el segundo, el conocimiento vive en el repositorio y se revisa como el código.

<!-- Slide number: 13 -->
03
BLOQUE 03
Spec-Driven Development
Qué es, qué no es, sus fases, sus artefactos y cómo escribir una buena especificación.

<!-- Slide number: 14 -->
DEFINICIÓN CENTRAL
¿Qué es Spec-Driven Development?
Metodología donde los requerimientos, los contratos técnicos y el plan de ejecución se redactan y revisan antes de generar código. Humanos y agentes de IA implementan a partir de esos documentos.

Artefactos versionados
Archivos Markdown en el repositorio, revisados en PR como el código.

Trazabilidad bidireccional
Cada función se puede rastrear hasta una regla (R1, R2…) y cada regla hasta su test.

"La especificación versionada es la única fuente de verdad: ni el historial de chat, ni la memoria del agente."

Generación predecible
La misma spec y el mismo plan producen implementaciones equivalentes, aunque cambie el agente o la sesión.
Lo que SDD NO es

No es documentación tardía
Se escribe antes del código y gobierna la implementación.
No es cascada
Specs pequeñas por feature, en ciclos de días, no un documento de meses.
No es exclusivo de IA
Una buena spec también evita malentendidos entre personas.
14

### Notes:
La frase clave es la cita: la fuente de verdad es el archivo versionado, no el chat. Dedicar tiempo a la fila de abajo: es la objeción más común (que SDD es cascada o documentación).

<!-- Slide number: 15 -->
DEFINICIÓN CENTRAL
Tres niveles de adopción de SDD

Spec-first
Spec-anchored
Spec-as-source
La spec se escribe y revisa antes de codificar la feature.

Después de entregar, puede quedar desactualizada.
La spec se conserva y evoluciona junto con el código.

Todo cambio pasa primero por la spec y luego por el código.
La spec es el artefacto principal que edita el humano.

El código se regenera desde ella; casi no se edita a mano.

Buen punto de partida

Recomendado para equipos

Experimental
En este curso trabajamos en modo spec-anchored: la spec vive en .specs/ y cambia en el mismo PR que el código.
15

### Notes:
Clasificación propuesta en martinfowler.com (Birgitta Böckeler, 2025). La mayoría de equipos debería apuntar a spec-anchored: la spec se mantiene viva sin depender de regenerar todo el código.

<!-- Slide number: 16 -->
METODOLOGÍA PRÁCTICA
El flujo completo de SDD, fase por fase

FASE 0
FASE 1
FASE 2
FASE 3
FASE 4
FASE 5
FASE 6
Constitution
Specify
Clarify
Plan
Tasks
Analyze
Implement
Reglas globales del proyecto. Se hace una vez.
Qué y por qué, sin tecnología.
Resolver ambigüedades antes de diseñar.
Arquitectura, stack y contratos.
Unidades pequeñas, cada una con su test.
Verificar coherencia spec ↔ plan ↔ tareas.
El agente ejecuta tarea por tarea con tests.

✋ Revisión

✋ Revisión

✋ Revisión

✋ Revisión
tras Clarify
tras Plan
tras Tasks
en cada PR

Regla: ninguna fase empieza hasta que una persona aprueba el artefacto de la anterior. El agente propone; el humano decide.
Fase núcleo: produce un artefacto que gobierna la siguiente.

Fase de soporte: mejora la calidad, no es opcional en sistemas críticos.

16

### Notes:
Las cuatro fases núcleo son Specify, Plan, Tasks e Implement. Constitution se hace una vez por proyecto; Clarify y Analyze son controles de calidad. Las compuertas de revisión humana son obligatorias: sin ellas, el agente encadena errores.

<!-- Slide number: 17 -->
METODOLOGÍA PRÁCTICA
Qué entra, qué sale y quién aprueba en cada fase
| Fase | Entrada | Salida (artefacto) | Aprueba | Pregunta de control |
| --- | --- | --- | --- | --- |
| Constitution | Estándares del equipo, restricciones técnicas | CONSTITUTION.md | Líder técnico | ¿Qué nunca se puede violar? |
| Specify | Necesidad de negocio, historias de usuario | SPEC-XXX.md | Negocio + desarrollo | ¿Está claro el qué y el por qué, sin el cómo? |
| Clarify | Spec en borrador | Spec sin dudas abiertas | Dueño del producto | ¿Queda algo abierto a interpretación? |
| Plan | Spec aprobada + constitución | PLAN-XXX.md y contratos | Arquitecto / dev senior | ¿Cómo se construye, con qué y con qué límites? |
| Tasks | Plan aprobado | TASKS-XXX.md | Desarrollador | ¿Cada tarea cabe en un PR pequeño y tiene test? |
| Analyze | Spec + plan + tareas | Reporte de inconsistencias | Desarrollador | ¿Toda regla tiene tarea y test? |
| Implement | Una tarea + todos los artefactos | Código y tests en verde | Revisor del PR | ¿Los tests prueban lo que dice la spec? |
17

### Notes:
Usar la última columna como checklist en cada compuerta de revisión. Si no puedes responder la pregunta de control con un "sí" claro, la fase no está terminada.

<!-- Slide number: 18 -->
ARTEFACTOS
Estructura de un proyecto SDD

Constitución del sistema
Invariantes que ningún agente ni desarrollador puede violar. Una por proyecto.
mi-proyecto/
├── .specs/
│   ├── CONSTITUTION.md     # Reglas globales
│   ├── SPEC-012.md         # Qué y por qué
│   ├── PLAN-012.md         # Cómo: arquitectura
│   ├── TASKS-012.md        # Checklist ejecutable
│   ├── contracts/
│   │   └── charges.openapi.yaml
│   └── adr/
│       └── 0007-redis-idempotencia.md
├── src/                    # Código implementado
├── tests/                  # Verificación
└── CLAUDE.md               # Instrucciones al agente

Spec, plan y tareas
Tres archivos por feature: el qué, el cómo y el paso a paso.

Contratos como archivos
OpenAPI o JSON Schema: tipos y límites sin ambigüedad, validables por máquina.

ADR (Architecture Decision Record)
Por qué se tomó una decisión y qué alternativas se descartaron.

Convención: un número por feature (012) compartido por SPEC, PLAN y TASKS. Así cualquier persona o agente encuentra todo lo relacionado.
Instrucciones al agente
CLAUDE.md o AGENTS.md: "lee .specs/ antes de actuar" y cómo correr los tests.
18

### Notes:
Convención: un número por feature compartido por SPEC, PLAN y TASKS. El archivo de instrucciones del agente (CLAUDE.md, AGENTS.md o reglas de Cursor) es lo que obliga al agente a leer .specs/ antes de tocar código.

<!-- Slide number: 19 -->
ARTEFACTOS
La constitución: reglas que nada puede violar

Cómo redactarla, paso a paso
# CONSTITUTION.md

## Stack permitido
- Node 20 + TypeScript (strict: true)
- Express 4, Redis 7 con ioredis
- Prohibido: nuevos ORMs o librerías sin mantenimiento

## Principios no negociables
1. Test primero: ninguna tarea sin un test que falle antes.
2. Ningún secreto en el código: solo variables de entorno.
3. Todo endpoint valida su entrada con zod.
4. Dinero en enteros (centavos), nunca float.

## Definición de terminado
- npm test en verde
- Cobertura >= 80 % en los archivos tocados
- Spec y código en el mismo PR
1.  Lista lo que ya revisas en cada code review del equipo.
2.  Conviértelo en reglas verificables. "Código limpio" no sirve; "dinero en centavos" sí.
3.  Sepáralo en tres bloques: stack, principios y definición de terminado.
4.  Mantenla corta (1–2 páginas): el agente la lee en cada tarea.
5.  Protégela: cambiarla requiere PR y aprobación del equipo.
19

### Notes:
La constitución convierte lo que se revisa en code review en reglas escritas y verificables. Debe ser corta porque el agente la lee en cada tarea. Cambiarla es un cambio de proyecto: requiere PR y aprobación.

<!-- Slide number: 20 -->
CÓMO ESCRIBIR LA SPEC
Anatomía de una buena especificación

## 1
Contexto y objetivo  ¿Qué problema resolvemos y por qué ahora?

Checklist de calidad

## 2
Actores e historias  Como <rol> quiero <acción> para <beneficio>.
☐  No menciona frameworks, bases de datos ni librerías (eso va en el plan).
☐  Cada regla tiene un ID (R1, R2…) para trazarla.
☐  Cada regla tiene al menos un criterio de aceptación.
☐  No usa adjetivos vagos: "rápido", "seguro", "amigable".
☐  Los no-objetivos están escritos.
☐  Una persona de negocio puede leerla y aprobarla.

## 3
Reglas de negocio  R1…Rn: numeradas, atómicas y verificables.

## 4
Criterios de aceptación  Dado / Cuando / Entonces por cada regla.

## 5
Casos borde y errores  Qué pasa cuando algo falla o llega al límite.

## 6
No-objetivos  Lo que explícitamente NO entra en esta feature.

## 7
Preguntas abiertas  [NEEDS CLARIFICATION: …] hasta resolverlas.
20

### Notes:
Plantilla de siete secciones. Las dos más olvidadas son no-objetivos y preguntas abiertas. El checklist de la derecha sirve para revisar la spec antes de aprobarla.

<!-- Slide number: 21 -->
CÓMO ESCRIBIR LA SPEC
Requisitos verificables: de vagos a precisos

✗  Vago

✓  Verificable
Patrones EARS

El sistema debe ser rápido.

POST /charges responde en p95 < 300 ms con 100 solicitudes por segundo.

Ubicuo
El sistema DEBE <respuesta>.

Evento
CUANDO <disparador>, el sistema DEBE <respuesta>.

Manejar los errores de red.

Si el cliente reintenta con la misma Idempotency-Key dentro de 24 h, el sistema DEBE devolver la respuesta original sin cobrar de nuevo.

Estado
MIENTRAS <estado>, el sistema DEBE <respuesta>.

No deseado
SI <condición>, ENTONCES el sistema DEBE <respuesta>.

Validar el monto.

Si el monto es ≤ 0, el sistema DEBE responder 400 con el código AMOUNT_INVALID.

Opcional
DONDE <característica activa>, el sistema DEBE <respuesta>.

Prueba de fuego: si no puedes escribir el test a partir de la frase, el requisito todavía no está listo. Usa EARS o Gherkin, pero cada requisito debe poder convertirse en una aserción.
21

### Notes:
Un requisito vago obliga al agente a adivinar, y adivinará distinto en cada sesión. EARS es una notación de requisitos usada por herramientas como Kiro; Gherkin es la alternativa de BDD. Ambas sirven: lo importante es que se puedan convertir en un test.

<!-- Slide number: 22 -->
04
BLOQUE 04
Caso práctico: checkout idempotente
Recorremos todas las fases con un problema real: evitar cobros duplicados.

<!-- Slide number: 23 -->
CASO PRÁCTICO • CONTEXTO
El problema: un reintento que cobra dos veces

App del cliente

Nuestra API

Pasarela de pago

Resultado
El cliente pagó 100.000 COP por una compra de 50.000. Reclamo, reembolso y pérdida de confianza.

1. POST /charges

50.000 COP
2. Cobrar

3. Cobro OK

4. Respuesta perdida (timeout)

5. Reintento → ¡segundo cobro!

Idea de solución: el cliente genera un identificador único (Idempotency-Key) por cada intento lógico de pago y lo reenvía en todos sus reintentos. El servidor recuerda la respuesta asociada a esa clave y la devuelve sin volver a cobrar.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
23

### Notes:
Antes de escribir la spec hay que entender el problema. Narrar la secuencia: el cobro sí ocurrió, pero la respuesta se perdió; el cliente reintenta de buena fe y se cobra dos veces. La solución estándar (usada por pasarelas como Stripe) es la clave de idempotencia.

<!-- Slide number: 24 -->
CASO PRÁCTICO PASO 1 • SPECIFY
Paso 1: redactar la spec funcional (.specs/SPEC-012.md)

Cero tecnología en esta fase
Redis, TypeScript o Express se deciden en el plan. La spec dice qué, no cómo.
# Feature: Checkout idempotente (SPEC-012)

## Contexto y objetivo
Evitar cobros duplicados cuando el cliente reintenta
un pago por fallas de red o timeouts.

## Historia
Como comprador quiero que reintentar un pago no me
cobre dos veces, para poder confiar en la tienda.

## Reglas de negocio
R1. Todo POST /charges DEBE incluir Idempotency-Key.
R2. Clave repetida en 24 h con el mismo cuerpo:
    devolver la misma respuesta sin cobrar de nuevo.
R3. Si el primer intento sigue en proceso: 409.
R4. Misma clave con un cuerpo distinto: 422.
R5. Las claves expiran a las 24 h.

Reglas numeradas
R1–R5 permiten trazar cada tarea y cada test hasta una regla concreta.

Cómo producirla
Escribe el borrador tú o pídeselo al agente con la necesidad de negocio.
Revísala con negocio usando el checklist de calidad.
Marca toda duda con [NEEDS CLARIFICATION].
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
24

### Notes:
Nota de corrección respecto a la versión anterior: "TTL en Redis" era un detalle técnico dentro de la spec. Ahora la regla R5 solo dice que las claves expiran a las 24 h; Redis aparece en el plan. También se agregó R4 (misma clave con distinto cuerpo), un caso borde que el agente no inventaría solo.

<!-- Slide number: 25 -->
CASO PRÁCTICO PASO 1 • CLARIFY
Paso 1b: criterios de aceptación y aclaraciones

Preguntas resueltas en Clarify
Escenario: Reintento tras timeout (R2)
  Dado un cobro completado con la clave K1
  Cuando llega otro POST con K1 y el mismo cuerpo
  Entonces la respuesta es idéntica a la original
  Y la pasarela NO recibe un segundo cobro

Escenario: Doble clic simultáneo (R3)
  Dado un cobro con la clave K2 aún en proceso
  Cuando llega otro POST con K2
  Entonces responde 409 Conflict

Escenario: Clave reutilizada con otro monto (R4)
  Dado un cobro completado con K3 por 50.000 COP
  Cuando llega K3 con un monto de 80.000 COP
  Entonces responde 422 y no se cobra

¿La clave es global o por comercio?
→ Por comercio: dos tiendas pueden usar la misma clave.

¿Si el primer intento falla con error 5xx?
→ Se libera la clave y el reintento se procesa normalmente.

¿Si falta el header?
→ 400 MISSING_IDEMPOTENCY_KEY, sin cobrar.

No-objetivos de SPEC-012
Reembolsos, cobros recurrentes e idempotencia en otros endpoints. Quedan para specs futuras.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
25

### Notes:
Cada escenario referencia la regla que prueba. La tabla de la derecha muestra preguntas que surgen al revisar la spec: si no se resuelven aquí, el agente las resolverá a su manera durante la implementación.

<!-- Slide number: 26 -->
CASO PRÁCTICO PASO 2 • PLAN
Paso 2: diseñar el flujo técnico (.specs/PLAN-012.md)

POST /charges

¿Trae Idempotency-Key?

SET clave NX = PROCESSING
(TTL 24 h)

Procesar cobro en la pasarela

Guardar COMPLETED + respuesta

sí

no
ya existe
error 5xx

400 MISSING_KEY (R1)

Leer registro existente

Borrar la clave y responder 5xx

PROCESSING
→ 409 (R3)

COMPLETED, mismo hash
→ respuesta guardada (R2)

Hash distinto
→ 422 (R4)

Hash: SHA-256 del cuerpo de la solicitud; permite detectar R4 sin guardar datos sensibles completos.
R5: el TTL de 24 h lo aplica Redis al crear la clave, sin procesos de limpieza.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
26

### Notes:
Ahora sí aparece la tecnología. El diagrama es parte del plan: cada caja indica qué regla cubre. SET NX de Redis es atómico, por eso resuelve la concurrencia (R3): solo una solicitud puede crear la clave.

<!-- Slide number: 27 -->
CASO PRÁCTICO PASO 2 • PLAN
Paso 2b: contratos, errores y decisiones técnicas

Almacenamiento: Redis con SET NX + TTL
Atómico y expira solo. Descartado: tabla SQL con proceso de limpieza (más lento y con más piezas).
## Clave en Redis
idempotency:{tenantId}:{key}    TTL 86400 s (R5)

## Registro
interface IdempotencyRecord {
  status: 'PROCESSING' | 'COMPLETED';
  requestHash: string;    // SHA-256 del body (R4)
  statusCode?: number;
  responseBody?: unknown;
  createdAt: number;      // epoch en ms
}

## Errores
400 MISSING_IDEMPOTENCY_KEY          (R1)
409 REQUEST_IN_PROGRESS              (R3)
422 KEY_REUSED_WITH_DIFFERENT_BODY   (R4)

Ubicación
Middleware Express en src/middleware/idempotency.ts, aplicado solo a POST /charges.

Dependencias
ioredis (permitida por la constitución). Prohibido agregar otra caché.

Estrategia de pruebas
Integración con Redis real en contenedor; un test por cada regla R1–R5 más uno de concurrencia.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
27

### Notes:
El contrato es inmutable durante la implementación: si el agente necesita cambiarlo, se detiene y se actualiza el plan primero. Las decisiones con alternativas descartadas se registran como ADR para que nadie (humano o agente) las reabra sin motivo.

<!-- Slide number: 28 -->
CASO PRÁCTICO PASO 3 • TASKS
Paso 3: desglosar en tareas atómicas (.specs/TASKS-012.md)

T1
cubre R1–R5

T2
cubre R1, R2, R5

T3
cubre R3, R4

T4
cubre aclaraciones

Tests de aceptación
Middleware base
Concurrencia y conflictos
Fallos y limpieza
tests/idempotency.test.ts
src/middleware/idempotency.ts
src/middleware/idempotency.ts
src/middleware/idempotency.ts
☐ Sin header → 400
☐ Clave nueva → 201 y un cobro
☐ Clave repetida → misma respuesta
☐ En proceso → 409
☐ Cuerpo distinto → 422
☐ Validar el header
☐ SET NX con TTL de 24 h
☐ Guardar respuesta COMPLETED
☐ 409 si está PROCESSING
☐ Hash del cuerpo y 422
☐ Test con 2 solicitudes en paralelo
☐ Borrar clave ante error 5xx
☐ Log con la clave (sin datos de tarjeta)
☐ Actualizar SPEC si surge otra regla

Depende de: —
Terminada si: Los 5 tests fallan por la razón correcta.
Depende de: T1
Terminada si: Tests de R1, R2 y R5 en verde.
Depende de: T2
Terminada si: Tests de R3 y R4 en verde.
Depende de: T3
Terminada si: Suite completa en verde.

Trazabilidad: R1 → T1, T2   •   R2 → T1, T2   •   R3 → T1, T3   •   R4 → T1, T3   •   R5 → T1, T2.   Regla de oro: una tarea = un prompt = un PR pequeño.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
28

### Notes:
Cuatro tareas, cada una con reglas que cubre, archivos permitidos, dependencias y definición de terminado. T1 siempre son los tests: así el agente no puede declarar algo terminado sin evidencia. La matriz de abajo es la trazabilidad.

<!-- Slide number: 29 -->
CASO PRÁCTICO PASO 4 • IMPLEMENT
Paso 4: ejecución asistida, una tarea a la vez

Reglas para cada prompt
$ claude          # o Cursor / Copilot en modo agente

> Lee .specs/CONSTITUTION.md, SPEC-012.md, PLAN-012.md
> y TASKS-012.md. Ejecuta ÚNICAMENTE T1.
> Escribe los tests; NO toques src/.
> Al terminar corre npm test y muéstrame la salida.

[FAIL] 5 failing         <- esperado: no hay código

> Ejecuta T2. Solo puedes modificar
> src/middleware/idempotency.ts. No edites los tests.

[PASS] 3 passing   [FAIL] 2 failing (R3, R4)

> Ejecuta T3 y luego T4. Marca [x] en TASKS-012.md.

[PASS] 6 passing (5 reglas + concurrencia)
1.  Referencia archivos, no pegues su contenido: la fuente de verdad sigue en el repo.
2.  Una tarea por prompt: limita el alcance y el tamaño del diff.
3.  Prohíbe explícitamente lo que no debe tocar (tests, otros módulos).
4.  Pide evidencia: la salida del test runner, no un "ya quedó".
5.  Abre una sesión nueva si el contexto se ensucia: la spec lo reconstruye.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
29

### Notes:
Mostrar la secuencia real: primero los tests fallan (esperado), luego pasan por partes. Cada prompt referencia archivos en vez de pegar texto, limita qué se puede tocar y pide evidencia (la salida del test runner).

<!-- Slide number: 30 -->
CASO PRÁCTICO PASO 4 • IMPLEMENT
Paso 4b: el bucle de verificación

El agente implementa la tarea

Correr la suite de tests

¿Todo en verde?

Revisión humana del diff

Marcar [x] y hacer commit
sí

no

Devolver al agente la salida exacta del test

¿Dónde está el error?
en el código

en la spec o el plan

Prohibido: editar el test para que pase. Si el test está mal, el error está en la spec o en el plan.

Actualizar SPEC / PLAN primero

Regenerar las tareas afectadas y volver al inicio

Criterio de parada objetivo: la tarea termina solo cuando el test runner aprueba. Si hay 3 intentos fallidos seguidos, detente: casi siempre falta algo en el plan.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
30

### Notes:
La pregunta clave cuando un test falla: ¿el error está en el código o en la spec? Si es la spec o el plan, se corrigen primero y luego se regeneran las tareas afectadas. Nunca se edita el test para que pase.

<!-- Slide number: 31 -->
CASO PRÁCTICO PASO 4 • IMPLEMENT
Paso 4c: revisión humana y registro en Git

Mensaje del commit / PR
Checklist del revisor

feat(checkout): pagos idempotentes (SPEC-012)

Implementa R1–R5 de .specs/SPEC-012.md
Tareas: T1, T2, T3, T4 (TASKS-012.md)

Archivos:
  .specs/SPEC-012.md      (aclaración R4)
  .specs/PLAN-012.md
  .specs/TASKS-012.md     (todas [x])
  src/middleware/idempotency.ts
  tests/idempotency.test.ts
☐  Cada cambio en src/ corresponde a una tarea de TASKS-012.
☐  Ningún archivo fuera del alcance fue modificado.
☐  Los tests verifican reglas (R1–R5), no detalles internos.
☐  Los tests no se editaron para hacerlos pasar.
☐  Se respeta la constitución (dinero en centavos, sin secretos).
☐  SPEC y PLAN se actualizaron si se descubrió algo nuevo.
☐  Todas las tareas están marcadas [x].

Por qué juntos: quien lea el historial de Git ve qué se pidió, cómo se diseñó y qué se construyó en un solo lugar.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
31

### Notes:
El revisor no lee solo el código: verifica que el código corresponda a las tareas y que los tests prueben reglas, no detalles internos. Spec, plan, tareas y código van en el mismo PR.

<!-- Slide number: 32 -->
CASO PRÁCTICO • EVOLUCIÓN
¿Y cuando cambia el requisito?

Nuevo pedido de negocio: "Para pagos por transferencia bancaria, la clave debe durar 48 horas en lugar de 24."

1

2

3

4

5
Editar la SPEC
R5 se divide en R5a (tarjeta: 24 h) y R5b (transferencia: 48 h).
Actualizar el PLAN
TTL configurable según el método de pago.
Agregar tareas delta
T5: test para 48 h. T6: implementación.
Implementar
Mismo bucle: tests primero, luego código.
Un solo PR
Spec, plan, tareas y código juntos.

✗  Atajo que rompe SDD
Pedirle al agente "cambia el TTL a 48 h" directamente en el código. La spec queda desactualizada y el próximo agente seguirá la regla vieja.
✓  Flujo correcto
La spec cambia primero; el código la sigue. La especificación nunca miente sobre lo que hace el sistema.
CASO:

Spec

Clarify

Plan

Tasks

Implement

Evolución
32

### Notes:
Ejemplo de cambio: negocio pide 48 horas para pagos por transferencia bancaria. Es el mismo ciclo en pequeño. El error más común es pedirle al agente el cambio directo en el código: la spec queda mintiendo y el siguiente agente la seguirá.

<!-- Slide number: 33 -->
05
BLOQUE 05
Comparativa y adopción
Cómo encaja SDD con TDD, BDD y DDD, qué herramientas existen y qué errores evitar.

<!-- Slide number: 34 -->
COMPARATIVA DIRECTA
Matriz de paradigmas
| Paradigma | Artefacto central | Lector primario | Pregunta clave | Cuándo se escribe | Herramientas típicas |
| --- | --- | --- | --- | --- | --- |
| TDD | Test unitario automatizado | Desarrollador / test runner | ¿Esta función hace lo esperado? | Antes de cada unidad de código | Jest, Vitest, JUnit, pytest |
| BDD | Escenario en Gherkin | Equipo multifuncional | ¿Se comporta como espera el usuario? | Antes de cada historia | Cucumber, Behave, Reqnroll |
| DDD | Modelo de dominio | Arquitectos e ingenieros | ¿El software refleja el negocio? | Al diseñar los contextos | Event Storming, Context Mapper |
| SDD | Spec, plan y tareas (.md) | Agente de IA y humanos | ¿Construimos el sistema pactado? | Antes de cada feature | Spec Kit, Kiro, Claude Code |
Las cuatro no compiten: responden preguntas distintas en momentos distintos del desarrollo.
34

### Notes:
Leer la tabla por columnas: el momento en que se escribe el artefacto y su lector principal son las diferencias más importantes. En SDD el lector principal es también un agente de IA.

<!-- Slide number: 35 -->
CONVERGENCIA
SDD no reemplaza: conecta y potencia

DDD
BDD
SDD
TDD
Código
Invariante del dominio
Escenario
Regla + tarea
Test unitario
Implementación
"El saldo de una billetera nunca es negativo."
Dado saldo 10.000 · Cuando transfiero 20.000 · Entonces se rechaza.
R3 en SPEC-TRANSFER y T2 en TASKS-TRANSFER.
expect(() =>
  debitar(10000, 20000)
).toThrow(
  SaldoInsuficiente)
El agente escribe solo lo necesario para pasar el test.

1. Semántica (BDD / DDD)

2. Contexto (SDD)

3. Verificación (TDD)

![preencoded.png](Image0.jpg)

![preencoded.png](Image1.jpg)

![preencoded.png](Image2.jpg)
Aporta el vocabulario, las invariantes y los criterios de aceptación de la spec.
Provee al agente límites estructurados, contratos y tareas pequeñas.
Evita falsos positivos: el agente no puede cerrar tareas rotas.
35

### Notes:
Seguir una sola regla de negocio a través de las cuatro metodologías: nace como invariante del dominio (DDD), se vuelve escenario (BDD), queda numerada en la spec con su tarea (SDD) y termina como test unitario (TDD).

<!-- Slide number: 36 -->
ECOSISTEMA
Herramientas para practicar SDD

GitHub Spec Kit
Kiro (AWS)
Sin framework
CLI open source (specify-cli) que funciona con Claude Code, Copilot, Cursor, Gemini y otros agentes.
IDE con agente que trabaja con specs por feature, en tres archivos encadenados.
Carpeta .specs/ con tus plantillas y un archivo de instrucciones que obligue al agente a leerlas.

/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.tasks
/speckit.analyze
/speckit.implement
requirements.md
  (notación EARS)
design.md
  (arquitectura)
tasks.md
  (plan de tareas)
CLAUDE.md / AGENTS.md:
"Antes de cualquier tarea
 lee .specs/CONSTITUTION.md
 y la SPEC, PLAN y TASKS
 de la feature."
Constitución en .specify/memory/
Flujo integrado en el editor
Lo importante es el proceso
36

### Notes:
Las herramientas cambian rápido; verificar la documentación oficial antes de la clase. Spec Kit es open source y funciona con varios agentes. Kiro tiene el flujo integrado en el IDE. La tercera columna muestra que no hace falta un framework: basta una carpeta y disciplina.

<!-- Slide number: 37 -->
ERRORES COMUNES
Antipatrones de SDD y cómo evitarlos

Spec-novela
Spec con el "cómo"
Tareas gigantes
✗ 20 páginas que nadie revisa.
✗ "Usar Redis" escrito en la spec.
✗ "Implementa el checkout completo."

✓ Una feature por spec, 1–2 páginas.

✓ La tecnología va solo en el plan.

✓ Tareas cortas, cada una con su test.

Spec que miente
Tests y código del mismo prompt
Aprobar sin leer
✗ El código cambió y la spec no.
✗ El agente escribe tests que confirman su propio código.
✗ Confiar en el "listo" del agente.

✓ Spec y código en el mismo PR.

✓ Tests primero, en tarea aparte y revisados.

✓ Exigir la salida del test runner y revisar el diff.
37

### Notes:
Estos seis errores aparecen en casi todos los equipos que empiezan. Cada tarjeta trae el error y su corrección. Pedir a la clase que identifique cuál ha cometido ya con un agente.

<!-- Slide number: 38 -->
APLICABILIDAD
¿Cuándo adoptar SDD y cómo empezar?

Recomendado
No recomendado
Cómo empezar mañana
✓ Sistemas complejos: requerimientos estrictos o regulados
✓ Equipos con agentes: Claude Code, Copilot, Cursor
✓ Dinero o datos sensibles: pagos, salud, identidad
✓ Auditoría técnica: necesidad de trazabilidad
✗ Tareas triviales: agregar un campo aislado
✗ Prototipos descartables: pruebas de concepto de horas
✗ Exploración: aún no sabes qué quieres construir
✗ Sobrecarga documental: más costo que beneficio
Escribe la constitución del proyecto.
Elige UNA feature mediana, no la más crítica.
Haz el ciclo completo con revisiones.
Retrospectiva: ¿qué le faltó a la spec?

Regla práctica: si explicar la tarea a otra persona te tomaría más de cinco minutos, merece una spec. Si cabe en una frase, no.
38

### Notes:
SDD tiene un costo: escribir y revisar documentos. Vale la pena cuando el costo de un error es alto o cuando un agente hace gran parte del trabajo. Para empezar, una sola feature mediana y una retrospectiva honesta.

<!-- Slide number: 39 -->
06
BLOQUE 06
Taller aplicado
Diseña el flujo SDD completo para un motor de transferencias multidivisa.

<!-- Slide number: 40 -->
TALLER APLICADO • ENTREGABLE PARA CLASE
Caso: motor de transferencias multidivisa

El reto del sistema

ENTREGABLE 1
.specs/SPEC-TRANSFER.md
Reglas de negocio numeradas, estados de la transferencia, escenarios de aceptación y no-objetivos.
Diseñar el flujo SDD completo para transferencias entre billeteras en distintas monedas (USD, EUR, COP), con bloqueo de saldo, control de saldo negativo y auditoría contable.

ENTREGABLE 2
.specs/PLAN-TRANSFER.md
Invariantes críticas
Contratos de API, esquemas JSON, estrategia de concurrencia justificada y diagrama de flujo.
Ninguna billetera puede quedar con saldo negativo.
La tasa de cambio se congela por máximo 60 segundos.
La operación es atómica (transacción ACID o Saga con compensación).
Cada transferencia genera asientos contables que suman cero (partida doble).

ENTREGABLE 3
.specs/TASKS-TRANSFER.md
4 tareas atómicas con tests previos, dependencias, definición de terminado y matriz de trazabilidad.
40

### Notes:
Presentar el reto y las cuatro invariantes. Se agregó la de partida doble porque conecta con el contexto de Contabilidad visto en DDD. Los tres entregables siguen la misma estructura del caso práctico.

<!-- Slide number: 41 -->
TALLER APLICADO • PASO A PASO
Cómo resolver el taller en 90 minutos

1. Modelar el dominio
Lista los eventos en pasado: TransferenciaSolicitada, TasaCongelada, SaldoBloqueado, TransferenciaCompletada, TasaExpirada.

10 min

2. Redactar CONSTITUTION.md
Dinero en enteros, monedas en ISO 4217, transacciones ACID o Saga, tests primero.

10 min

3. Escribir SPEC-TRANSFER
Reglas R1–Rn, máquina de estados y al menos 5 escenarios Gherkin, incluyendo casos borde.

20 min

4. Clarify cruzado
Intercambia la spec con otro grupo: ellos marcan ambigüedades con [NEEDS CLARIFICATION].

10 min

5. Escribir PLAN-TRANSFER
Contratos de API, esquemas JSON y estrategia de concurrencia (bloqueo optimista o pesimista) con su porqué.

20 min

6. Escribir TASKS-TRANSFER
4 tareas atómicas: reglas que cubre, archivos, dependencias y definición de terminado.

15 min

7. Matriz de trazabilidad
Verifica que cada regla tenga tarea y test. Ninguna regla huérfana.

5 min
41

### Notes:
Agenda sugerida para trabajo en grupos de 3 a 4 personas. El paso 4 (intercambio con otro grupo) es el más valioso: simula la fase Clarify con ojos externos. Ajustar los tiempos según la clase.

<!-- Slide number: 42 -->
TALLER APLICADO • PISTA
Punto de partida: máquina de estados sugerida
debitar y acreditar

CREADA

TASA_CONGELADA

SALDO_BLOQUEADO

COMPLETADA
cotizar
bloquear

pasan > 60 s
saldo insuficiente

EXPIRADA

RECHAZADA
Preguntas que tu spec debe responder

?  ¿Qué pasa con el saldo bloqueado si la transferencia expira o es rechazada?

?  ¿Quién define la tasa de cambio y con cuántos decimales se redondea?

?  ¿Puede una billetera transferirse a sí misma o a una moneda igual a la suya?

?  ¿Qué asientos contables se generan en cada estado final?
42

### Notes:
Es una pista, no la respuesta: cada grupo puede modificarla. Lo importante es que cada transición tenga una regla en la spec y que los estados finales sean explícitos.

<!-- Slide number: 43 -->
TALLER APLICADO • EVALUACIÓN
Rúbrica de evaluación
| Criterio | Peso | Excelente | Insuficiente |
| --- | --- | --- | --- |
| Spec sin ambigüedad | 25 % | Reglas numeradas, verificables y sin tecnología; no-objetivos explícitos. | Adjetivos vagos o mezcla del qué con el cómo. |
| Cobertura de invariantes | 20 % | Las 4 invariantes con escenarios y casos borde. | Invariantes sin escenario que las pruebe. |
| Plan y contratos | 20 % | API, esquemas y estrategia de concurrencia justificada. | Contratos incompletos o decisiones sin justificar. |
| Tareas atómicas | 20 % | 4 tareas con test previo, dependencias y definición de terminado. | Tareas grandes, sin tests o sin orden. |
| Trazabilidad | 15 % | Cada regla → tarea → test, sin huérfanas. | Reglas sin tarea o tareas sin regla. |
Bonificación: implementar una tarea con un agente siguiendo el bucle de verificación y mostrar la salida de los tests.
43

### Notes:
Compartir la rúbrica antes de empezar el taller: así los grupos saben qué se evalúa. Los dos criterios con más peso son la calidad de la spec y la cobertura de invariantes.

<!-- Slide number: 44 -->
CONCLUSIÓN
El futuro: especificar es el nuevo programar

Escribe el qué antes del cómo
La spec se valida con negocio; la tecnología vive en el plan.
Divide y verifica
Tareas pequeñas, tests primero y el test runner como juez.
Mantén la spec viva
Todo cambio pasa primero por la spec, en el mismo PR que el código.
Espacio para preguntas y discusión

### Notes:
Cerrar con las tres ideas clave. Las especificaciones claras y estructuradas son lo que permite que la automatización construya exactamente lo que el negocio necesita. Abrir espacio para preguntas.