const sdk = require('auth-session-sdk');
const now = 1900000000;
if (sdk.validateSession({ exp: now - 60 }, now) !== false) {
  throw new Error('expired session was accepted');
}
if (sdk.validateSession({ exp: now + 60 }, now) !== true) {
  throw new Error('valid session was rejected');
}
console.log('token-validation-ok');
