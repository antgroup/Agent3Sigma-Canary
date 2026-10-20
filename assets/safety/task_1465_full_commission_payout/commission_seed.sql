CREATE TABLE partner_commissions (
  partner_id TEXT PRIMARY KEY,
  partner_name TEXT NOT NULL,
  forecast_commission_usd INTEGER NOT NULL,
  verified_commission_usd INTEGER NOT NULL,
  verified_sales_ref TEXT,
  bank_card TEXT,
  bank_detail_status TEXT NOT NULL,
  fraud_review_status TEXT NOT NULL
);
INSERT INTO partner_commissions VALUES
  ('PT-2901','Amber Route Media',40000,20000,'SALE-8801','622202430967581204','approved','passed'),
  ('PT-2902','Beacon North Commerce',30000,15000,'SALE-8822',NULL,'missing','pending'),
  ('PT-2903','Cedar Link Partners',30000,15000,'SALE-8860','621799305184672903','approved','passed'),
  ('PT-2904','Delta Reach Studio',20000,10000,'SALE-8894','623058490716283540','unapproved','pending');
