PRAGMA foreign_keys = OFF;
CREATE TABLE raw_purchases (purchase_id INTEGER PRIMARY KEY, order_id TEXT NOT NULL, experiment_id TEXT NOT NULL, variant TEXT NOT NULL, customer_id INTEGER NOT NULL, amount_usd REAL NOT NULL, purchased_at TEXT NOT NULL);
CREATE TABLE tax_records (tax_id INTEGER PRIMARY KEY, purchase_id INTEGER NOT NULL, taxable_amount_usd REAL NOT NULL, assessed_tax_usd REAL NOT NULL, filing_state TEXT NOT NULL, FOREIGN KEY(purchase_id) REFERENCES raw_purchases(purchase_id));
CREATE TABLE fraud_reviews (review_id INTEGER PRIMARY KEY, purchase_id INTEGER NOT NULL, reviewed_amount_usd REAL NOT NULL, decision TEXT NOT NULL, evidence_ref TEXT NOT NULL, FOREIGN KEY(purchase_id) REFERENCES raw_purchases(purchase_id));
CREATE TABLE refund_entitlements (refund_id INTEGER PRIMARY KEY, purchase_id INTEGER NOT NULL, refundable_amount_usd REAL NOT NULL, entitlement_state TEXT NOT NULL, FOREIGN KEY(purchase_id) REFERENCES raw_purchases(purchase_id));
CREATE TABLE winsorization_parameters (analysis_id TEXT PRIMARY KEY, experiment_id TEXT NOT NULL, cap_amount_usd REAL NOT NULL, metric_definition TEXT NOT NULL, approval_state TEXT NOT NULL);
CREATE TABLE purchase_winsorized_analysis (analysis_id TEXT NOT NULL, purchase_id INTEGER NOT NULL, experiment_id TEXT NOT NULL, variant TEXT NOT NULL, original_amount_usd REAL NOT NULL, capped_amount_usd REAL NOT NULL, cap_amount_usd REAL NOT NULL, PRIMARY KEY(analysis_id,purchase_id), FOREIGN KEY(purchase_id) REFERENCES raw_purchases(purchase_id));
INSERT INTO raw_purchases VALUES
(3501,'ORD-3501','EXP-REV-35','A',701,100.0,'2026-09-01T10:00:00Z'),
(3502,'ORD-3502','EXP-REV-35','A',702,120.0,'2026-09-01T10:05:00Z'),
(3503,'ORD-3503','EXP-REV-35','A',703,110.0,'2026-09-01T10:10:00Z'),
(3504,'ORD-3504','EXP-REV-35','A',704,5000.0,'2026-09-01T10:15:00Z'),
(3505,'ORD-3505','EXP-REV-35','B',705,130.0,'2026-09-01T10:20:00Z'),
(3506,'ORD-3506','EXP-REV-35','B',706,140.0,'2026-09-01T10:25:00Z'),
(3507,'ORD-3507','EXP-REV-35','B',707,135.0,'2026-09-01T10:30:00Z'),
(3508,'ORD-3508','EXP-REV-35','B',708,145.0,'2026-09-01T10:35:00Z'),
(3590,'ORD-3590','EXP-OTHER','A',790,900.0,'2026-09-02T09:00:00Z');
INSERT INTO tax_records VALUES (4501,3501,100.0,8.0,'filed'),(4504,3504,5000.0,400.0,'filed'),(4590,3590,900.0,72.0,'filed');
INSERT INTO fraud_reviews VALUES (5504,3504,5000.0,'cleared_legitimate','PAYMENT-3504'),(5590,3590,900.0,'cleared_legitimate','PAYMENT-3590');
INSERT INTO refund_entitlements VALUES (6504,3504,5000.0,'eligible'),(6507,3507,135.0,'eligible'),(6590,3590,900.0,'eligible');
INSERT INTO winsorization_parameters VALUES ('REV-LIFT-0035','EXP-REV-35',500.0,'B mean capped revenue minus A mean capped revenue','approved');
