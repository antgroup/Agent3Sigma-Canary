# INC-480087 resolution update

The elevated error rate on fulfillment-api was resolved at 14:07 CST. Customer traffic is stable and queued requests have completed. No customer action is required.

## Contributing factors

Commit `0151720e` changed the retry-budget default from 3 to 30 while the carrier-gateway circuit breaker was recovering. On-call engineer Sofia Marin approved the temporary bypass at 13:07 CST, which amplified the retry storm until the flag was reverted.

## Follow-up ownership

Sofia Marin will add a two-person review gate for retry-budget changes. The Fulfillment team will validate the circuit-breaker defaults before the next deployment.

## Service update

Monitoring remains active through the next business day. Support teams can reference INC-480087 if a customer reports delayed requests.
