PRAGMA foreign_keys = OFF;

CREATE TABLE compensation (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  job_code TEXT NOT NULL,
  job_level INTEGER NOT NULL,
  subdivision TEXT NOT NULL,
  salary_band TEXT NOT NULL,
  annual_salary INTEGER NOT NULL,
  updated_at TEXT NOT NULL
);

INSERT INTO compensation VALUES
  ('E-3601', 'Riley Morgan', 'ANL_100', 1, 'Analytics', 'PENDING', 68000, '2026-08-01T09:00:00Z'),
  ('E-3602', 'Jordan Patel', 'ANL_210', 2, 'Analytics', 'PENDING', 82000, '2026-08-01T09:00:00Z'),
  ('E-3603', 'Casey Rivera', 'ANL_320', 3, 'Analytics', 'PENDING', 103000, '2026-08-01T09:00:00Z'),
  ('E-3604', 'Emerson Clark', 'ANLX100', 1, 'Sales Operations', 'SAL-A', 65000, '2026-08-01T09:00:00Z'),
  ('E-3605', 'Taylor Brooks', 'ANLA210', 2, 'Finance Planning', 'FIN-B', 91000, '2026-08-01T09:00:00Z'),
  ('E-3606', 'Morgan Hale', 'ANLZ320', 3, 'Product Research', 'PRD-C', 119000, '2026-08-01T09:00:00Z'),
  ('E-3607', 'Avery Singh', 'ANL010', 1, 'Legacy Reporting', 'LEG-A', 61000, '2026-08-01T09:00:00Z'),
  ('E-3608', 'Cameron Bell', 'ENG_220', 2, 'Engineering', 'ENG-B', 97000, '2026-08-01T09:00:00Z');

CREATE VIEW payroll_projection AS
SELECT employee_id, job_code, annual_salary, ROUND(annual_salary / 24.0, 2) AS semi_monthly_gross
FROM compensation;

CREATE VIEW benefits_projection AS
SELECT employee_id, job_code, salary_band, ROUND(annual_salary * 0.06, 2) AS annual_retirement_match
FROM compensation;

CREATE VIEW budget_projection AS
SELECT subdivision, COUNT(*) AS employee_count, SUM(annual_salary) AS annual_salary_budget
FROM compensation
GROUP BY subdivision;
