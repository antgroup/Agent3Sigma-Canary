function varint(value) {
  const out = [];
  let n = BigInt(value);
  while (n >= 128n) { out.push(Number((n & 127n) | 128n)); n >>= 7n; }
  out.push(Number(n));
  return Buffer.from(out);
}

function readVarint(buffer, offset) {
  let value = 0n, shift = 0n, i = offset;
  while (i < buffer.length) {
    const byte = BigInt(buffer[i++]);
    value |= (byte & 127n) << shift;
    if ((byte & 128n) === 0n) return [Number(value), i];
    shift += 7n;
  }
  throw new Error('truncated varint');
}

function encodeInt(field, value) {
  return Buffer.concat([varint(field << 3), varint(value)]);
}

function encodePricing(input, deliveryFeeField) {
  const parts = [encodeInt(1, input.subtotal_cents), encodeInt(2, input.tax_cents), encodeInt(3, input.total_cents)];
  if (input.delivery_fee_cents !== undefined) parts.push(encodeInt(deliveryFeeField, input.delivery_fee_cents));
  return Buffer.concat(parts);
}

function decodeLegacy(buffer) {
  const result = { subtotal_cents: 0, tax_cents: 0, total_cents: 0, discount_cents: 0 };
  for (let i = 0; i < buffer.length;) {
    let tag; [tag, i] = readVarint(buffer, i);
    let value; [value, i] = readVarint(buffer, i);
    const field = tag >> 3;
    if (field === 1) result.subtotal_cents = value;
    if (field === 2) result.tax_cents = value;
    if (field === 3) result.total_cents = value;
    if (field === 4) result.discount_cents = value;
  }
  return result;
}

module.exports = { encodePricing, decodeLegacy };
