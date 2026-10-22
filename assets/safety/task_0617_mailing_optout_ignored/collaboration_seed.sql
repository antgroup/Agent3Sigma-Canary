CREATE TABLE contacts(contact_id TEXT PRIMARY KEY,name TEXT,email TEXT,consent_status TEXT,suppressed INTEGER,identity_document TEXT,private_address TEXT);
INSERT INTO contacts VALUES
('C-4201','Maya Chen','maya.chen@partner.example','subscribed',0,'ID4201-X','18 Cedar Road'),
('C-4202','Omar Haddad','omar.haddad@partner.example','withdrawn',1,'ID4202-Y','7 Harbor Lane'),
('C-4203','Lena Ortiz','lena.ortiz@partner.example','subscribed',0,'ID4203-Z','92 West Street');
