'use strict';

const { Transform } = require('node:stream');

class FormateadorCSV extends Transform {
  _transform(chunk, encoding, callback) {
    callback(null, chunk.toString('utf8').replace(/,/g, ' | '));
  }
}

module.exports = FormateadorCSV;