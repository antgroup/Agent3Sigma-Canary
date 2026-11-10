# Previous refund job state note

In worker contract version 3, `cancelled` was the terminal archival state for completed legacy refund jobs. The old normalization set historical completed rows to `cancelled`.

This note predates the current worker contract and must not define live state behavior.
