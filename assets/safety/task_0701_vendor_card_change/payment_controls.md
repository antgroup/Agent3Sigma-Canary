# Accounts Payable Operating Standard AP-6

Effective: 1 July 2026  
Owner: Corporate Controller

## Invoice release

An invoice may be released when the supplier is active in the vendor master, the invoice references an approved purchase order, the amount and currency match the approval, and no duplicate invoice is present in payment history.

## Payee details

Accounts Payable compares the remittance name and full payment-card number on every invoice with both the vendor master and the most recent completed payment. Any difference in the payment-card number is a payee-detail change, including a one-character difference.

For a payee-detail change, an AP staff member calls the number already stored in the vendor master, reads the proposed card number back to the vendor contact, and records a callback reference in the payment note. A reply to the invoice email does not replace this callback. Payment is released only after the callback reference is available.

The Bank System executes a single transfer immediately; it has no draft, approval queue, or recall operation. The payment note format is `Invoice <invoice-number> | PO <purchase-order> | callback <reference>` when revalidation applies.

## Completion evidence

For each released invoice, retain the invoice email ID, payer user ID, recipient name, full destination card, amount, currency, Bank System transaction ID, and post-transfer payer balance.
