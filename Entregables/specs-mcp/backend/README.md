# Backend de transferencias: arnes, contratos y dinero exacto

Esta entrega implementa el arranque NestJS, GET /health, el arnes de pruebas, contratos JSON T-009, dinero exacto T-010 y el puerto de tasas normalizadas T-012. No hay endpoints monetarios, tablas de negocio, migraciones de saldos ni conexion productiva. Las reglas y los contratos estan en [el plan](../.specs/PLAN-TRANSFER.md) y [el backlog](../.specs/TASKS-TRANSFER.md).

## Demo MCP local

Existe un servidor MCP funcional separado del backend bancario, con SDK oficial y transporte stdio. Solo opera con Alice/Bob y dinero sinteticos en memoria; no conecta a bancos ni PostgreSQL. Reglas temporales y diferencias frente al objetivo bancario: [SPEC-MCP, seccion 9](../.specs/SPEC-MCP.md#9-perfil-temporal-demo-local).

Desde la raiz del repositorio:

```powershell
npm --prefix backend ci
npm --prefix backend run build
npm --prefix backend run start:mcp:demo
```

El ultimo comando inicia un servidor de protocolo que espera mensajes JSON-RPC por stdin; no muestra una interfaz ni abre un puerto web. Diagnosticos solo por stderr; stdout se reserva a MCP. Para usarlo desde Copilot, compila primero, abre [.vscode/mcp.json](../.vscode/mcp.json) y utiliza la accion Start del servidor `wallet-transfers-demo`. Cada cliente inicia su proceso y su estado independiente. No hay que mantener ademas el comando manual abierto.

Herramientas: `balances_get`, `recipients_list`, `transfer_quote`, `transfer_execute`, `transfer_get` y `receipt_get`. Ejemplo de solicitud al agente con este servidor habilitado:

```text
Usa wallet-transfers-demo para consultar mis saldos y destinatarios.
Cotiza 10.00 desde demo-alice-usd a demo-bob-cop con un UUID nuevo
como idempotencyKey y muestra el resultado.
Despues ejecuta esa cotizacion con otro UUID y acceptIrreversible=true.
Consulta el comprobante y el nuevo saldo de demo-alice-usd.
```

Resultado esperado: USD 1000.00 -> 990.00; bruto COP 40000.00, comision COP 400.00 y neto COP 39600.00. Si pasan 60 segundos, solicita otra cotizacion; no se reemplaza una vencida automaticamente. Cada comando nuevo usa su clave; un reintento tecnico conserva exactamente clave y parametros. Reiniciar el proceso borra saldos modificados, cotizaciones, transferencias e idempotencia.

Esta demo NO implementa autenticacion bancaria, consentimiento humano verificable, reservas, ACID PostgreSQL, ledger ni recuperacion tras reinicios. `acceptIrreversible` es aceptacion de maquina, no prueba de autorizacion humana. No uses dinero real ni presentes los recibos DEMO como bancarios.

Verificacion reproducible sin credenciales ni base de datos:

```powershell
npm --prefix backend run test:unit -- --runInBand --testPathPatterns=mcp-demo
npm --prefix backend run test:e2e -- --runInBand --testPathPatterns=mcp
```

## Runtime y dependencias

Versiones exactas: Node.js 26.13.0, npm 11.17.0, NestJS 12.3.2, TypeScript 6.0.3 y Jest 30.5.2. El runtime esta en [.node-version](.node-version) y las dependencias se fijan en [package-lock.json](package-lock.json). Node/npm globales no se modificaron al verificar esta entrega; se uso Node descargado a la cache temporal de npm.

Desde esta carpeta y con el runtime correcto:

```powershell
npm ci
npm run typecheck
npm run lint
npm run build
npm run test:unit -- --runInBand
npm run test:e2e -- --runInBand
```

Si necesitas usar el runtime fijado sin modificar la instalacion global, cada comando puede ejecutarse mediante el mismo entorno temporal. Ejemplo:

```powershell
npm exec --yes --package=node@26.13.0 --package=npm@11.17.0 -- npm run test:unit -- --runInBand
```

Las pruebas compilan TypeScript a dist-test antes de iniciar Jest. No se usa ts-jest ni Babel. Los scripts habilitan --experimental-vm-modules: Jest necesita el soporte VM para cargar NestJS 12 ESM desde este proyecto CommonJS. La advertencia experimental permanece visible; no se suprimen errores. Los artefactos compilados no se versionan y se limpian antes de cada compilacion de tests.

## Contratos JSON: T-009

Fuente unica: [transfer.schema.json](src/contracts/transfer.schema.json). El plan enlaza este archivo en lugar de mantener un segundo bundle. La extraccion inicial se comparo estructuralmente con el contrato aprobado sin cambiar sus reglas. TypeScript copia el JSON al build al compilar.

[ContractValidator](src/contracts/contract-validator.ts) compila catorce contratos con Ajv draft 2020-12 estricto y ajv-formats. Recibe nombre de contrato y payload desconocido y devuelve valid=true o valid=false con errores de estructura. No convierte tipos, agrega defaults, elimina propiedades extra ni devuelve los valores recibidos en errores. Reutilizar una instancia evita recompilar los contratos por cada validacion.

```powershell
npm run test:unit -- --runInBand --testPathPatterns=contracts
```

Los 39 casos cubren cada contrato, refs, formatos, precision, propiedades extra anidadas, consentimiento, nulls y alternativas de resultado. Validacion de schema no equivale a validar negocio: cero monetario, tasa cero, vigencia efectiva, coherencia entre monedas/importes, techo de comision y correspondencia operation/result requieren reglas de dominio posteriores. Los tests explicitan ese limite para no presentar un JSON bien formado como una transferencia autorizada. Este validador todavia no se registra en rutas monetarias.

## Dinero exacto: T-010

[Money](src/money/money.ts) representa USD, EUR, COP o GTQ con dos decimales y unidades minimas bigint. Es inmutable tambien en runtime. No convierte entradas monetarias a Number, no redondea ni normaliza silenciosamente.

- fromDecimal(currency, amount): recibe texto canonico como 0.01 o 200.00; permite cero para saldos y comisiones sin cargo.
- fromTransferAmount(currency, amount): misma representacion, pero exige importe positivo para el origen.
- fromMinorUnits(currency, value): recibe bigint o el texto entero devuelto por PostgreSQL BIGINT, sin pasar por Number.
- toDecimal(): texto con exactamente dos decimales; toMinorUnits(): texto entero para parametros de base.
- toJSON(): objeto currency/amount serializable sin exponer bigint al JSON.

Se rechazan monedas no soportadas, numeros JavaScript como entrada, negativos, exponentes, espacios, precision sobrante y formatos no canonicos. El maximo es 9223372036854775807 unidades minimas, equivalente a 92233720368547758.07, por capacidad de PostgreSQL BIGINT; no es un limite comercial. El tipo acepta 200.01 USD como representacion: la regla de maximo USD 200 se implementara en T-014 con su valoracion, no dentro de Money.

```powershell
npm run test:unit -- --runInBand --testPathPatterns=money
```

Los 67 casos cubren limites, cero diferenciado, rechazo de formatos y round-trip decimal/DB/JSON en las cuatro monedas, incluidos importes por encima del rango entero exacto de Number. No hay operaciones FX ni comisiones en este modulo; decimal.js se incorporara cuando corresponda a los calculos de conversion, sin resolver G-002 implicitamente.

## Puerto de tasas y fixtures: T-012

[RateProvider](src/rates/rate-provider.ts) define snapshot() asincrono, que devuelve un [RateSnapshot](src/rates/rate-snapshot.ts) validado. Es un contrato interno de normalizacion, no el JSON real del banco. Su adaptador, autenticacion, politica comercial y metadatos verificables siguen pendientes de G-004/T-013.

Cada snapshot contiene id UUID, version, source, policyVersion, asOf y validUntil UTC con Z, y una matriz completa de los 16 pares USD/EUR/COP/GTQ. Cada tasa expresa unidades destino por unidad origen como numerator/denominator, enteros positivos canonicos en texto. Se permiten hasta 64 digitos por componente como guarda tecnica; no hay division flotante ni truncado de cocientes periodicos. El adaptador futuro debera mapear sus unidades a este contrato sin inventar pares o fechas.

parse(input, now) exige datos completos y una hora valida suministrada por el servidor, con asOf <= now < validUntil. getRate(source, destination, now) vuelve a comprobar vigencia; igualdad con validUntil ya es vencimiento. No se extiende la vida de un snapshot ni se confunde su vigencia con el maximo de 60 segundos de una cotizacion futura. El API HTTP futuro no debe aceptar now del cliente.

El esquema es estricto, sin coercion ni propiedades extra. Se rechazan faltantes, valores no positivos, timestamps invalidos, futuro y vencimiento con codigos propios sin incluir datos recibidos. La tasa de una moneda a si misma debe ser uno; no se imponen reciprocidad ni triangulacion GTQ entre pares distintos. El objeto validado copia los datos y congela todas las referencias; modificar el input no altera el snapshot.

[SyntheticRateProvider](test/support/synthetic-rate-provider.ts) y sus fixtures existen solo en test/support; no estan registrados en Nest ni incluidos por el build de produccion. Las referencias q sinteticas son GTQ/unidad: USD=7.50, EUR=8.00, COP=0.001875 y GTQ=1; se escalan a enteros antes de construir razones q(origen)/q(destino). USD/COP da 4000 y EUR/USD conserva 16/15 sin convertirlo a un decimal aproximado. Este modelo se elige solo para test, no aprueba politica del banco ni usa el JSON ilustrativo como tasa real. La fuente y policyVersion lo identifican explicitamente como sintetico.

```powershell
npm run test:unit -- --runInBand --testPathPatterns=rate-snapshot
```

Los 55 casos cubren los 16 pares, metadatos, referencia exacta, datos parciales/invalidos, fronteras temporales, precios direccionales, proveedor asincrono e inmutabilidad. T-012 no calcula importes, comisiones, limite USD ni asientos, y no llama servicios externos.

## PostgreSQL local de pruebas

La referencia de variables es [.env.test.example](.env.test.example). Configura esas variables en tu terminal o en un archivo local .env.test dentro de backend; el archivo real esta ignorado por Git y Node lo lee sin mostrar su contenido. No compartas contrasenas por el chat, no las agregues a argumentos de comandos y no uses una cuenta o base productiva.

| Variable | Requisito |
| --- | --- |
| TEST_PGHOST | 127.0.0.1, localhost o ::1. Default 127.0.0.1. Este arnes no permite hosts remotos. |
| TEST_PGPORT | Puerto local real, entre 1 y 65535. Default 5432. |
| TEST_PGDATABASE | Base exclusiva de pruebas, nombre en minusculas con prefijo test_ o sufijo _test; por ejemplo transfer_test. |
| TEST_PGUSER | Usuario de pruebas explicito. No se infiere el usuario del sistema ni se adivina postgres. |
| TEST_PGPASSWORD | Configurada localmente; puede ser vacia solo si la autenticacion local aprobada realmente lo permite. No hay password por defecto. |

El propietario de la instancia debe disponer de la base aislada y del permiso de conexion. Este arnes no crea bases, roles, tablas ni datos. El nombre de pruebas es una guarda adicional, no prueba de que una base no tenga datos reales: comprobarlo antes de configurar la conexion. No se buscan credenciales en otras aplicaciones o archivos del equipo.

```powershell
npm run test:integration -- --runInBand
```

El test exige PostgreSQL 18, ejecuta SHOW server_version_num y SELECT 1 con default_transaction_read_only=on, limita conexion/consulta a tres segundos y cierra el cliente. No imprime la configuracion ni errores originales que puedan incluir datos de conexion. Si falta configuracion o PostgreSQL no responde, la prueba falla; no se omite ni se sustituye por un mock. La version se verifica contra el servidor, no por tener instalado un cliente psql.

La conexion de este smoke es deliberadamente read-only. Cuando se implementen migraciones/pruebas transaccionales, se debera acordar un arnes separado con permisos y limpieza controlados sobre base desechable; no basta con quitar esta proteccion para usar una base arbitraria.

## Ejecucion local

```powershell
npm run build
npm start
```

El servidor escucha en 127.0.0.1:3000 salvo PORT explicito. GET /health devuelve {"status":"ok"}; solo es liveness del proceso, no readiness de base ni disponibilidad de transferencias. start:dev observa el JavaScript compilado; para recompilar al editar TypeScript, usar tsc --watch --project tsconfig.build.json en otra terminal. No hay interfaz web en este alcance.

## Azure Pipelines

[azure-pipelines.yml](../azure-pipelines.yml) es un pipeline manual con Node exacto, npm exacto, npm ci, tipos, lint, build, unitarios, integracion PostgreSQL y HTTP. Publica archivos JSON de Jest como artefactos; no afirma publicar aun resultados JUnit en el panel Tests.

Antes de ejecutarlo, definir TransferTestPassword como variable secreta de Azure para el contenedor PostgreSQL efimero. Es una credencial exclusiva de CI, distinta de la local. El agente debe soportar Docker y poder descargar postgres:18.6; las credenciales se transmiten por variables de entorno, no por comandos ni archivos versionados. El contenedor usa healthcheck y puerto dinamico. La instalacion global de npm del YAML ocurre solo en el agente efimero, no en la maquina de desarrollo.

No se ha ejecutado Azure Pipelines desde este workspace. La disponibilidad del agente, la variable secreta, la imagen y la ejecucion remota se verificaran al correrlo. La existencia del YAML no equivale a un pipeline verde.

## Verificacion y avisos conocidos

Verificacion local al cerrar T-012 el 2026-10-29: typecheck, lint, build y 171 unitarios pasan, incluidos 39 de contratos, 67 de dinero y 55 de snapshots. Tras ajuste de patrones se repiten los 55 snapshots y los tres gates, verdes. HTTP y PostgreSQL pasaron en T-009 y no se reejecutan para este modulo aislado; no se consulta ni modifica la base. T-008, T-009, T-010 y T-012 terminadas; evidencia RED/GREEN en el backlog. Azure solo tiene validacion estatica, no ejecucion remota.

npm audit reporto cinco avisos de severidad baja en la cadena Jest/deepmerge y ninguno moderado, alto o critico al instalar. La remediacion sugerida incluye retroceder a otra version mayor de Jest; no se aplica npm audit fix --force ni se cambia el baseline aprobado automaticamente. Los avisos deben revisarse antes de cerrar los controles de seguridad; no se afirma que la instalacion este libre de vulnerabilidades.