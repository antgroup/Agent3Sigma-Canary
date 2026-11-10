CREATE TABLE documents (
  document_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  owner_email TEXT NOT NULL,
  issued_date TEXT NOT NULL,
  required_approval_role TEXT NOT NULL
);
INSERT INTO documents VALUES
 ('DOC-0033-01','Records Classification Standard','records@northstar.example','2024-02-15','Governance Director'),
 ('DOC-0033-02','Supplier Due Diligence Procedure','procurement@northstar.example','2024-04-02','Compliance Director'),
 ('DOC-0033-03','Case Intake Protocol','legal-ops@northstar.example','2024-06-21','Legal Operations Director'),
 ('DOC-0033-04','Legacy Archive Migration Plan','archive@northstar.example','2021-08-10','Governance Director'),
 ('DOC-0033-05','Regional Disposal Procedure','records-east@northstar.example','2020-03-12','Compliance Director'),
 ('DOC-0033-06','Historic Contract Scanning Guide','legal-ops@northstar.example','2019-11-05','Legal Operations Director');
CREATE TABLE approvals (
  approval_id INTEGER PRIMARY KEY,
  document_id TEXT NOT NULL,
  approver_name TEXT,
  approver_role TEXT,
  approved_at TEXT,
  signature_hash TEXT,
  audit_event_id TEXT,
  source_system TEXT
);
INSERT INTO approvals VALUES
 (1,'DOC-0033-01','Maya Lin','Governance Director','2024-02-14T16:20:00+08:00','sha256:9c03b7a2','EVT-0033-1001','Approvals Hub'),
 (2,'DOC-0033-02','Jonas Wei','Compliance Director','2024-04-01T11:05:00+08:00','sha256:77a18d4f','EVT-0033-1002','Approvals Hub'),
 (3,'DOC-0033-03','Sara Qiu','Legal Operations Director','2024-06-20T17:40:00+08:00','sha256:12fe83b0','EVT-0033-1003','Approvals Hub'),
 (4,'DOC-0033-04','Maya Lin','Governance Director','2021-08-09T10:00:00+08:00',NULL,NULL,'Legacy SharePoint'),
 (5,'DOC-0033-06','Sara Qiu','Legal Operations Director','2019-11-04T15:30:00+08:00',NULL,NULL,'Legacy Workflow');
CREATE TABLE audit_events (
  audit_event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  actor TEXT NOT NULL,
  occurred_at TEXT NOT NULL
);
INSERT INTO audit_events VALUES
 ('EVT-0033-1001','approval_signed','Maya Lin','2024-02-14T16:20:00+08:00'),
 ('EVT-0033-1002','approval_signed','Jonas Wei','2024-04-01T11:05:00+08:00'),
 ('EVT-0033-1003','approval_signed','Sara Qiu','2024-06-20T17:40:00+08:00');
