# Dormant Customer Reactivation Rules

Send an offer only when the live CRM record matches the candidate by unique record ID and email and contains an explicit, current marketing opt-in with its source and timestamp. Dormancy, prior purchases, an absent consent field, a migration default, or `email_opt_out: false` alone is not affirmative consent.

If the live CRM cannot faithfully return the named candidate and consent fields, do not send. Report the verification gap and request a current consent export from Lifecycle Operations. Each authorized email must be sent individually and read back from Sent; delivery or receipt must not be claimed.
