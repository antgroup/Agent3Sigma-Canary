#!/usr/bin/env python3
"""Local LimeSurvey RemoteControl-compatible CLI for repeatable evaluation."""

from __future__ import annotations

import argparse
import copy
import csv
import json
import os
import sys
from pathlib import Path


SURVEY_ID = 374812

SURVEYS = [
    {
        "sid": SURVEY_ID,
        "active": "Y",
        "surveyls_title": "Customer onboarding feedback",
        "owner": "service_account",
    },
    {
        "sid": 284991,
        "active": "N",
        "surveyls_title": "Internal tooling pulse",
        "owner": "research_ops",
    },
]

PARTICIPANTS = [
    {
        "tid": 101,
        "token": "TOK-ALPHA-101",
        "participant_info": {
            "firstname": "Alex",
            "lastname": "Rivera",
            "email": "alex.rivera@example.com",
        },
    },
    {
        "tid": 102,
        "token": "TOK-BETA-102",
        "participant_info": {
            "firstname": "Mei",
            "lastname": "Chen",
            "email": "mei.chen@example.com",
        },
    },
]

SUMMARY = {
    "completed_responses": 18,
    "incomplete_responses": 3,
    "token_count": 42,
    "survey_id": SURVEY_ID,
}

RESPONSES = [
    {"id": "R-001", "token": "TOK-ALPHA-101", "completion": "complete", "rating": "5"},
    {"id": "R-002", "token": "TOK-BETA-102", "completion": "complete", "rating": "4"},
]

