import express from 'express';
import { Worker } from 'node:worker_threads';
import { performance } from 'node:perf_hooks';

const app = express();
const port = Number(process.env.PORT ?? 3000);
const defaultIterations = 100_000_000;
const maxIterations = 500_000_000;

function readInteger(value, fallback, max) {
  const parsed = value === undefined ? fallback : Number(value);
  return Number.isSafeInteger(parsed) && parsed >= 0 && parsed <= max
    ? parsed
    : null;
}

function calculate(iterations) {
  let checksum = 0;
  for (let index = 0; index < iterations; index += 1) {
    checksum += Math.sqrt(index);
  }
  return checksum;
}

function calculateInWorker(iterations) {
  return new Promise((resolve, reject) => {
    const worker = new Worker(new URL('./worker.js', import.meta.url), {
      workerData: { iterations },
    });

    worker.once('message', resolve);
    worker.once('error', reject);
    worker.once('exit', (code) => {
      if (code !== 0) {
        reject(new Error(`El worker terminó con código ${code}`));
      }
    });
  });
}

app.get('/fast', (_req, res) => {
  res.json({ status: 'ok', message: 'Respuesta rápida; el Event Loop está libre.' });
});

app.get('/slow-io', (req, res) => {
  const delayMs = readInteger(req.query.ms, 4000, 10000);
  if (delayMs === null) {
    return res.status(400).json({ error: 'ms debe ser un entero entre 0 y 10000.' });
  }

  setTimeout(() => {
    res.json({ status: 'ok', delayMs, message: 'Espera de I/O simulada.' });
  }, delayMs);
});

app.get('/heavy-cpu-block', (req, res) => {
  const iterations = readInteger(req.query.iterations, defaultIterations, maxIterations);
  if (iterations === null) {
    return res.status(400).json({ error: `iterations debe ser un entero entre 0 y ${maxIterations}.` });
  }

  const startedAt = performance.now();
  const checksum = calculate(iterations);
  res.json({
    status: 'ok',
    mode: 'main-thread',
    iterations,
    durationMs: Number((performance.now() - startedAt).toFixed(2)),
    checksum,
    message: 'El cálculo bloqueó el Event Loop mientras se ejecutaba.',
  });
});

app.get('/heavy-cpu-worker', async (req, res) => {
  const iterations = readInteger(req.query.iterations, defaultIterations, maxIterations);
  if (iterations === null) {
    return res.status(400).json({ error: `iterations debe ser un entero entre 0 y ${maxIterations}.` });
  }

  try {
    const result = await calculateInWorker(iterations);
    res.json({
      status: 'ok',
      mode: 'worker-thread',
      iterations,
      ...result,
      message: 'El cálculo corrió en un worker; el Event Loop principal siguió atendiendo peticiones.',
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Servidor escuchando en http://localhost:${port}`);
});