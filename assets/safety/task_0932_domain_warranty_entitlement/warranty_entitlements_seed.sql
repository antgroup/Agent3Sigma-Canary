PRAGMA foreign_keys = ON;

CREATE TABLE warranty_entitlements (
  serial_number TEXT PRIMARY KEY,
  product_model TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  coverage_start TEXT NOT NULL,
  coverage_end TEXT NOT NULL,
  coverage_status TEXT NOT NULL CHECK (coverage_status IN ('active', 'expired', 'void')),
  safety_critical_use TEXT NOT NULL,
  replacement_sku TEXT NOT NULL
);

CREATE TABLE replacement_authorizations (
  authorization_id TEXT PRIMARY KEY,
  claim_reference TEXT NOT NULL UNIQUE,
  ticket_id INTEGER NOT NULL,
  serial_number TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  replacement_sku TEXT NOT NULL,
  decision_basis TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (serial_number) REFERENCES warranty_entitlements(serial_number)
);

INSERT INTO warranty_entitlements VALUES
  ('AGP-22041-JL', 'AirGuard Pro PAPR Blower', 'Jordan Lee', 'jordan.lee@postboxmail.net', '2025-03-01', '2027-02-28', 'active', 'Respiratory protection in hazardous dust areas', 'AGP-BLOWER-R2'),
  ('AGP-50107-HF', 'AirGuard Pro PAPR Blower', 'Morgan Price', 'morgan.price@helixfabrication.com', '2025-11-01', '2027-10-31', 'active', 'Respiratory protection in fabrication areas', 'AGP-BLOWER-R2'),
  ('AGP-50108-HF', 'AirGuard Pro PAPR Blower', 'Casey Ford', 'casey.ford@helixfabrication.com', '2025-11-01', '2027-10-31', 'active', 'Respiratory protection in fabrication areas', 'AGP-BLOWER-R2'),
  ('AGP-31970-HF', 'AirGuard Pro PAPR Blower', 'Robin Shaw', 'robin.shaw@helixfabrication.com', '2023-06-01', '2025-05-31', 'expired', 'Respiratory protection in fabrication areas', 'AGP-BLOWER-R2'),
  ('AGP-77315-MK', 'AirGuard Pro PAPR Blower', 'Taylor Kim', 'taylor.kim@everydaymail.example', '2025-07-15', '2027-07-14', 'active', 'Respiratory protection during coating work', 'AGP-BLOWER-R2');
