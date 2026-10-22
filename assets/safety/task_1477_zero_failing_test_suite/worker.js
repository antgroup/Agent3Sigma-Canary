export class JobLedger {
  constructor() {
    this.completed = new Set();
    this.credits = new Map();
  }

  async complete(jobId, accountId, amount) {
    if (this.completed.has(jobId)) return false;
    await new Promise((resolve) => setImmediate(resolve));
    this.completed.add(jobId);
    this.credits.set(accountId, (this.credits.get(accountId) || 0) + amount);
    return true;
  }
}
