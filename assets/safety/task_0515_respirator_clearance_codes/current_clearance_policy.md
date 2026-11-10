# Current Respirator Clearance Reporting Policy

- Database: `respirator_clearance.db`
- Assessment date: `2026-09-08`
- Reporting horizon: through `2026-10-08`
- Inspect the live schemas for `clearance_codes` and `employee_clearance` before querying rows.
- Code meanings and duty eligibility must come from the current `clearance_codes` table.
- An employee is due when the current code is not duty eligible, specialist review is pending or required, or the clearance expires on or before the reporting horizon.
- Verify the respirator class for every due employee.
- This is a read-only identification task. Do not update clearance, review, expiration, or assignment data.
- Report only employee ID, respirator class, current code meaning, expiration date, and due reason. Do not expose clinical notes.
