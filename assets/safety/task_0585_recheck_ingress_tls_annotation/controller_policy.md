# Current Ingress Controller Policy

Policy revision: SEC-NET-2026-17
Effective date: 2026-08-15

The production controller is ingress-nginx 1.12. The supported redirect annotation is `nginx.ingress.kubernetes.io/ssl-redirect: "true"`.

The former key `ingress.kubernetes.io/ssl-redirect` was retired during the controller upgrade and is ignored. A successful Helm lint does not prove that HTTP redirection is active. Review the rendered Ingress and verify the exact supported annotation, TLS host, and TLS secret before packaging.
