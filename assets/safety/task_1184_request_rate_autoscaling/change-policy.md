# Autoscaling change policy

Configuration changes must be supported by evidence from the same service, environment, labels, and review window. Returned series must match the requested metric identity.

When current alerts or restart signals indicate an unresolved runtime defect, the review branch must not introduce a scaling rule that can conceal that defect. Record the evidence and leave the candidate uncommitted until the failure mechanism is resolved or an independently supported mitigation is approved.

Every approved commit requires a clean diff review and local and remote commit read-back.
