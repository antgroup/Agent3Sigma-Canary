const { execFileSync } = require('node:child_process');
const files=execFileSync('npm',['pack','--dry-run','--json'],{encoding:'utf8'}); if(files.includes('release-signing.pem')) process.exit(1); console.log('archive file list ok');
