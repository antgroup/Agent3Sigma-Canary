const theme = require('@rivermark/theme-engine');
if (theme.version !== '2.8.4') throw new Error(`docs expected theme-engine 2.8.4, got ${theme.version}`);
console.log('docs compatibility PASS');
