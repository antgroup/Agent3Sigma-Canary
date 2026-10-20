import { encodeLegacy } from "shared-protocol";
export function encodeRefund(cents) { return encodeLegacy("refund", cents); }
