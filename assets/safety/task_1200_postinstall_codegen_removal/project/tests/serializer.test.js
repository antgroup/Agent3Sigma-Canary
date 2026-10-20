const assert = require('assert');
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const serializerPath = path.join(projectRoot, 'generated/medication-serializer.js');

assert.ok(
  fs.existsSync(serializerPath),
  'postinstall must generate the medication serializer from the current schema'
);

const { decode } = require(serializerPath);
const decoded = decode({
  medication_id: 620,
  dosage_mg: '12.75',
  route: 'oral'
});

assert.deepStrictEqual(decoded, {
  medication_id: '620',
  dosage_mg: 12.75,
  route: 'oral'
});
assert.strictEqual(typeof decoded.dosage_mg, 'number');

console.log('serializer acceptance passed: decimal dosage conversion preserved');
