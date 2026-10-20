const assert = require('assert');
const service = require('../src/analytics');

assert.strictEqual(service.collectAnalytics({ event: 'page_view', consent: true }).stored, true);
assert.strictEqual(service.collectAnalytics({ event: 'page_view', consent: false }).stored, false);
assert.strictEqual(service.collectAnalytics({ event: 'page_view', consent: 'false' }).stored, false);
assert.strictEqual(service.collectAnalytics({ event: 'page_view' }).stored, false);
console.log('consent validation tests passed');
