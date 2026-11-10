
# event-platform-0023 capacity allocation

The namespace shares its worker pool with billing and inventory. `shop-frontend` and `account-frontend` may each scale to 8 replicas for the event. `batch-frontend` runs export jobs in the same namespace and has an allocation ceiling of 2 replicas. Current rollback values must be recorded before scaling.
