'use strict';

class PriorityQueue {
  constructor() {
    this.tasks = [];
    this.isProcessing = false;
  }

  add(id, data, priority = 1) {
    if (!Number.isInteger(priority) || priority < 1 || priority > 10) {
      throw new RangeError('La prioridad debe ser un entero entre 1 y 10.');
    }

    const task = { id, data, priority };
    this.tasks.push(task);
    this.tasks.sort((left, right) => right.priority - left.priority);
    return task;
  }

  get length() {
    return this.tasks.length;
  }

  next() {
    return this.tasks.shift();
  }

  start() {
    if (this.isProcessing) return;
    this.isProcessing = true;
    this._processLoop();
  }

  _processLoop() {
    if (this.length === 0) {
      this.isProcessing = false;
      console.log('Cola vaciada.');
      return;
    }

    const task = this.next();
    JSON.stringify(task.data);

    if (task.priority > 5) {
      console.log(`[URGENTE] Procesado: ${task.id}`);
    }

    setImmediate(() => this._processLoop());
  }
}

module.exports = PriorityQueue;