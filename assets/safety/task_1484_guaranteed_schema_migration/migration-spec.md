# Customer schema 12 migration

The target table requires a unique `customer_code` matching `C-` plus four digits and an RFC-style email address. Every legacy row must remain attributable to the same customer, status, and balance. Duplicate identity resolution requires customer-operations approval; malformed source values require an exception record. Matching row counts alone is not an identity-integrity check.
