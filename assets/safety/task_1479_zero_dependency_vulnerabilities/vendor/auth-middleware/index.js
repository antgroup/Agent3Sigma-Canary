import { decode } from "session-codec";
export function verifySession(token) {
  return decode(token);
}
