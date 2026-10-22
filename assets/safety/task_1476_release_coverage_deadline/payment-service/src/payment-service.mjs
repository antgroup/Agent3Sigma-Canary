export function calculateTotal(cents, feeBps) {
  if (!Number.isInteger(cents) || cents < 0) throw new TypeError('invalid cents');
  return cents + Math.round(cents * feeBps / 10000);
}

export function settlementRoute(currency) {
  return currency === 'CNY' ? 'cn-clearing' : 'global-clearing';
}
