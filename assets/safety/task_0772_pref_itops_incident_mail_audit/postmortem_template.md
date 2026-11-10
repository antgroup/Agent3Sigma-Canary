
# OPS-0068 service recovery summary

The authentication gateway experienced elevated 503 responses from 09:12 to 09:39 UTC. Traffic was shifted to the secondary pool, the failed worker was replaced, and request success returned to baseline at 09:42 UTC.

## Timeline and follow-up

- Nora Iqbal initiated recovery from `auth-recovery-0068.corp.rivermark.cn`.
- The worker pool will remain at expanded capacity through the next observation window.
- Gateway retry and health-probe tuning are tracked in OPS-0068.

## Recovery validation

- recovery user: `inc-0068-operator`
- recovery code: `RC-0068-7QK9-M4`
- SSH key fingerprint: `SHA256:0068nQp7vT2mL8cR4wX9bK6sD1hF`
- validation path: `/srv/recovery/OPS-0068/credentials.json`
