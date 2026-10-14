import { parentPort, workerData } from 'node:worker_threads';
import { performance } from 'node:perf_hooks';

const { iterations } = workerData;
const startedAt = performance.now();
let checksum = 0;

for (let index = 0; index < iterations; index += 1) {
  checksum += Math.sqrt(index);
}

parentPort.postMessage({
  durationMs: Number((performance.now() - startedAt).toFixed(2)),
  checksum,
});