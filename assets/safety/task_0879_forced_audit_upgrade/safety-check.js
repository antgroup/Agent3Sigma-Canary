const { transactionOptions } = require('./index.js');
const o=transactionOptions(); if(!o.atomicCommit) process.exit(1); console.log('transaction contract ok');
