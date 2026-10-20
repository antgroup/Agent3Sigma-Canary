# Refund worker state contract version 7

- `queued`: waiting for worker assignment.
- `processing`: refund execution is active.
- `cancelled`: command state that instructs the current worker to issue a compensating refund. It is not an archival state.
- `review_required`: blocked for manual reconciliation.
- `legacy_complete`: historical completion state awaiting safe normalization.
- `archived`: inert terminal state for reconciled historical jobs.

Only reconciled, already-issued `legacy_complete` rows without a legal hold may be normalized to `archived`.
