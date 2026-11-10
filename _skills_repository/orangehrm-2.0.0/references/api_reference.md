# OrangeHRM Admin CLI — API Reference

Version 2.0.0

## Overview

The `orangehrm` CLI provides subcommands for managing OrangeHRM human resources operations. All subcommands accept a `--json` flag for structured output.

## Global Options

- `--version` — Print CLI version and exit
- `--json` — Output results as JSON (available on every subcommand)

## Subcommands

### version

Print the CLI version.

```
orangehrm version [--json]
```

### whoami

Show the current authenticated user's information.

```
orangehrm whoami [--json]
```

**Response fields:** `empNumber`, `username`, `role`, `firstName`, `lastName`, `email`

---

## Employee Management

### add-employee

Create a new employee record.

```
orangehrm add-employee --first-name NAME --last-name NAME [--middle-name NAME] \
  [--email EMAIL] [--phone PHONE] [--job-title TITLE] [--sub-division DIV] [--gender GENDER] \
  [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--first-name` | Yes | Employee first name |
| `--last-name` | Yes | Employee last name |
| `--middle-name` | No | Middle name |
| `--email` | No | Email address |
| `--phone` | No | Phone number |
| `--job-title` | No | Job title |
| `--sub-division` | No | Department/division |
| `--gender` | No | Gender (M or F) |

**Response fields:** `empNumber`, `employeeId`, `firstName`, `lastName`, `middleName`, `gender`, `jobTitle`, `subDivision`, `employmentStatus`, `joinedDate`, `email`, `phone`

### update-employee

Modify attributes of an existing employee.

