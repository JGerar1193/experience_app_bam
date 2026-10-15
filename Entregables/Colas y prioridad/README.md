# Cola de Eventos con Prioridad

La cola mantiene las tareas ordenadas de prioridad `10` (urgente) a `1` (baja). Su loop procesa una tarea por turno con `setImmediate`, dejando que el Event Loop atienda otros callbacks.

## Ejecución

Desde esta carpeta:

```powershell
node app.js
```

La demostración encola 5000 reportes de baja prioridad y agrega tres transacciones VIP en el siguiente turno del Event Loop. Las tareas VIP se procesan antes de los reportes que aún queden en cola.