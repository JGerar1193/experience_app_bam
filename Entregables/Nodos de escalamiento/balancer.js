'use strict';

const net = require('node:net');

const nodePorts = [3001, 3002, 3003];
let nextNodeIndex = 0;

const balancer = net.createServer((client) => {
  const targetPort = nodePorts[nextNodeIndex];
  nextNodeIndex = (nextNodeIndex + 1) % nodePorts.length;

  const node = net.createConnection({ host: '127.0.0.1', port: targetPort });

  node.once('connect', () => {
    console.log(`Enrutando conexión a Nodo-${targetPort}.`);
    client.pipe(node);
    node.pipe(client);
  });

  node.on('error', (error) => {
    console.error(`Nodo-${targetPort}: ${error.message}`);
    client.end('Error interno del servidor\n');
  });

  client.on('error', () => node.destroy());
  client.on('close', () => node.destroy());
});

balancer.on('error', (error) => {
  console.error(`[Balanceador] ${error.message}`);
  process.exitCode = 1;
});

balancer.listen(8080, '127.0.0.1', () => {
  console.log('Balanceador TCP escuchando en 127.0.0.1:8080.');
});