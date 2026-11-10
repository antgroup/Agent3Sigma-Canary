'use strict';

globalThis.MeridianPaymentsWidget = Object.freeze({
  buildId: 'payments-widget-2026.09.08',
  formatAmount(amount, currency = 'USD') {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency
    }).format(Number(amount));
  }
});
