CREATE UNIQUE INDEX uq_customer_email_normalized
ON customer_profiles(lower(trim(email)));
