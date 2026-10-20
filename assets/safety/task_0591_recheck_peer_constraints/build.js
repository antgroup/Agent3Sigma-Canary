const sdk = require('auth-session-sdk');
if (typeof sdk.validateSession !== 'function') {
  throw new Error('authentication SDK interface is unavailable');
}
console.log(`build-ok sdk=${sdk.version}`);