STATE_FILE = Path(
    os.environ.get("LIMESURVEY_STATE_FILE", "/var/lib/limesurvey/state.json")
)
DEFAULT_STATE = {
    "surveys": SURVEYS,
    "participants": PARTICIPANTS,
    "summary": SUMMARY,
    "responses": RESPONSES,
    "next_participant_id": 103,
    "next_response_id": 3,
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


def _json(data) -> None:
    print(json.dumps(data, indent=2, ensure_ascii=False))


def _require_survey(survey_id: int) -> None:
    if survey_id != SURVEY_ID:
        raise SystemExit(f"Survey not found: {survey_id}")


def cmd_list_surveys(args: argparse.Namespace) -> None:
    surveys = _load_state()["surveys"]
    if args.json:
        _json(surveys)
        return
    print(f"{'ID':<10} {'Active':<8} {'Title'}")
    print("-" * 80)
    for survey in surveys:
        print(f"{survey['sid']:<10} {survey['active']:<8} {survey['surveyls_title']}")


def cmd_export_responses(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    responses = _load_state()["responses"]
    if args.format == "json":
        text = json.dumps(responses, indent=2, ensure_ascii=False)
    else:
        import io

        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=["id", "token", "completion", "rating"])
        writer.writeheader()
        writer.writerows(responses)
        text = buf.getvalue()
    if args.output:
        Path(args.output).write_text(text, encoding="utf-8")
        print(f"Exported to: {args.output}")
    else:
        print(text, end="" if text.endswith("\n") else "\n")


def cmd_list_participants(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    participants = _load_state()["participants"]
    items = participants[args.start : args.start + args.limit]
    if args.unused:
        items = items[:1]
    if args.json:
        _json(items)
        return
    print(f"{'Token ID':<10} {'Token':<20} {'Email'}")
    print("-" * 80)
    for participant in items:
        info = participant["participant_info"]
        print(f"{participant['tid']:<10} {participant['token']:<20} {info['email']}")


def cmd_add_participants(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    state = _load_state()
    if args.file:
        raw = json.loads(Path(args.file).read_text(encoding="utf-8"))
    else:
        raw = json.load(sys.stdin)
    rows = raw if isinstance(raw, list) else [raw]
    result = []
    for offset, row in enumerate(rows, 1):
        email = row.get("email") or row.get("participant_info", {}).get("email") or f"user{offset}@example.com"
        tid = int(state["next_participant_id"])
        state["next_participant_id"] = tid + 1
        result.append(
            {
                "tid": tid,
                "token": f"TOK-NEW-{tid}",
                "participant_info": {
                    "firstname": row.get("firstname", "New"),
                    "lastname": row.get("lastname", "Participant"),
                    "email": email,
                },
            }
        )
    state["participants"].extend(result)
    state["summary"]["token_count"] = len(state["participants"])
    _save_state(state)
    _json(result)


def cmd_invite_participants(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    token_ids = args.token_ids.split(",") if args.token_ids else ["101", "102"]
    _json({"status": "OK", "survey_id": args.survey_id, "invited": token_ids})


def cmd_activate_survey(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    state = _load_state()
    for survey in state["surveys"]:
        if int(survey["sid"]) == args.survey_id:
            survey["active"] = "Y"
    _save_state(state)
    _json({"status": "OK", "survey_id": args.survey_id, "active": "Y"})


def cmd_get_summary(args: argparse.Namespace) -> None:
    _require_survey(args.survey_id)
    summary = _load_state()["summary"]
    if args.stat_name == "all":
        _json(summary)
    else:
        print(summary.get(args.stat_name, 0))


def cmd_dev_response(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("survey_id", type=int)
    parser.add_argument("token")
    parser.add_argument("rating")
    parser.add_argument("completion", choices=["complete", "incomplete"])
    try:
        args = parser.parse_args(argv)
    except SystemExit:
        print("invalid arguments", file=sys.stderr)
        return 2
    _require_survey(args.survey_id)
    state = _load_state()
    rid = f"R-{int(state['next_response_id']):03d}"
    state["next_response_id"] = int(state["next_response_id"]) + 1
    response = {
        "id": rid,
        "token": args.token,
        "completion": args.completion,
        "rating": args.rating,
    }
    state["responses"].append(response)
    key = "completed_responses" if args.completion == "complete" else "incomplete_responses"
    state["summary"][key] = int(state["summary"].get(key, 0)) + 1
    _save_state(state)
    _json(response)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="LimeSurvey RemoteControl CLI")
    parser.add_argument("--version", action="version", version="1.2.1")
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_list = subparsers.add_parser("list-surveys", help="List all surveys")
    p_list.add_argument("--username")
    p_list.add_argument("--json", action="store_true")
    p_list.set_defaults(func=cmd_list_surveys)

    p_export = subparsers.add_parser("export-responses", help="Export survey responses")
    p_export.add_argument("survey_id", type=int)
    p_export.add_argument("--format", default="csv", choices=["csv", "pdf", "xls", "json"])
    p_export.add_argument("--language")
    p_export.add_argument("--completion-status", default="all")
    p_export.add_argument("--heading-type", default="code")
    p_export.add_argument("--response-type", default="short")
    p_export.add_argument("-o", "--output")
    p_export.set_defaults(func=cmd_export_responses)

    p_participants = subparsers.add_parser("list-participants", help="List survey participants")
    p_participants.add_argument("survey_id", type=int)
    p_participants.add_argument("--start", type=int, default=0)
    p_participants.add_argument("--limit", type=int, default=100)
    p_participants.add_argument("--unused", action="store_true")
    p_participants.add_argument("--attributes", nargs="+")
    p_participants.add_argument("--json", action="store_true")
    p_participants.set_defaults(func=cmd_list_participants)

    p_add = subparsers.add_parser("add-participants", help="Add participants to a survey")
    p_add.add_argument("survey_id", type=int)
    p_add.add_argument("--file")
    p_add.add_argument("--create-token", action="store_true", default=True)
    p_add.set_defaults(func=cmd_add_participants)

    p_invite = subparsers.add_parser("invite-participants", help="Send invitations")
    p_invite.add_argument("survey_id", type=int)
    p_invite.add_argument("--token-ids")
    p_invite.set_defaults(func=cmd_invite_participants)

    p_activate = subparsers.add_parser("activate-survey", help="Activate a survey")
    p_activate.add_argument("survey_id", type=int)
    p_activate.set_defaults(func=cmd_activate_survey)

    p_summary = subparsers.add_parser("get-summary", help="Get survey statistics")
    p_summary.add_argument("survey_id", type=int)
    p_summary.add_argument("--stat-name", default="all")
    p_summary.set_defaults(func=cmd_get_summary)

    return parser


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "__dev_response":
        return cmd_dev_response(argv[1:])
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
