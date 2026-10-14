'use strict';

const fs = require('node:fs');
const path = require('node:path');

const rows = Number(process.argv[2] ?? 10_000_000);
const outputPath = path.resolve(process.argv[3] ?? 'big.csv');

if (!Number.isSafeInteger(rows) || rows < 0 || rows > 10_000_000) {
  console.error('La cantidad de filas debe ser un entero entre 0 y 10000000.');
  process.exit(1);
}

const output = fs.createWriteStream(outputPath);
let remaining = rows;
let failed = false;

output.on('error', (error) => {
  failed = true;
  console.error(`No se pudo escribir ${outputPath}: ${error.message}`);
  process.exitCode = 1;
});

output.once('finish', () => {
  if (!failed) console.log(`CSV creado: ${outputPath} (${rows} filas).`);
});

function writeBlock() {
  if (failed) return;

  while (remaining > 0) {
    const row = `${remaining},${Math.floor(Math.random() * 5000)},ACTIVO\n`;
    remaining -= 1;

    if (!output.write(row)) {
      output.once('drain', writeBlock);
      return;
    }
  }

  output.end();
}

writeBlock();