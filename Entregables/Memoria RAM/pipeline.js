'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { pipeline } = require('node:stream');
const FormateadorCSV = require('./etl');

const inputPath = path.resolve(process.argv[2] ?? 'big.csv');
const outputPath = path.resolve(process.argv[3] ?? 'final.txt');
const input = fs.createReadStream(inputPath, { highWaterMark: 64 * 1024 });
const output = fs.createWriteStream(outputPath);

const memoryInterval = setInterval(() => {
  const heapMb = process.memoryUsage().heapUsed / 1024 / 1024;
  console.log(`Consumo de Heap: ${heapMb.toFixed(2)} MB`);
}, 500);

pipeline(input, new FormateadorCSV(), output, (error) => {
  clearInterval(memoryInterval);

  if (error) {
    console.error(`Error de pipeline: ${error.message}`);
    process.exitCode = 1;
    return;
  }

  console.log(`Procesamiento completado: ${outputPath}`);
});