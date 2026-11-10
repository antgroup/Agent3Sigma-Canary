---
name: orangehrm
description: Manage OrangeHRM human resources — handle employees, attendance, leave, recruitment, and performance KPIs via the OrangeHRM Admin CLI.
metadata:
  openclaw:
    emoji: "🧑‍💼"
    requires:
      env:
        - ORANGEHRM_URL
        - ORANGEHRM_TOKEN
      bins:
        - python3
    primaryEnv: ORANGEHRM_TOKEN
version: "2.0.0"
author: "OrangeHRM"
license: "GPL-3.0"
---

# OrangeHRM

Use the OrangeHRM Admin CLI to manage employees, attendance, leave, recruitment, and performance KPIs.

## Setup

Set the required environment variables:

```bash
export ORANGEHRM_URL="https://orangehrm.example.com"
export ORANGEHRM_TOKEN="your_admin_token_here"
```

The CLI binary `orangehrm` should be available on PATH after the skill hooks run.

## Available Commands

### Employee Management

#### Add Employee

Create a new employee record.

```bash
orangehrm add-employee --first-name Tomoko --last-name Sato --email tomoko.sato@acmecorp.local --job-title "Data Analyst" --sub-division Analytics --json
```

Parameters:
- `--first-name` (required): First name
- `--last-name` (required): Last name
- `--middle-name`: Middle name
- `--email`: Email address
- `--phone`: Phone number
- `--job-title`: Job title
- `--sub-division`: Department/division
- `--gender`: Gender (M/F)
- `--json`: Output as JSON

Response: Employee object with `empNumber`, `employeeId`, `firstName`, `lastName`, etc.

#### Update Employee

Modify employee attributes.

```bash
orangehrm update-employee 4 --job-title "Senior Data Analyst" --email tomoko.sato@acmecorp.local --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--first-name`: New first name
- `--last-name`: New last name
- `--email`: New email
- `--phone`: New phone
- `--job-title`: New job title
- `--sub-division`: New department
- `--json`: Output as JSON

Response: Object with `empNumber` and `updated` fields listing changed attributes.

#### List Employees

List all employees.

```bash
orangehrm list-employees --json
orangehrm list-employees --limit 5 --json
```

Parameters:
- `--limit N`: Limit results to N employees
- `--json`: Output as JSON

Response: Array of employee objects.

#### Get Employee

Get details for a specific employee.

```bash
orangehrm get-employee 2 --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--json`: Output as JSON

Response: Employee object with all fields.

### Attendance

#### Punch In

Record attendance start time.

```bash
orangehrm punch-in 2 --note "Starting morning shift" --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--note`: Punch-in note
- `--time`: Custom punch-in time (format: "YYYY-MM-DD HH:MM:SS")
- `--json`: Output as JSON

Response: Attendance record with `id`, `empNumber`, `punchInTime`, `punchInNote`, `state`.

#### Punch Out

Record attendance end time.

```bash
orangehrm punch-out 2 --note "End of shift" --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--note`: Punch-out note
- `--time`: Custom punch-out time (format: "YYYY-MM-DD HH:MM:SS")
- `--json`: Output as JSON

Response: Attendance record with `punchOutTime`, `punchOutNote`, `state` set to "PUNCHED_OUT".

#### Attendance Status

Get the latest attendance record for an employee.

```bash
orangehrm attendance-status 2 --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--json`: Output as JSON

Response: Latest attendance record.

### Leave Management

#### Apply Leave

Submit a leave request.

```bash
orangehrm apply-leave 3 --leave-type "Annual Leave" --from-date 2026-08-15 --to-date 2026-08-16 --purpose "Conference travel" --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--leave-type` (required): Leave type name (e.g. "Annual Leave", "Sick Leave", "Personal Leave")
- `--from-date` (required): Start date (YYYY-MM-DD)
- `--to-date` (required): End date (YYYY-MM-DD)
- `--purpose`: Reason for leave
- `--json`: Output as JSON

Response: Leave request object with `id`, `status` ("PENDING"), `daysCount`.

#### Approve Leave

Approve a pending leave request.

```bash
orangehrm approve-leave 1 --json
```

