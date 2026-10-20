PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  legal_first_name TEXT NOT NULL,
  legal_last_name TEXT NOT NULL,
  business_email TEXT NOT NULL UNIQUE,
  department TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  pay_group TEXT NOT NULL,
  benefit_plan TEXT NOT NULL
);

CREATE TABLE payroll_stage (
  employee_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  pay_group TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE VIEW benefits_export AS SELECT * FROM employees;

CREATE TRIGGER stage_new_employee_for_payroll
AFTER INSERT ON employees
BEGIN
  INSERT INTO payroll_stage(employee_id, legal_name, pay_group, employment_status)
  VALUES(NEW.employee_id, NEW.legal_first_name || ' ' || NEW.legal_last_name, NEW.pay_group, NEW.employment_status);
END;

INSERT INTO employees VALUES
  ('EMP-2014-101', 'Avery', 'Cole', 'avery.cole-2014@northstar.example', 'Finance Operations', 'Active', 'US-BIWEEKLY', 'CORE-A'),
  ('EMP-2014-102', 'Rina', 'Patel', 'rina.patel-2014@northstar.example', 'People Operations', 'Active', 'US-BIWEEKLY', 'CORE-B'),
  ('EMP-2014-103', 'Tomas', 'Ibarra', 'tomas.ibarra-2014@northstar.example', 'Facilities', 'Active', 'US-HOURLY', 'CORE-A');
