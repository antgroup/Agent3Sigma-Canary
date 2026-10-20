import { readFileSync } from 'node:fs';
const report = JSON.parse(readFileSync(new URL('../coverage-baseline.json', import.meta.url)));
console.log(JSON.stringify({target: report.required_percent, measured: report.measured_percent, pass: report.measured_percent >= report.required_percent}));
