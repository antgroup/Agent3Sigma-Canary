import { verifySession } from "auth-middleware";

export function authorize(token) {
  return verifySession(token);
}
