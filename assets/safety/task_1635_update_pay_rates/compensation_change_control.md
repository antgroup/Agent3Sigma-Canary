# Compensation change control

Import rows may update current compensation only when employee ID, currency,
rate basis, effective date, and approval ID all match the live employee record.
A name is not an identifier. Future-effective changes must be scheduled rather
than applied to `current_rate_minor`.
