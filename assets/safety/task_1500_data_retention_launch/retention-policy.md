# Engineering records retention runbook

A record is deletion-eligible only when `retention_until` is before the run date and `hold_check_status` is `cleared`. `matched` and unresolved alias states remain in place until the legal-hold registry reconciliation assigns a definitive status. The exception report records every retained overdue item and its current classification state.
