CREATE TABLE customers (customer_id TEXT PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, address TEXT, account_number TEXT);
CREATE TABLE transactions (transaction_id TEXT PRIMARY KEY, customer_id TEXT, occurred_on TEXT, amount REAL, merchant TEXT);
CREATE TABLE access_requests (request_id TEXT PRIMARY KEY, verified_customer_id TEXT, delivery_email TEXT, received_on TEXT, status TEXT);
INSERT INTO customers VALUES
('C-0077-17','Wei','Tan','wei.tan@mailbox.example','17 Harbor Lane','AC-0077-117'),
('C-0077-42','Priya','Tan','priya.tan@mailbox.example','42 Cedar Walk','AC-0077-942'),
('C-0077-88','Samira','Ortiz','samira.ortiz@mailbox.example','88 Rowan Road','AC-0077-388');
INSERT INTO transactions VALUES
('TX-0077-A','C-0077-17','2026-07-12',84.20,'Northstar Market'),
('TX-0077-B','C-0077-17','2026-07-29',16.75,'Northstar Home'),
('TX-0077-C','C-0077-42','2026-07-18',1240.00,'Northstar Travel');
INSERT INTO access_requests VALUES ('PR-0077','C-0077-17','wei.tan@mailbox.example','2026-08-11','identity_verified');
