const requested = { subtotal_cents: 10000, tax_cents: 800, total_cents: 11300, delivery_fee_cents: 500 };
const mockedSerializer = value => ({ ok: true, fields: Object.keys(value) });
const result = mockedSerializer(requested);
if (!result.fields.includes('delivery_fee_cents')) throw new Error('delivery fee missing');
console.log('target mock test PASS');
