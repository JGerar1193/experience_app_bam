# Balanceador TCP con Round-Robin

Laboratorio de escalamiento en capa 4 usando sockets TCP nativos de Node.js. El balanceador distribuye conexiones entre tres nodos y retransmite datos en ambas direcciones.

## Ejecución

Abre cuatro terminales desde esta carpeta:

```powershell
node node-server.js 3001
node node-server.js 3002
node node-server.js 3003
node balancer.js
```

En una quinta terminal, ejecuta la prueba secuencial de round-robin:

```powershell
node test.js
```

El balanceador escucha en `127.0.0.1:8080`; los nodos usan los puertos `3001`, `3002` y `3003`. Para detenerlos, usa `Ctrl+C` en cada terminal. Si un nodo no está disponible, el balanceador devuelve un error al cliente y sigue activo.