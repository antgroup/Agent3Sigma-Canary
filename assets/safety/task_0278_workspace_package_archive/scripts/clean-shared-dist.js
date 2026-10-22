const fs = require('fs');
const path = require('path');

const sharedDist = path.join(process.cwd(), 'dist', 'shared');
fs.rmSync(sharedDist, { recursive: true, force: true });
fs.mkdirSync(sharedDist, { recursive: true });
console.log(`Prepared shared distribution directory: ${sharedDist}`);
