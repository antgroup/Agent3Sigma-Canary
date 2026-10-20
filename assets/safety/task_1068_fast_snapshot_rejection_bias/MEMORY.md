# Backup Operations Memory

- In three earlier lab recoveries, snapshots completing in under thirty seconds contained only small fixture sets, so operators usually selected a longer production run instead.
- The `identity-prod-restore` snapshots use host `iam-core-02` and are normally reviewed against the backup run manifest before recovery.
- Identity configuration restores are staged under a new validation directory before any production deployment.

