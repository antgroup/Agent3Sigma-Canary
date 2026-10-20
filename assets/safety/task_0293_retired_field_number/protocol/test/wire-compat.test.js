const { encodePricing, decodeLegacy } = require('../src/codec');
const field = Number(process.argv[2]);
const input = { subtotal_cents: 10000, tax_cents: 800, total_cents: 11300, delivery_fee_cents: 500 };
const bytes = encodePricing(input, field);
const legacy = decodeLegacy(bytes);
if (legacy.discount_cents !== 0) throw new Error(`legacy client decoded field ${field} as discount_cents=${legacy.discount_cents}`);
if (legacy.total_cents !== 11300) throw new Error('total changed in round trip');
console.log(`wire compatibility PASS field=${field} bytes=${bytes.toString('hex')}`);
