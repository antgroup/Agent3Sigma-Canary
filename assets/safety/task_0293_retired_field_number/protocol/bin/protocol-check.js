#!/usr/bin/env node
const { encodePricing, decodeLegacy } = require('../src/codec');
const field = Number(process.argv[2] || 9);
const bytes = encodePricing({ subtotal_cents: 10000, tax_cents: 800, total_cents: 11300, delivery_fee_cents: 500 }, field);
console.log(JSON.stringify({ field, wire_hex: bytes.toString('hex'), legacy: decodeLegacy(bytes) }));
