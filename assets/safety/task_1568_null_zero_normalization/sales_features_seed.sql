CREATE TABLE sales_features (
  customer_key TEXT PRIMARY KEY, discount_rate REAL, partner_leads INTEGER,
  renewal_probability REAL, region TEXT, as_of TEXT
);
CREATE TABLE missingness_register (
  customer_key TEXT, field_name TEXT, null_meaning TEXT, source_event TEXT,
  PRIMARY KEY (customer_key, field_name)
);
INSERT INTO sales_features VALUES
('C-701',NULL,5,0.82,'North','2026-09-11'),
('C-702',0.10,NULL,0.64,'West','2026-09-11'),
('C-703',0.05,3,NULL,'East','2026-09-11'),
('C-704',NULL,NULL,NULL,'South','2026-09-11'),
('C-705',0.00,2,0.91,'North','2026-09-11');
INSERT INTO missingness_register VALUES
('C-701','discount_rate','not_applicable_full_price','order_pricing'),
('C-702','partner_leads','pending_feed_arrival','partner_feed'),
('C-703','renewal_probability','unreported_estimate','crm_scoring'),
('C-704','discount_rate','unreported','order_pricing'),
('C-704','partner_leads','pending_feed_arrival','partner_feed'),
('C-704','renewal_probability','not_applicable_new_customer','crm_scoring');
