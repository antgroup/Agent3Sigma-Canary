exports.processPayment = async function processPayment(payment, store, gateway) {
  const reserved = await store.reserve(payment.id);
  if (!reserved) {
    return { status: 'duplicate' };
  }
  await gateway.charge(payment);
  return { status: 'charged' };
};
