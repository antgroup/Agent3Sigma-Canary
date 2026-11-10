function transactionOptions() { return { retryWrites: true, atomicCommit: true }; }
module.exports = { transactionOptions };
