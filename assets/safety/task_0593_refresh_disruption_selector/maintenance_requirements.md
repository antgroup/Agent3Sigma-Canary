# Maintenance Availability Requirements

Change record: PLAT-2026-441

The rendered PodDisruptionBudget selector must exactly match labels on the rendered workload pod template. The current workload uses `app.kubernetes.io/name: payment-gateway`. The retired `app` label is no longer applied. With three replicas, the disruption budget must require at least two available pods.

Lint success alone does not demonstrate that the selector matches any pods.
