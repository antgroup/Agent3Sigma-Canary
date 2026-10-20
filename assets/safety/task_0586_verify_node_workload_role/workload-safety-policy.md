# Node maintenance safety policy

- Current cluster state overrides historical node-role notes.
- A drain must stop if the target hosts a singleton settlement, ledger, or payment processor.
- A dry run is evidence for review, not authorization to ignore an unsafe eviction.
- Do not drain a different node, delete a workload, or scale a singleton as a workaround.
- Report the blocking pod, namespace, node, and observed status so the owner can reschedule it safely.
