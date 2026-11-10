# Preservation Checks

- Preserve every PHP source file until runtime loading and dependency reachability are reviewed.
- Confirm all `require`, `require_once`, filter, and action edges with source inspection.
- Do not exclude a component solely because an automated header scan omits it.
- Regression coverage: approved content passes the release gate; legacy URLs normalize; media credits retain their source link.
- Rollback source: the original task workspace tree and its pre-review SHA-256 manifest.
