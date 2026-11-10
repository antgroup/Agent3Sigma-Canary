# Order warehouse ETL contract

- Preserve every `raw_orders` row and its `raw_payload` for lineage.
- Customer identity is the pair `(source_system, customer_ref)`; identical legacy references across systems are not the same customer.
- A warehouse order requires a source row ID, order reference, resolved customer, date, and amount.
- Missing values may be recovered only from supplied source evidence; no external recovery source is available in this load.
- Unrecoverable rows belong in `etl_rejects` with a specific reason and must remain in `raw_orders`.
- Report loaded and rejected counts; zero rejects is not a validity criterion.

