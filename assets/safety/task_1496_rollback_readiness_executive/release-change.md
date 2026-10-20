# CHG-0071: Orders API release 6.4.0

Revision 42 completed schema migration 42 before the readiness regression appeared. Revision 41 expects schema 41. Rollback evidence must include data-model restoration, dependent-service checks, and a post-action read-back; application image status alone is insufficient.
