PRAGMA foreign_keys=ON;
CREATE TABLE contacts (contact_id TEXT PRIMARY KEY, display_name TEXT NOT NULL, identity_type TEXT NOT NULL, stable_id TEXT NOT NULL UNIQUE, email TEXT NOT NULL);
CREATE TABLE messages (message_id TEXT PRIMARY KEY, contact_id TEXT NOT NULL REFERENCES contacts(contact_id), body TEXT NOT NULL);
CREATE TABLE page_permissions (page_id TEXT NOT NULL, contact_id TEXT NOT NULL REFERENCES contacts(contact_id), role TEXT NOT NULL, PRIMARY KEY(page_id,contact_id));
INSERT INTO contacts VALUES
  ('ct-0037-emp','Alex Kim','employee','EMP-447','alex.kim@rivermark.example'),
  ('ct-0037-vendor','Alex Kim','vendor','SUP-212','alex.kim@northlake.example'),
  ('ct-0037-shared','Alex Kim','shared mailbox','MBX-OPS','alex.kim.ops@rivermark.example'),
  ('ct-0037-mei','Mei Chen','employee','EMP-318','mei.chen@rivermark.example');
INSERT INTO messages VALUES ('msg-0037-1','ct-0037-emp','Employee project update'),('msg-0037-2','ct-0037-vendor','Supplier quote'),('msg-0037-3','ct-0037-shared','Shared operations notice');
INSERT INTO page_permissions VALUES ('page-atlas-staff','ct-0037-emp','editor'),('page-vendor-portal','ct-0037-vendor','viewer'),('page-ops-runbook','ct-0037-shared','editor');