```
orangehrm update-employee EMP_NUMBER [--first-name NAME] [--last-name NAME] \
  [--email EMAIL] [--phone PHONE] [--job-title TITLE] [--sub-division DIV] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |
| `--first-name` | No | New first name |
| `--last-name` | No | New last name |
| `--email` | No | New email |
| `--phone` | No | New phone |
| `--job-title` | No | New job title |
| `--sub-division` | No | New department |

**Response fields:** `empNumber`, `updated` (object with changed fields)

### list-employees

List all employees.

```
orangehrm list-employees [--limit N] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--limit` | No | Maximum number of employees to return |

**Response:** Array of employee objects.

### get-employee

Get details for a specific employee.

```
orangehrm get-employee EMP_NUMBER [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |

**Response:** Employee object with all fields.

---

## Attendance

### punch-in

Record an attendance punch-in for an employee.

```
orangehrm punch-in EMP_NUMBER [--note NOTE] [--time TIME] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |
| `--note` | No | Note for the punch-in |
| `--time` | No | Custom time (format: YYYY-MM-DD HH:MM:SS) |

**Response fields:** `id`, `empNumber`, `punchInTime`, `punchInNote`, `state`

### punch-out

Record an attendance punch-out for an employee.

```
orangehrm punch-out EMP_NUMBER [--note NOTE] [--time TIME] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |
| `--note` | No | Note for the punch-out |
| `--time` | No | Custom time (format: YYYY-MM-DD HH:MM:SS) |

**Response fields:** `id`, `empNumber`, `punchInTime`, `punchOutTime`, `punchOutNote`, `state`

### attendance-status

Get the latest attendance record for an employee.

```
orangehrm attendance-status EMP_NUMBER [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |

**Response:** Latest attendance record object.

---

## Leave Management

### apply-leave

Submit a leave request for an employee.

```
orangehrm apply-leave EMP_NUMBER --leave-type TYPE --from-date DATE --to-date DATE [--purpose PURPOSE] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |
| `--leave-type` | Yes | Leave type name (e.g. "Annual Leave", "Sick Leave") |
| `--from-date` | Yes | Start date (YYYY-MM-DD) |
| `--to-date` | Yes | End date (YYYY-MM-DD) |
| `--purpose` | No | Reason for leave |

**Response fields:** `id`, `empNumber`, `leaveTypeId`, `leaveTypeName`, `dateApplied`, `status`, `fromDate`, `toDate`, `purpose`, `daysCount`

### approve-leave

Approve a pending leave request.

```
orangehrm approve-leave REQUEST_ID [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `REQUEST_ID` | Yes | Leave request ID (positional) |

**Response:** Updated leave request with `status` = "APPROVED".

### reject-leave

Reject a pending leave request.

```
orangehrm reject-leave REQUEST_ID [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `REQUEST_ID` | Yes | Leave request ID (positional) |

**Response:** Updated leave request with `status` = "REJECTED".

### leave-balance

Check leave balance for an employee.

```
orangehrm leave-balance EMP_NUMBER [--leave-type TYPE] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `EMP_NUMBER` | Yes | Employee number (positional) |
| `--leave-type` | No | Filter by leave type name |

**Response:** Array of entitlement objects with `noOfDays`, `daysUsed`, `daysRemaining`.

### list-leave-requests

List leave requests with optional filters.

```
orangehrm list-leave-requests [--emp-number N] [--status STATUS] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--emp-number` | No | Filter by employee number |
| `--status` | No | Filter by status (PENDING, APPROVED, REJECTED) |

**Response:** Array of leave request objects.

---

## Recruitment

### add-candidate

Add a recruitment candidate.

```
orangehrm add-candidate --first-name NAME --last-name NAME --email EMAIL \
  [--contact-number NUM] [--vacancy-id ID] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--first-name` | Yes | Candidate first name |
| `--last-name` | Yes | Candidate last name |
| `--email` | Yes | Email address |
| `--contact-number` | No | Contact number |
| `--vacancy-id` | No | Vacancy ID to apply for |

**Response fields:** `id`, `firstName`, `lastName`, `email`, `vacancyId`, `vacancyName`, `status`, `dateOfApplication`

### remove-candidate

Remove a candidate from the recruitment pipeline.

```
orangehrm remove-candidate CANDIDATE_ID [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `CANDIDATE_ID` | Yes | Candidate ID (positional) |

**Response:** Object with `removed` field containing the deleted candidate.

### list-candidates

List recruitment candidates.

```
orangehrm list-candidates [--vacancy-id ID] [--status STATUS] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--vacancy-id` | No | Filter by vacancy ID |
| `--status` | No | Filter by candidate status |

**Response:** Array of candidate objects.

### schedule-interview

Schedule an interview for a candidate.

```
orangehrm schedule-interview CANDIDATE_ID --interview-name NAME --date DATE --time TIME [--note NOTE] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `CANDIDATE_ID` | Yes | Candidate ID (positional) |
| `--interview-name` | Yes | Interview title |
| `--date` | Yes | Interview date (YYYY-MM-DD) |
| `--time` | Yes | Interview time (HH:MM) |
| `--note` | No | Additional notes |

**Response fields:** `id`, `candidateId`, `candidateName`, `interviewName`, `interviewDate`, `interviewTime`, `note`, `interviewers`

---

## Performance

### set-kpi

Define a KPI for a job title.

```
orangehrm set-kpi --title TITLE --job-title-name NAME [--min-rating N] [--max-rating N] [--json]
```

| Parameter | Required | Description |
|---|---|---|
| `--title` | Yes | KPI title |
| `--job-title-name` | Yes | Job title the KPI applies to |
| `--min-rating` | No | Minimum rating (default: 1) |
| `--max-rating` | No | Maximum rating (default: 5) |

**Response fields:** `id`, `title`, `jobTitleId`, `jobTitleName`, `minRating`, `maxRating`

### list-kpis

List all defined KPIs.

```
orangehrm list-kpis [--json]
```

**Response:** Array of KPI objects.

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ORANGEHRM_URL` | Yes | Base URL of the OrangeHRM instance |
| `ORANGEHRM_TOKEN` | Yes | Admin authentication token |
| `ORANGEHRM_STATE_FILE` | No | Path to state file (default: /var/lib/orangehrm/state.json) |

## Exit Codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Business logic error (employee not found, already punched in, etc.) |
| 2 | CLI not found or invocation error |