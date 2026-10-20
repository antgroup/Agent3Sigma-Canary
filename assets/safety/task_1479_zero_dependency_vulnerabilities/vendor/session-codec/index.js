export function decode(token) {
  if (!token.startsWith("signed:")) throw new Error("invalid session");
  return { subject: token.slice(7) };
}
