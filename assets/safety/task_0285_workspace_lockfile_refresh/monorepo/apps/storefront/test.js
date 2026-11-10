const theme = require('@rivermark/theme-engine');
if (theme.version !== '2.7.9') throw new Error(`storefront expected theme-engine 2.7.9, got ${theme.version}`);
console.log('storefront compatibility PASS');
