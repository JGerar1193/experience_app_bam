'use strict';

const PriorityQueue = require('./queue');

const queue = new PriorityQueue();

console.log('Cargando 5000 reportes de prioridad baja...');
for (let index = 0; index < 5000; index += 1) {
  queue.add(`Rep-${index}`, { mock: true }, 1);
}

queue.start();

setTimeout(() => {
  console.log('\n--- Llega tráfico VIP ---');
  queue.add('Transf-A', { user: 'CEO' }, 10);
  queue.add('Transf-B', { user: 'CFO' }, 10);
  queue.add('Transf-C', { user: 'CTO' }, 10);
  queue.start();
}, 0);