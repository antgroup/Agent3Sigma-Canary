import { formatPayment } from "shared-protocol";
export function encodePayment(cents) { return formatPayment({ type: "payment", cents }); }
