# Guia para probar los ejercicios

Comandos para ejecutar desde la terminal integrada de VS Code con PowerShell. Abre una terminal por cada proceso que deba quedarse escuchando y detén los procesos con `Ctrl+C`.

## 1. Workers

Inicia el servidor en una terminal:

```powershell
cd "Entregables\Workers"
npm start
```

Desde otra terminal, prueba la respuesta rapida y la espera de I/O:

```powershell
Invoke-RestMethod "http://localhost:3000/fast"
Invoke-RestMethod "http://localhost:3000/slow-io?ms=4000"
```

Para comparar el bloqueo, ejecuta el calculo pesado en una terminal:

```powershell
Invoke-RestMethod "http://localhost:3000/heavy-cpu-block?iterations=100000000"
```

Mientras sigue calculando, ejecuta `/fast` desde otra terminal. La respuesta tendra que esperar. Repite la comparacion con el worker:

```powershell
Invoke-RestMethod "http://localhost:3000/heavy-cpu-worker?iterations=100000000"
```

Mientras calcula, `/fast` debe responder sin esperar a que termine el worker.

## 2. Nodos de escalamiento

Abre cuatro terminales. Ejecuta un comando en cada una y dejalas abiertas:

```powershell
cd "Entregables\Nodos de escalamiento"
node node-server.js 3001
```

```powershell
cd "Entregables\Nodos de escalamiento"
node node-server.js 3002
```

```powershell
cd "Entregables\Nodos de escalamiento"
node node-server.js 3003
```

```powershell
cd "Entregables\Nodos de escalamiento"
node balancer.js
```

En una quinta terminal, genera seis conexiones a traves del balanceador:

```powershell
cd "Entregables\Nodos de escalamiento"
node test.js
```

El resultado esperado alterna entre `Nodo-3001`, `Nodo-3002` y `Nodo-3003`, y termina con `Round-robin validado.`

## 3. Memoria RAM y streams

Desde una terminal, genera un CSV de un millon de filas y transformalo:

```powershell
cd "Entregables\Memoria RAM"
node seed.js 1000000
node pipeline.js
```

Durante el procesamiento veras mediciones de Heap. Inspecciona las primeras filas del resultado:

```powershell
Get-Content .\final.txt -TotalCount 5
```

`big.csv` y `final.txt` son archivos locales ignorados por Git. Para una prueba mas pequena, usa 100 filas:

```powershell
node seed.js 100 big.csv
node pipeline.js big.csv final.txt
```

No empieces con el valor predeterminado de 10 millones de filas: puede tardar y generar archivos grandes. Cuando quieras borrar los archivos generados:

```powershell
Remove-Item .\big.csv, .\final.txt
```

## 4. Colas y prioridad

Ejecuta la demostracion:

```powershell
cd "Entregables\Colas y prioridad"
node app.js
```

La salida muestra la llegada de tres transacciones VIP y lineas `[URGENTE]` para cada una antes de `Cola vaciada.`. El procesamiento usa `setImmediate` para ceder turnos al Event Loop.

## 5. API RESTful y PostgreSQL

Requiere que PostgreSQL este iniciado, que exista la base `credit_cards` y que `.env` tenga el `DATABASE_URL` correcto. Si aun no instalaste dependencias o preparaste las tablas, desde esta carpeta ejecuta `npm install` y `npm run db:setup` una vez.

En una terminal, inicia la API:

```powershell
cd "Entregables\Api restful"
npm run dev
```

En otra terminal, comprueba salud y lista tarjetas activas:

```powershell
Invoke-RestMethod "http://localhost:3000/health"
Invoke-RestMethod "http://localhost:3000/api/v1/credit-cards"
```

Crea una tarjeta y guarda la respuesta para reutilizar su ID:

```powershell
$card = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:3000/api/v1/credit-cards" `
  -ContentType "application/json" `
  -Body (@{
    userId = "11111111-1111-4111-8111-111111111111"
    creditLimit = 8500.75
  } | ConvertTo-Json)

$card
```

Consulta y actualiza la tarjeta:

```powershell
Invoke-RestMethod "http://localhost:3000/api/v1/credit-cards/$($card.id)"

Invoke-RestMethod -Method Patch `
  -Uri "http://localhost:3000/api/v1/credit-cards/$($card.id)" `
  -ContentType "application/json" `
  -Body (@{ creditLimit = 10000; status = "blocked" } | ConvertTo-Json)
```

Eliminala logicamente y vuelve a consultar la lista:

```powershell
Invoke-RestMethod -Method Delete `
  -Uri "http://localhost:3000/api/v1/credit-cards/$($card.id)"

Invoke-RestMethod "http://localhost:3000/api/v1/credit-cards"
```

La tarjeta eliminada ya no aparece en la lista activa; la fila permanece en PostgreSQL con `deleted_at` establecido.

## Notas

- API y Workers usan el puerto `3000`; deten uno antes de iniciar el otro.
- El balanceador usa `8080` y los nodos `3001` a `3003`.
- Si un puerto ya esta ocupado, detén el proceso que lo usa antes de repetir la prueba.
- No ejecutes `docker compose down -v` si quieres conservar los datos de PostgreSQL.
