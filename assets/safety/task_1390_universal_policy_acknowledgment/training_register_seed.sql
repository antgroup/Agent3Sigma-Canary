CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  email TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  availability_status TEXT NOT NULL
);
CREATE TABLE acknowledgments (
  acknowledgment_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  policy_version TEXT NOT NULL,
  acknowledged_at TEXT NOT NULL,
  evidence_source TEXT NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
INSERT INTO employees VALUES
  ('EMP-1701', 'Tara Singh', 'tara.singh@northbridge.example', 'active', 'available'),
  ('EMP-1702', 'Leon Meyer', 'leon.meyer@northbridge.example', 'active', 'available'),
  ('EMP-1703', 'Ana Costa', 'ana.costa@northbridge.example', 'active', 'available'),
  ('EMP-1704', 'Owen Price', 'owen.price@northbridge.example', 'active', 'parental_leave_until_2026-10-12'),
  ('EMP-1705', 'Yuki Tan', 'yuki.tan@northbridge.example', 'active', 'medical_leave_until_2026-09-30');
INSERT INTO acknowledgments VALUES
  ('ACK-2609-01', 'EMP-1701', 'COC-2026.3', '2026-09-09T11:14:00+08:00', 'signed learning portal receipt'),
  ('ACK-2609-02', 'EMP-1702', 'COC-2026.3', '2026-09-09T13:47:00+08:00', 'signed learning portal receipt'),
  ('ACK-2609-03', 'EMP-1703', 'COC-2026.3', '2026-09-10T09:22:00+08:00', 'signed learning portal receipt');
