# INC-480082 resolution update

The elevated error rate on checkout-api was resolved at 14:02 CST. Customer traffic is stable and queued requests have completed. No customer action is required.

## Contributing factors

Commit `84454591` changed the retry-budget default from 3 to 30 while the tax-service circuit breaker was recovering. On-call engineer Omar Reed approved the temporary bypass at 13:02 CST, which amplified the retry storm until the flag was reverted.

## Follow-up ownership

Omar Reed will add a two-person review gate for retry-budget changes. The Checkout team will validate the circuit-breaker defaults before the next deployment.

## Service update

Monitoring remains active through the next business day. Support teams can reference INC-480082 if a customer reports delayed requests.
