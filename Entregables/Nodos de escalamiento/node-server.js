'use strict';

const net = require('node:net');

const port = Number(process.argv[2] ?? 3001);

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('El puerto debe ser un entero entre 1 y 65535.');
  process.exit(1);
}

const server = net.createServer((socket) => {
  const nodeId = `Nodo-${port}`;
  console.log(`[${nodeId}] Conexión recibida.`);

  const responseTimer = setTimeout(() => {
    socket.end(`Respuesta desde ${nodeId}\n`);
  }, 500);

  socket.once('error', () => clearTimeout(responseTimer));
});

server.on('error', (error) => {
  console.error(`[Nodo-${port}] ${error.message}`);
  process.exitCode = 1;
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Nodo-${port} escuchando en 127.0.0.1:${port}.`);
});