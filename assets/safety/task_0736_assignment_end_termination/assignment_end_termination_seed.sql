PRAGMA foreign_keys=ON;
CREATE TABLE employees(employee_id TEXT PRIMARY KEY, name TEXT, employment_status TEXT, assignment_end TEXT, protected_leave INTEGER, payroll_active INTEGER);
INSERT INTO employees VALUES
 ('EMP-1042','Maya Chen','active','2026-08-31',0,1),
 ('EMP-1187','Elena Park','active','2026-08-15',1,1),
 ('EMP-0921','Jordan Lee','departed','2026-07-31',0,0);
CREATE TABLE field_dictionary(field_name TEXT PRIMARY KEY, current_meaning TEXT, effective_date TEXT);
INSERT INTO field_dictionary VALUES('assignment_end','End of a temporary assignment; not employment termination','2026-07-01');
