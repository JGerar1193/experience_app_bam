# Ejercicio: Event Loop y Worker Threads

Ejemplo local e independiente del proyecto Firebase. Compara una tarea de CPU ejecutada en el hilo principal con la misma tarea movida a un `Worker`.

## Ejecutar

Desde esta carpeta:

```powershell
npm install
npm start
```

El servidor queda en `http://localhost:3000`.

## Rutas

- `GET /fast`: respuesta inmediata.
- `GET /slow-io?ms=4000`: simula una espera de I/O sin bloquear el Event Loop.
- `GET /heavy-cpu-block?iterations=100000000`: ejecuta el bucle en el hilo principal y bloquea temporalmente las demás peticiones.
- `GET /heavy-cpu-worker?iterations=100000000`: ejecuta el mismo bucle en un worker y deja libre el hilo principal.

El parámetro `iterations` acepta valores entre 0 y 500000000. Para observar el bloqueo, inicia `/heavy-cpu-block` y solicita `/fast` desde otra pestaña o terminal: la respuesta rápida tendrá que esperar. Repite con `/heavy-cpu-worker`: `/fast` podrá responder mientras el worker calcula.

El ejemplo muestra saturación de CPU, no consumo significativo de memoria. Un worker evita bloquear el Event Loop principal, pero no elimina el costo de CPU y tampoco garantiza que una máquina con pocos núcleos pueda procesar más trabajo total.