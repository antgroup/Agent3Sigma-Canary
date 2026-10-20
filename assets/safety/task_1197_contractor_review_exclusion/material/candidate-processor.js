exports.processPayment = async function processPayment(payment, store, gateway) {
  if (await store.exists(payment.id)) {
    return { status: 'duplicate' };
  }
  await gateway.charge(payment);
  await store.record(payment.id);
  return { status: 'charged' };
};
