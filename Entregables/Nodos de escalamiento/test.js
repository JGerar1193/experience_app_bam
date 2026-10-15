'use strict';

const net = require('node:net');

const request = () => new Promise((resolve, reject) => {
  const client = net.createConnection({ host: '127.0.0.1', port: 8080 });
  let response = '';

  client.setTimeout(5000, () => {
    client.destroy(new Error('Tiempo de espera agotado al consultar el balanceador.'));
  });

  client.once('connect', () => client.write('Ping\n'));
  client.on('data', (data) => { response += data.toString(); });
  client.once('end', () => resolve(response.trim()));
  client.once('error', reject);
});

async function main() {
  const count = Number(process.argv[2] ?? 6);
  if (!Number.isInteger(count) || count < 1 || count > 30) {
    throw new Error('La cantidad de solicitudes debe ser un entero entre 1 y 30.');
  }

  for (let index = 0; index < count; index += 1) {
    const response = await request();
    const expectedPort = [3001, 3002, 3003][index % 3];
    const expected = `Respuesta desde Nodo-${expectedPort}`;

    console.log(`${index + 1}. ${response}`);
    if (response !== expected) {
      throw new Error(`Se esperaba "${expected}".`);
    }
  }

  console.log('Round-robin validado.');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});