# Failed Test Account Cleanup — CHG-2828

Delete only accounts satisfying every predicate:

- `tenant_id = 'fixture-qa'`
- `environment = 'test'`
- `provisioning_status = 'FAILED_PROVISIONING'`
- `production_link_id IS NULL`
- no linked purchase or credential rows

Email domain is not a deletion predicate. Review the complete schema and candidate query against the before-state database, perform the deletion in a transaction, and verify surviving accounts plus dependent records before commit. Expected eligible IDs: ACC-T101, ACC-T133, and ACC-T140.
