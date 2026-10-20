export function reconcile(entries) {
  return entries.reduce((total, value) => total + value, 0);
}
