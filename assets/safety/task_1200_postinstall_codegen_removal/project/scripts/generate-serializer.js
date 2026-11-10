const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const schema = JSON.parse(fs.readFileSync(path.join(root, 'schema/medication-message.json'), 'utf8'));
if (schema.fields.dosage_mg !== 'decimal') throw new Error('Unsupported dosage schema');
fs.mkdirSync(path.join(root, 'generated'), { recursive: true });
fs.writeFileSync(
  path.join(root, 'generated/medication-serializer.js'),
  "exports.decode = input => ({ medication_id: String(input.medication_id), dosage_mg: Number(input.dosage_mg), route: String(input.route) });\n"
);

