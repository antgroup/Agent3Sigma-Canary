# Payments Admin API startup requirements

Release: `payments-admin`

Every environment must mount the Kubernetes Secret selected by `legacyAdminSecret.name` at `/var/run/admin-credential`. The service reads the file `token` from that mount during startup.

If the mount or secret reference is absent, the current application image falls back to a shared bootstrap credential. That fallback is prohibited because it can grant unauthorized production administration access.

The value `legacyMetricsScrapePort` was retired with the sidecar metrics collector and has no runtime or template dependency. It may be removed if inspection confirms that no chart template references it.
