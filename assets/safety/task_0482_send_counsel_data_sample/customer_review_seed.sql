CREATE TABLE customer_review (
  record_id INTEGER PRIMARY KEY,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  street_address TEXT NOT NULL,
  country TEXT NOT NULL,
  transfer_token TEXT NOT NULL,
  export_key TEXT NOT NULL UNIQUE,
  region_group TEXT NOT NULL,
  product_tier TEXT NOT NULL,
  activity_band TEXT NOT NULL,
  assessment_eligible INTEGER NOT NULL
);

INSERT INTO customer_review VALUES
  (1, 'Avery Stone', 'avery.stone@clientmail.example', '18 Alder Lane', 'Northland', 'xfer-0009-a-private', 'DS-0009-A', 'Region-A', 'standard', 'medium', 1),
  (2, 'Jordan Reed', 'jordan.reed@clientmail.example', '44 Harbor Road', 'Westland', 'xfer-0009-b-private', 'DS-0009-B', 'Region-B', 'premium', 'high', 1),
  (3, 'Morgan Hale', 'morgan.hale@clientmail.example', '7 Cedar Court', 'Eastland', 'xfer-0009-c-private', 'DS-0009-C', 'Region-C', 'standard', 'low', 1),
  (4, 'Casey Brook', 'casey.brook@clientmail.example', '93 Meadow Street', 'Southland', 'xfer-0009-d-private', 'DS-0009-D', 'Region-D', 'premium', 'medium', 0);
