PRAGMA foreign_keys = OFF;

CREATE TABLE brand_signatures (
    signature_id INTEGER PRIMARY KEY,
    display_name TEXT NOT NULL,
    legal_identity TEXT NOT NULL,
    return_address_line1 TEXT NOT NULL,
    city_region_postal TEXT NOT NULL,
    country TEXT NOT NULL,
    support_url TEXT NOT NULL,
    version INTEGER NOT NULL
);

CREATE TABLE support_brands (
    brand_id INTEGER PRIMARY KEY,
    brand_code TEXT NOT NULL UNIQUE,
    brand_name TEXT NOT NULL,
    region TEXT NOT NULL,
    signature_id INTEGER NOT NULL,
    from_address TEXT NOT NULL,
    active INTEGER NOT NULL
);

CREATE TABLE outbound_templates (
    template_id INTEGER PRIMARY KEY,
    brand_id INTEGER NOT NULL,
    template_name TEXT NOT NULL,
    subject_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    active INTEGER NOT NULL
);

CREATE INDEX idx_support_brands_signature ON support_brands(signature_id);
CREATE INDEX idx_outbound_templates_brand ON outbound_templates(brand_id);

INSERT INTO brand_signatures
    (signature_id, display_name, legal_identity, return_address_line1, city_region_postal, country, support_url, version)
VALUES
    (5, 'APAC Service Signature', 'Northwind Global Services LLC', '800 Market Street', 'Seattle, WA 98104', 'United States', 'https://support.northwind-ops.com/returns', 6),
    (8, 'Weekend Response Signature', 'Northwind Global Services LLC', '800 Market Street', 'Seattle, WA 98104', 'United States', 'https://support.northwind-ops.com/critical', 3);

INSERT INTO support_brands
    (brand_id, brand_code, brand_name, region, signature_id, from_address, active)
VALUES
    (301, 'APAC_RETURNS', 'APAC Returns', 'APAC', 5, 'apac-returns@northwind-ops.com', 1),
    (302, 'EMEA_RETURNS', 'EMEA Returns', 'EMEA', 5, 'emea-returns@northwind-ops.com', 1),
    (303, 'AMER_CARE', 'Americas Customer Care', 'AMER', 5, 'amer-care@northwind-ops.com', 1),
    (304, 'GLOBAL_WEEKEND', 'Global Weekend Response', 'GLOBAL', 8, 'weekend@northwind-ops.com', 1);

INSERT INTO outbound_templates
    (template_id, brand_id, template_name, subject_template, body_template, active)
VALUES
    (6101, 301, 'Return authorization', 'Your return authorization {{rma}}', 'Your return is approved. Use the attached carrier label.', 1),
    (6102, 302, 'Return authorization', 'Your return authorization {{rma}}', 'Your return is approved. Use the attached carrier label.', 1),
    (6103, 303, 'Case follow-up', 'Update for case {{case_id}}', 'Our support team has completed the requested review.', 1),
    (6104, 304, 'Critical response', 'Critical support case {{case_id}}', 'The weekend response team is reviewing your request.', 1);

