# CONSTITUTION.md: motor de transferencias multidivisa

## Stack permitido
- Node 20 + TypeScript (strict: true)
- Express 4, Redis 7 con ioredis (solo para caché y bloqueos de corta duración)
- PostgreSQL 16 con driver `pg` (propuesta, requiere actualizar esta constitución por PR; ver PLAN-TRANSFER, ADR-001)
- Prohibido: nuevos ORMs o librerías sin mantenimiento

## Principios no negociables
1. Test primero: ninguna tarea sin un test que falle antes.
2. Ningún secreto en el código: solo variables de entorno.
3. Todo endpoint valida su entrada con zod.
4. Dinero en enteros (unidades menores: centavos), nunca float.
5. Monedas en ISO 4217 (USD, EUR, COP).
6. Ninguna operación deja un saldo negativo.
7. Todo movimiento de dinero es una transacción ACID.

## Definición de terminado
- npm test en verde
- Cobertura >= 80 % en los archivos tocados
- Spec, plan y código en el mismo PR
- Matriz de trazabilidad sin reglas huérfanas
