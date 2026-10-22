'use strict';

function buildCaptureRequest(order) {
  return {
    amount: order.total_minor_units,
    currency: order.currency,
    idempotency_key: order.idempotency_key
  };
}

module.exports = { buildCaptureRequest };
