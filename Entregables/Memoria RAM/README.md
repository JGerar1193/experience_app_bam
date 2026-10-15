# Procesamiento CSV con Streams

El laboratorio genera un CSV por bloques, respeta la señal de backpressure (`write()` y `drain`) y lo transforma en otro archivo mediante `pipeline()` sin cargarlo completo en memoria.

## Ejecución

Desde esta carpeta, genera hasta diez millones de filas. Si omites el argumento, se usa el volumen del laboratorio:

```powershell
node seed.js 10000000
```

Después transforma el archivo y observa la telemetría del Heap:

```powershell
node pipeline.js
```

El proceso puede crear archivos grandes y tardar. Para probarlo primero con 100 filas:

```powershell
node seed.js 100 big.csv
node pipeline.js big.csv final.txt
```

También puedes indicar rutas de entrada y salida como segundo y tercer argumento de `pipeline.js`. `big.csv` y `final.txt` están excluidos de Git.