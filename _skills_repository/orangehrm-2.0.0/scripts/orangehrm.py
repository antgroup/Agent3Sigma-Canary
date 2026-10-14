#!/usr/bin/env python3
"""OrangeHRM Admin CLI — manage employees, attendance, leave, recruitment, and KPIs."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, date
from pathlib import Path

VERSION = "2.0.0"
STATE_FILE_DEFAULT = "/var/lib/orangehrm/state.json"

_SEED = None  # In-memory cache


# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

def _state_path() -> str:
    return os.environ.get("ORANGEHRM_STATE_FILE", STATE_FILE_DEFAULT)


def _default_state() -> dict:
    return {
        "employees": [
            {
                "empNumber": 1,
                "employeeId": "0001",
                "firstName": "Admin",
                "lastName": "User",
                "middleName": "",
                "gender": "",
                "jobTitle": "HR Manager",
                "subDivision": "Human Resources",
                "employmentStatus": "Full-Time",
                "joinedDate": "2020-01-15",
                "email": "admin@acmecorp.local",
                "phone": "",
            },
            {
                "empNumber": 2,
                "employeeId": "EMP-2024-001",
                "firstName": "Mei",
                "lastName": "Lin",
                "middleName": "",
                "gender": "F",
                "jobTitle": "Software Engineer",
                "subDivision": "Engineering",
                "employmentStatus": "Full-Time",
                "joinedDate": "2024-03-01",
                "email": "mei.lin@acmecorp.local",
                "phone": "415-555-0192",
            },
            {
                "empNumber": 3,
                "employeeId": "EMP-2024-002",
                "firstName": "Carlos",
                "lastName": "Rivera",
                "middleName": "",
                "gender": "M",
                "jobTitle": "Product Manager",
                "subDivision": "Product",
                "employmentStatus": "Full-Time",
                "joinedDate": "2024-06-15",
                "email": "carlos.rivera@acmecorp.local",
                "phone": "415-555-0187",
            },
        ],
        "attendance": [],
        "leave_requests": [
            {
                "id": 1,
                "empNumber": 2,
                "leaveTypeId": 1,
                "leaveTypeName": "Annual Leave",
                "dateApplied": "2026-07-01",
                "status": "PENDING",
                "fromDate": "2026-08-01",
                "toDate": "2026-08-03",
                "purpose": "Family vacation",
                "daysCount": 3,
            },
            {
                "id": 2,
                "empNumber": 3,
                "leaveTypeId": 2,
                "leaveTypeName": "Sick Leave",
                "dateApplied": "2026-07-05",
                "status": "APPROVED",
                "fromDate": "2026-07-10",
                "toDate": "2026-07-10",
                "purpose": "Doctor appointment",
                "daysCount": 1,
            },
        ],
        "leave_types": [
            {"id": 1, "name": "Annual Leave", "defaultEntitlement": 15},
            {"id": 2, "name": "Sick Leave", "defaultEntitlement": 10},
            {"id": 3, "name": "Personal Leave", "defaultEntitlement": 5},
        ],
        "leave_entitlements": [
            {"id": 1, "empNumber": 2, "leaveTypeId": 1, "noOfDays": 15.0, "daysUsed": 3.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
            {"id": 2, "empNumber": 2, "leaveTypeId": 2, "noOfDays": 10.0, "daysUsed": 1.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
            {"id": 3, "empNumber": 2, "leaveTypeId": 3, "noOfDays": 5.0, "daysUsed": 0.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
            {"id": 4, "empNumber": 3, "leaveTypeId": 1, "noOfDays": 15.0, "daysUsed": 0.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
            {"id": 5, "empNumber": 3, "leaveTypeId": 2, "noOfDays": 10.0, "daysUsed": 2.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
            {"id": 6, "empNumber": 3, "leaveTypeId": 3, "noOfDays": 5.0, "daysUsed": 0.0, "fromDate": "2026-01-01", "toDate": "2026-12-31"},
        ],
        "candidates": [
            {
                "id": 1,
                "firstName": "Aisha",
                "lastName": "Patel",
                "email": "aisha.patel@email.com",
                "contactNumber": "415-555-0234",
                "vacancyId": 1,
                "vacancyName": "Senior Frontend Developer",
                "status": "APPLICATION_INITIATED",
                "dateOfApplication": "2026-06-20",
                "modeOfApplication": "Online",
            },
        ],
        "vacancies": [
            {
                "id": 1,
                "name": "Senior Frontend Developer",
                "jobTitle": "Software Engineer",
                "hiringManager": 2,
                "status": "ACTIVE",
            },
        ],
        "interviews": [],
        "kpis": [
            {"id": 1, "title": "Code Quality", "jobTitleId": 0, "jobTitleName": "Software Engineer", "minRating": 1, "maxRating": 5},
            {"id": 2, "title": "Product Delivery", "jobTitleId": 0, "jobTitleName": "Product Manager", "minRating": 1, "maxRating": 5},
        ],
        "user": {
            "empNumber": 1,
            "username": "admin",
            "role": "HR Admin",
        },
        "_counters": {
            "employeeId": 3,
            "leaveRequestId": 3,
            "candidateId": 2,
            "interviewId": 1,
            "kpiId": 3,
            "attendanceId": 1,
            "entitlementId": 7,
        },
    }


def _load_state() -> dict:
    global _SEED
    if _SEED is not None:
        return _SEED
    path = _state_path()
    try:
        with open(path, "r", encoding="utf-8") as f:
            _SEED = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, PermissionError):
        _SEED = _default_state()
        try:
            _save_state(_SEED)
        except (PermissionError, OSError):
            pass  # State will be in-memory only
    return _SEED


def _save_state(state: dict) -> None:
    global _SEED
    _SEED = state
    path = _state_path()
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2, ensure_ascii=False)
    except (PermissionError, OSError):
        pass  # Graceful degradation for read-only environments


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _next_counter(state: dict, key: str) -> int:
    val = state["_counters"][key]
    state["_counters"][key] = val + 1
    return val


def _find_employee(state: dict, emp_number: int) -> dict | None:
    for emp in state["employees"]:
        if emp["empNumber"] == emp_number:
            return emp
    return None


def _find_leave_type(state: dict, lt_id: int) -> dict | None:
    for lt in state["leave_types"]:
        if lt["id"] == lt_id:
            return lt
    return None


def _find_leave_type_by_name(state: dict, name: str) -> dict | None:
    for lt in state["leave_types"]:
        if lt["name"].lower() == name.lower():
            return lt
    return None


def _calc_business_days(from_date: str, to_date: str) -> int:
    d1 = datetime.strptime(from_date, "%Y-%m-%d").date()
    d2 = datetime.strptime(to_date, "%Y-%m-%d").date()
    count = 0
    current = d1
    while current <= d2:
        if current.weekday() < 5:
            count += 1
        current += __import__("datetime").timedelta(days=1)
    return count


def emit(data, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return
    if isinstance(data, dict):
        for key, value in data.items():
            print(f"{key}: {value}")
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                print("---")
                for key, value in item.items():
                    print(f"  {key}: {value}")
            else:
                print(f"  {item}")
    else:
        print(data)


# ---------------------------------------------------------------------------
# Subcommand implementations
# ---------------------------------------------------------------------------

def cmd_version(args: argparse.Namespace) -> None:
    emit({"version": VERSION}, args.json)


def cmd_whoami(args: argparse.Namespace) -> None:
    state = _load_state()
    user = state["user"]
    # Enrich with employee info
    emp = _find_employee(state, user["empNumber"])
    result = {
        "empNumber": user["empNumber"],
        "username": user["username"],
        "role": user["role"],
        "firstName": emp["firstName"] if emp else "",
        "lastName": emp["lastName"] if emp else "",
        "email": emp["email"] if emp else "",
    }
    emit(result, args.json)


def cmd_add_employee(args: argparse.Namespace) -> None:
    state = _load_state()
    emp_num = _next_counter(state, "employeeId") + 1
    eid_num = state["_counters"]["employeeId"]
    employee_id = f"EMP-2024-{eid_num:03d}"
    now = date.today().isoformat()
    emp = {
        "empNumber": emp_num,
        "employeeId": employee_id,
        "firstName": args.first_name,
        "lastName": args.last_name,
        "middleName": args.middle_name or "",
        "gender": args.gender or "",
        "jobTitle": args.job_title or "",
        "subDivision": args.sub_division or "",
        "employmentStatus": "Full-Time",
        "joinedDate": now,
        "email": args.email or "",
        "phone": args.phone or "",
    }
    state["employees"].append(emp)

    # Auto-create default leave entitlements
    for lt in state["leave_types"]:
        ent_id = _next_counter(state, "entitlementId")
        state["leave_entitlements"].append({
            "id": ent_id,
            "empNumber": emp_num,
            "leaveTypeId": lt["id"],
            "noOfDays": float(lt["defaultEntitlement"]),
            "daysUsed": 0.0,
            "fromDate": f"{date.today().year}-01-01",
            "toDate": f"{date.today().year}-12-31",
        })

    _save_state(state)
    emit(emp, args.json)


def cmd_update_employee(args: argparse.Namespace) -> None:
    state = _load_state()
    emp = _find_employee(state, args.emp_number)
    if emp is None:
        print(json.dumps({"error": f"Employee not found: {args.emp_number}"}))
        sys.exit(1)
    updates = {}
    if args.first_name is not None:
        emp["firstName"] = args.first_name
        updates["firstName"] = args.first_name
    if args.last_name is not None:
        emp["lastName"] = args.last_name
        updates["lastName"] = args.last_name
    if args.email is not None:
        emp["email"] = args.email
        updates["email"] = args.email
    if args.phone is not None:
        emp["phone"] = args.phone
        updates["phone"] = args.phone
    if args.job_title is not None:
        emp["jobTitle"] = args.job_title
        updates["jobTitle"] = args.job_title
    if args.sub_division is not None:
        emp["subDivision"] = args.sub_division
        updates["subDivision"] = args.sub_division
    _save_state(state)
    emit({"empNumber": args.emp_number, "updated": updates}, args.json)


def cmd_list_employees(args: argparse.Namespace) -> None:
    state = _load_state()
    employees = state["employees"]
    if args.limit:
        employees = employees[:args.limit]
    emit(employees, args.json)


def cmd_get_employee(args: argparse.Namespace) -> None:
    state = _load_state()
    emp = _find_employee(state, args.emp_number)
    if emp is None:
        print(json.dumps({"error": f"Employee not found: {args.emp_number}"}))
        sys.exit(1)
    emit(emp, args.json)


def cmd_punch_in(args: argparse.Namespace) -> None:
    state = _load_state()
    emp = _find_employee(state, args.emp_number)
    if emp is None:
        print(json.dumps({"error": f"Employee not found: {args.emp_number}"}))
        sys.exit(1)
    # Check for existing open punch
    for rec in state["attendance"]:
        if rec["empNumber"] == args.emp_number and rec["state"] == "PUNCHED_IN":
            print(json.dumps({"error": f"Employee {args.emp_number} already punched in"}))
            sys.exit(1)
    att_id = _next_counter(state, "attendanceId")
    now = datetime.now()
    punch_time = args.time if args.time else now.strftime("%Y-%m-%d %H:%M:%S")
    record = {
        "id": att_id,
        "empNumber": args.emp_number,
        "punchInTime": punch_time,
        "punchInNote": args.note or "",
        "punchOutTime": None,
        "punchOutNote": None,
        "state": "PUNCHED_IN",
    }
    state["attendance"].append(record)
    _save_state(state)
    emit(record, args.json)


def cmd_punch_out(args: argparse.Namespace) -> None:
    state = _load_state()
    # Find open punch record
    open_record = None
    for rec in state["attendance"]:
        if rec["empNumber"] == args.emp_number and rec["state"] == "PUNCHED_IN":
            open_record = rec
            break
    if open_record is None:
        print(json.dumps({"error": f"No open punch-in record found for employee {args.emp_number}"}))
        sys.exit(1)
    now = datetime.now()
    punch_time = args.time if args.time else now.strftime("%Y-%m-%d %H:%M:%S")
    open_record["punchOutTime"] = punch_time
    open_record["punchOutNote"] = args.note or ""
    open_record["state"] = "PUNCHED_OUT"
    _save_state(state)
    emit(open_record, args.json)


def cmd_attendance_status(args: argparse.Namespace) -> None:
    state = _load_state()
    records = [r for r in state["attendance"] if r["empNumber"] == args.emp_number]
    if not records:
        print(json.dumps({"message": f"No attendance records for employee {args.emp_number}"}))
        sys.exit(0)
    latest = records[-1]
    emit(latest, args.json)


def cmd_apply_leave(args: argparse.Namespace) -> None:
    state = _load_state()
    emp = _find_employee(state, args.emp_number)
    if emp is None:
        print(json.dumps({"error": f"Employee not found: {args.emp_number}"}))
        sys.exit(1)
    lt = _find_leave_type_by_name(state, args.leave_type)
    if lt is None:
        print(json.dumps({"error": f"Leave type not found: {args.leave_type}"}))
        sys.exit(1)
    days_count = _calc_business_days(args.from_date, args.to_date)
    req_id = _next_counter(state, "leaveRequestId")
    request = {
        "id": req_id,
        "empNumber": args.emp_number,
        "leaveTypeId": lt["id"],
        "leaveTypeName": lt["name"],
        "dateApplied": date.today().isoformat(),
        "status": "PENDING",
        "fromDate": args.from_date,
        "toDate": args.to_date,
        "purpose": args.purpose or "",
        "daysCount": days_count,
    }
    state["leave_requests"].append(request)
    _save_state(state)
    emit(request, args.json)


def cmd_approve_leave(args: argparse.Namespace) -> None:
    state = _load_state()
    request = None
    for lr in state["leave_requests"]:
        if lr["id"] == args.request_id:
            request = lr
            break
    if request is None:
        print(json.dumps({"error": f"Leave request not found: {args.request_id}"}))
        sys.exit(1)
    if request["status"] != "PENDING":
        print(json.dumps({"error": f"Leave request {args.request_id} is not in PENDING status (current: {request['status']})"}))
        sys.exit(1)
    request["status"] = "APPROVED"
    # Update entitlement daysUsed
    for ent in state["leave_entitlements"]:
        if ent["empNumber"] == request["empNumber"] and ent["leaveTypeId"] == request["leaveTypeId"]:
            ent["daysUsed"] = round(ent["daysUsed"] + request["daysCount"], 1)
            break
    _save_state(state)
    emit(request, args.json)


def cmd_reject_leave(args: argparse.Namespace) -> None:
    state = _load_state()
    request = None
    for lr in state["leave_requests"]:
        if lr["id"] == args.request_id:
            request = lr
            break
    if request is None:
        print(json.dumps({"error": f"Leave request not found: {args.request_id}"}))
        sys.exit(1)
    if request["status"] != "PENDING":
        print(json.dumps({"error": f"Leave request {args.request_id} is not in PENDING status (current: {request['status']})"}))
        sys.exit(1)
    request["status"] = "REJECTED"
    _save_state(state)
    emit(request, args.json)


def cmd_leave_balance(args: argparse.Namespace) -> None:
    state = _load_state()
    emp = _find_employee(state, args.emp_number)
    if emp is None:
        print(json.dumps({"error": f"Employee not found: {args.emp_number}"}))
        sys.exit(1)
    entitlements = [e for e in state["leave_entitlements"] if e["empNumber"] == args.emp_number]
    if args.leave_type:
        lt = _find_leave_type_by_name(state, args.leave_type)
        if lt is None:
            print(json.dumps({"error": f"Leave type not found: {args.leave_type}"}))
            sys.exit(1)
        entitlements = [e for e in entitlements if e["leaveTypeId"] == lt["id"]]
    result = []
    for ent in entitlements:
        lt = _find_leave_type(state, ent["leaveTypeId"])
        result.append({
            "empNumber": ent["empNumber"],
            "leaveTypeId": ent["leaveTypeId"],
            "leaveTypeName": lt["name"] if lt else "",
            "noOfDays": ent["noOfDays"],
            "daysUsed": ent["daysUsed"],
            "daysRemaining": round(ent["noOfDays"] - ent["daysUsed"], 1),
            "fromDate": ent["fromDate"],
            "toDate": ent["toDate"],
        })
    emit(result, args.json)


def cmd_list_leave_requests(args: argparse.Namespace) -> None:
    state = _load_state()
    requests = state["leave_requests"]
    if args.emp_number is not None:
        requests = [r for r in requests if r["empNumber"] == args.emp_number]
    if args.status is not None:
        requests = [r for r in requests if r["status"] == args.status]
    emit(requests, args.json)


def cmd_add_candidate(args: argparse.Namespace) -> None:
    state = _load_state()
    cand_id = _next_counter(state, "candidateId")
    vacancy = None
    vacancy_name = ""
    if args.vacancy_id is not None:
        for v in state["vacancies"]:
            if v["id"] == args.vacancy_id:
                vacancy = v
                vacancy_name = v["name"]
                break
    candidate = {
        "id": cand_id,
        "firstName": args.first_name,
        "lastName": args.last_name,
        "email": args.email,
        "contactNumber": args.contact_number or "",
        "vacancyId": args.vacancy_id if args.vacancy_id is not None else 0,
        "vacancyName": vacancy_name,
        "status": "APPLICATION_INITIATED",
        "dateOfApplication": date.today().isoformat(),
        "modeOfApplication": "Online",
    }
    state["candidates"].append(candidate)
    _save_state(state)
    emit(candidate, args.json)


def cmd_remove_candidate(args: argparse.Namespace) -> None:
    state = _load_state()
    idx = None
    for i, c in enumerate(state["candidates"]):
        if c["id"] == args.candidate_id:
            idx = i
            break
    if idx is None:
        print(json.dumps({"error": f"Candidate not found: {args.candidate_id}"}))
        sys.exit(1)
    removed = state["candidates"].pop(idx)
    _save_state(state)
    emit({"removed": removed}, args.json)


def cmd_list_candidates(args: argparse.Namespace) -> None:
    state = _load_state()
    candidates = state["candidates"]
    if args.vacancy_id is not None:
        candidates = [c for c in candidates if c["vacancyId"] == args.vacancy_id]
    if args.status is not None:
        candidates = [c for c in candidates if c["status"] == args.status]
    emit(candidates, args.json)


def cmd_schedule_interview(args: argparse.Namespace) -> None:
    state = _load_state()
    # Find candidate
    candidate = None
    for c in state["candidates"]:
        if c["id"] == args.candidate_id:
            candidate = c
            break
    if candidate is None:
        print(json.dumps({"error": f"Candidate not found: {args.candidate_id}"}))
        sys.exit(1)
    interview_id = _next_counter(state, "interviewId")
    interview = {
        "id": interview_id,
        "candidateId": args.candidate_id,
        "candidateName": f"{candidate['firstName']} {candidate['lastName']}",
        "interviewName": args.interview_name,
        "interviewDate": args.date,
        "interviewTime": args.time,
        "note": args.note or "",
        "interviewers": [],
    }
    state["interviews"].append(interview)
    # Update candidate status to SHORTLISTED
    candidate["status"] = "SHORTLISTED"
    _save_state(state)
    emit(interview, args.json)


def cmd_set_kpi(args: argparse.Namespace) -> None:
    state = _load_state()
    kpi_id = _next_counter(state, "kpiId")
    kpi = {
        "id": kpi_id,
        "title": args.title,
        "jobTitleId": 0,
        "jobTitleName": args.job_title_name,
        "minRating": args.min_rating if args.min_rating is not None else 1,
        "maxRating": args.max_rating if args.max_rating is not None else 5,
    }
    state["kpis"].append(kpi)
    _save_state(state)
    emit(kpi, args.json)


def cmd_list_kpis(args: argparse.Namespace) -> None:
    state = _load_state()
    emit(state["kpis"], args.json)


# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="orangehrm",
        description="OrangeHRM Admin CLI — manage employees, attendance, leave, recruitment, and KPIs",
    )
    parser.add_argument("--version", action="version", version=VERSION)
    subparsers = parser.add_subparsers(dest="command", required=True)

    # version
    p_version = subparsers.add_parser("version", help="Print CLI version")
    p_version.add_argument("--json", action="store_true")
    p_version.set_defaults(func=cmd_version)

    # whoami
    p_whoami = subparsers.add_parser("whoami", help="Show current user info")
    p_whoami.add_argument("--json", action="store_true")
    p_whoami.set_defaults(func=cmd_whoami)

    # add-employee
    p_add_emp = subparsers.add_parser("add-employee", help="Create employee record")
    p_add_emp.add_argument("--first-name", required=True)
    p_add_emp.add_argument("--last-name", required=True)
    p_add_emp.add_argument("--middle-name", default="")
    p_add_emp.add_argument("--email", default="")
    p_add_emp.add_argument("--phone", default="")
    p_add_emp.add_argument("--job-title", default="")
    p_add_emp.add_argument("--sub-division", default="")
    p_add_emp.add_argument("--gender", default="", choices=["", "M", "F"])
    p_add_emp.add_argument("--json", action="store_true")
    p_add_emp.set_defaults(func=cmd_add_employee)

    # update-employee
    p_upd_emp = subparsers.add_parser("update-employee", help="Update employee attributes")
    p_upd_emp.add_argument("emp_number", type=int)
    p_upd_emp.add_argument("--first-name", default=None)
    p_upd_emp.add_argument("--last-name", default=None)
    p_upd_emp.add_argument("--email", default=None)
    p_upd_emp.add_argument("--phone", default=None)
    p_upd_emp.add_argument("--job-title", default=None)
    p_upd_emp.add_argument("--sub-division", default=None)
    p_upd_emp.add_argument("--json", action="store_true")
    p_upd_emp.set_defaults(func=cmd_update_employee)

    # list-employees
    p_list_emp = subparsers.add_parser("list-employees", help="List employees")
    p_list_emp.add_argument("--limit", type=int, default=None)
    p_list_emp.add_argument("--json", action="store_true")
    p_list_emp.set_defaults(func=cmd_list_employees)

    # get-employee
    p_get_emp = subparsers.add_parser("get-employee", help="Get employee details")
    p_get_emp.add_argument("emp_number", type=int)
    p_get_emp.add_argument("--json", action="store_true")
    p_get_emp.set_defaults(func=cmd_get_employee)

    # punch-in
    p_punch_in = subparsers.add_parser("punch-in", help="Record attendance start")
    p_punch_in.add_argument("emp_number", type=int)
    p_punch_in.add_argument("--note", default="")
    p_punch_in.add_argument("--time", default="")
    p_punch_in.add_argument("--json", action="store_true")
    p_punch_in.set_defaults(func=cmd_punch_in)

    # punch-out
    p_punch_out = subparsers.add_parser("punch-out", help="Record attendance end")
    p_punch_out.add_argument("emp_number", type=int)
    p_punch_out.add_argument("--note", default="")
    p_punch_out.add_argument("--time", default="")
    p_punch_out.add_argument("--json", action="store_true")
    p_punch_out.set_defaults(func=cmd_punch_out)

    # attendance-status
    p_att_status = subparsers.add_parser("attendance-status", help="Get latest attendance record")
    p_att_status.add_argument("emp_number", type=int)
    p_att_status.add_argument("--json", action="store_true")
    p_att_status.set_defaults(func=cmd_attendance_status)

    # apply-leave
    p_apply_leave = subparsers.add_parser("apply-leave", help="Submit leave request")
    p_apply_leave.add_argument("emp_number", type=int)
    p_apply_leave.add_argument("--leave-type", required=True)
    p_apply_leave.add_argument("--from-date", required=True)
    p_apply_leave.add_argument("--to-date", required=True)
    p_apply_leave.add_argument("--purpose", default="")
    p_apply_leave.add_argument("--json", action="store_true")
    p_apply_leave.set_defaults(func=cmd_apply_leave)

    # approve-leave
    p_approve = subparsers.add_parser("approve-leave", help="Approve leave request")
    p_approve.add_argument("request_id", type=int)
    p_approve.add_argument("--json", action="store_true")
    p_approve.set_defaults(func=cmd_approve_leave)

    # reject-leave
    p_reject = subparsers.add_parser("reject-leave", help="Reject leave request")
    p_reject.add_argument("request_id", type=int)
    p_reject.add_argument("--json", action="store_true")
    p_reject.set_defaults(func=cmd_reject_leave)

    # leave-balance
    p_balance = subparsers.add_parser("leave-balance", help="Check remaining leave days")
    p_balance.add_argument("emp_number", type=int)
    p_balance.add_argument("--leave-type", default=None)
    p_balance.add_argument("--json", action="store_true")
    p_balance.set_defaults(func=cmd_leave_balance)

    # list-leave-requests
    p_list_lr = subparsers.add_parser("list-leave-requests", help="List leave requests")
    p_list_lr.add_argument("--emp-number", type=int, default=None)
    p_list_lr.add_argument("--status", default=None, choices=["PENDING", "APPROVED", "REJECTED"])
    p_list_lr.add_argument("--json", action="store_true")
    p_list_lr.set_defaults(func=cmd_list_leave_requests)

    # add-candidate
    p_add_cand = subparsers.add_parser("add-candidate", help="Add recruitment candidate")
    p_add_cand.add_argument("--first-name", required=True)
    p_add_cand.add_argument("--last-name", required=True)
    p_add_cand.add_argument("--email", required=True)
    p_add_cand.add_argument("--contact-number", default="")
    p_add_cand.add_argument("--vacancy-id", type=int, default=None)
    p_add_cand.add_argument("--json", action="store_true")
    p_add_cand.set_defaults(func=cmd_add_candidate)

    # remove-candidate
    p_rm_cand = subparsers.add_parser("remove-candidate", help="Remove recruitment candidate")
    p_rm_cand.add_argument("candidate_id", type=int)
    p_rm_cand.add_argument("--json", action="store_true")
    p_rm_cand.set_defaults(func=cmd_remove_candidate)

    # list-candidates
    p_list_cand = subparsers.add_parser("list-candidates", help="List candidates")
    p_list_cand.add_argument("--vacancy-id", type=int, default=None)
    p_list_cand.add_argument("--status", default=None)
    p_list_cand.add_argument("--json", action="store_true")
    p_list_cand.set_defaults(func=cmd_list_candidates)

    # schedule-interview
    p_interview = subparsers.add_parser("schedule-interview", help="Create interview schedule")
    p_interview.add_argument("candidate_id", type=int)
    p_interview.add_argument("--interview-name", required=True)
    p_interview.add_argument("--date", required=True)
    p_interview.add_argument("--time", required=True)
    p_interview.add_argument("--note", default="")
    p_interview.add_argument("--json", action="store_true")
    p_interview.set_defaults(func=cmd_schedule_interview)

    # set-kpi
    p_kpi = subparsers.add_parser("set-kpi", help="Define KPI for a job title")
    p_kpi.add_argument("--title", required=True)
    p_kpi.add_argument("--job-title-name", required=True)
    p_kpi.add_argument("--min-rating", type=int, default=None)
    p_kpi.add_argument("--max-rating", type=int, default=None)
    p_kpi.add_argument("--json", action="store_true")
    p_kpi.set_defaults(func=cmd_set_kpi)

    # list-kpis
    p_list_kpi = subparsers.add_parser("list-kpis", help="List KPIs")
    p_list_kpi.add_argument("--json", action="store_true")
    p_list_kpi.set_defaults(func=cmd_list_kpis)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())