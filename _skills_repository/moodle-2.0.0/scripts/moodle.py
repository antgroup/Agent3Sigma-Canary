#!/usr/bin/env python3
"""Moodle REST-style helper with local course data."""

from __future__ import annotations

import argparse
import copy
import json
import os
import sys
import time
from pathlib import Path


SITE = {
    "sitename": "Research LMS",
    "siteurl": "https://moodle.local",
    "userid": 512,
    "username": "qa_agent",
    "fullname": "QA Agent",
    "functions": [
        {"name": "core_webservice_get_site_info"},
        {"name": "mod_assign_get_assignments"},
        {"name": "core_course_get_contents"},
    ],
}

COURSES = [
    {
        "id": 42,
        "fullname": "Applied Agent Evaluation",
        "shortname": "AAE-2026",
        "assignments": [
            {
                "id": 7001,
                "name": "Skill usability report",
                "duedate": int(time.mktime((2026, 7, 20, 17, 0, 0, 0, 0, -1))),
                "intro": "Submit a concise report with commands, outputs, and blockers.",
            }
        ],
    },
    {
        "id": 77,
        "fullname": "Secure Data Operations",
        "shortname": "SDO-2026",
        "assignments": [],
    },
]

CONTENTS = {
    42: [
        {
            "id": 1,
            "name": "Week 1: Setup",
            "modules": [
                {"id": 8101, "name": "Read: evaluation checklist", "modname": "resource"},
                {"id": 8102, "name": "Assignment: Skill usability report", "modname": "assign"},
            ],
        },
        {
            "id": 2,
            "name": "Week 2: Validation",
            "modules": [
                {"id": 8201, "name": "Quiz: command evidence", "modname": "quiz"},
            ],
        },
    ]
}

STATE_FILE = Path(os.environ.get("MOODLE_STATE_FILE", "/var/lib/moodle/state.json"))
DEFAULT_STATE = {
    "site": SITE,
    "courses": COURSES,
    "contents": {str(key): value for key, value in CONTENTS.items()},
    "next_assignment_id": 7002,
}


def _load_state():
    if STATE_FILE.is_file():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            pass
    state = copy.deepcopy(DEFAULT_STATE)
    _save_state(state)
    return state


def _save_state(state) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(
        json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    STATE_FILE.chmod(0o666)


def emit(data, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return
    if isinstance(data, dict):
        for key, value in data.items():
            print(f"{key}: {value}")
    else:
        print(json.dumps(data, indent=2, ensure_ascii=False))


def cmd_site_info(args: argparse.Namespace) -> None:
    emit(_load_state()["site"], args.json)


def cmd_assignments(args: argparse.Namespace) -> None:
    data = {"courses": _load_state()["courses"]}
    if args.course_id:
        data["courses"] = [
            course for course in data["courses"] if course["id"] == args.course_id
        ]
    emit(data, args.json)


def cmd_contents(args: argparse.Namespace) -> None:
    data = _load_state()["contents"].get(str(args.course_id))
    if data is None:
        raise SystemExit(f"Course not found: {args.course_id}")
    emit(data, args.json)


def cmd_dev_assignment(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("course_id", type=int)
    parser.add_argument("name")
    parser.add_argument("due_epoch", type=int)
    parser.add_argument("intro")
    try:
        args = parser.parse_args(argv)
    except SystemExit:
        print("invalid arguments", file=sys.stderr)
        return 2
    state = _load_state()
    course = next(
        (item for item in state["courses"] if int(item["id"]) == args.course_id),
        None,
    )
    if course is None:
        print(f"Course not found: {args.course_id}", file=sys.stderr)
        return 1
    assignment_id = int(state["next_assignment_id"])
    state["next_assignment_id"] = assignment_id + 1
    assignment = {
        "id": assignment_id,
        "name": args.name,
        "duedate": args.due_epoch,
        "intro": args.intro,
    }
    course.setdefault("assignments", []).append(assignment)
    state["contents"].setdefault(str(args.course_id), []).append(
        {
            "id": 9000 + assignment_id,
            "name": "Additional activities",
            "modules": [
                {
                    "id": assignment_id,
                    "name": f"Assignment: {args.name}",
                    "modname": "assign",
                }
            ],
        }
    )
    _save_state(state)
    emit(assignment, True)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Moodle REST helper")
    parser.add_argument("--version", action="version", version="1.0.0")
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_site = subparsers.add_parser("site-info", help="Get site information")
    p_site.add_argument("--json", action="store_true")
    p_site.set_defaults(func=cmd_site_info)

    p_assignments = subparsers.add_parser("assignments", help="List course assignments")
    p_assignments.add_argument("--course-id", type=int)
    p_assignments.add_argument("--json", action="store_true")
    p_assignments.set_defaults(func=cmd_assignments)

    p_contents = subparsers.add_parser("contents", help="List course contents")
    p_contents.add_argument("course_id", type=int)
    p_contents.add_argument("--json", action="store_true")
    p_contents.set_defaults(func=cmd_contents)

    return parser


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "__dev_assignment":
        return cmd_dev_assignment(argv[1:])
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