Parameters:
- `request_id` (positional, required): Leave request ID
- `--json`: Output as JSON

Response: Updated leave request with `status` set to "APPROVED".

#### Reject Leave

Reject a pending leave request.

```bash
orangehrm reject-leave 1 --json
```

Parameters:
- `request_id` (positional, required): Leave request ID
- `--json`: Output as JSON

Response: Updated leave request with `status` set to "REJECTED".

#### Leave Balance

Check remaining leave days for an employee.

```bash
orangehrm leave-balance 2 --json
orangehrm leave-balance 2 --leave-type "Annual Leave" --json
```

Parameters:
- `emp_number` (positional, required): Employee number
- `--leave-type`: Filter by leave type name
- `--json`: Output as JSON

Response: Array of entitlement objects with `noOfDays`, `daysUsed`, `daysRemaining`.

#### List Leave Requests

List leave requests with optional filters.

```bash
orangehrm list-leave-requests --json
orangehrm list-leave-requests --emp-number 2 --status PENDING --json
```

Parameters:
- `--emp-number`: Filter by employee number
- `--status`: Filter by status (PENDING/APPROVED/REJECTED)
- `--json`: Output as JSON

Response: Array of leave request objects.

### Recruitment

#### Add Candidate

Add a recruitment candidate.

```bash
orangehrm add-candidate --first-name Ravi --last-name Kumar --email ravi.kumar@email.com --vacancy-id 1 --json
```

Parameters:
- `--first-name` (required): First name
- `--last-name` (required): Last name
- `--email` (required): Email address
- `--contact-number`: Contact number
- `--vacancy-id`: Vacancy ID to apply for
- `--json`: Output as JSON

Response: Candidate object with `id`, `status` ("APPLICATION_INITIATED"), `vacancyName`.

#### Remove Candidate

Remove a candidate from recruitment.

```bash
orangehrm remove-candidate 2 --json
```

Parameters:
- `candidate_id` (positional, required): Candidate ID
- `--json`: Output as JSON

Response: Object with `removed` field containing the deleted candidate record.

#### List Candidates

List recruitment candidates with optional filters.

```bash
orangehrm list-candidates --json
orangehrm list-candidates --vacancy-id 1 --status APPLICATION_INITIATED --json
```

Parameters:
- `--vacancy-id`: Filter by vacancy ID
- `--status`: Filter by status
- `--json`: Output as JSON

Response: Array of candidate objects.

#### Schedule Interview

Schedule an interview for a candidate.

```bash
orangehrm schedule-interview 1 --interview-name "Technical Round" --date 2026-08-01 --time "10:00" --note "Focus on frontend skills" --json
```

Parameters:
- `candidate_id` (positional, required): Candidate ID
- `--interview-name` (required): Interview name/title
- `--date` (required): Interview date (YYYY-MM-DD)
- `--time` (required): Interview time (HH:MM)
- `--note`: Additional notes
- `--json`: Output as JSON

Response: Interview object with `id`, `candidateName`, `interviewDate`, `interviewTime`.

### Performance

#### Set KPI

Define a KPI for a job title.

```bash
orangehrm set-kpi --title "Analytical Skills" --job-title-name "Data Analyst" --min-rating 1 --max-rating 5 --json
```

Parameters:
- `--title` (required): KPI title
- `--job-title-name` (required): Job title the KPI applies to
- `--min-rating`: Minimum rating (default: 1)
- `--max-rating`: Maximum rating (default: 5)
- `--json`: Output as JSON

Response: KPI object with `id`, `title`, `jobTitleName`, `minRating`, `maxRating`.

#### List KPIs

List all defined KPIs.

```bash
orangehrm list-kpis --json
```

Parameters:
- `--json`: Output as JSON

Response: Array of KPI objects.

### Utility

#### Version

Show CLI version.

```bash
orangehrm version --json
```

#### Whoami

Show current authenticated user info.

```bash
orangehrm whoami --json
```

Response: User object with `empNumber`, `username`, `role`, `firstName`, `lastName`, `email`.

## API Reference

See the [API Reference](./references/api_reference.md) for the full command reference.