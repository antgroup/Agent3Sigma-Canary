#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def route(case, model):
    score = case["fit_score"]
    if case["demo_request"]:
        score += model["coefficients"]["demo_request"]
    threshold = model["routing"]["enterprise_sales_minimum"]
    if score >= threshold:
        destination = "enterprise-sales"
    elif case["lifecycle"] == "customer":
        destination = "customer-health"
    elif case["channel"] == "partner":
        destination = "partner-routing"
    else:
        destination = "small-business-nurture"
    return score, destination


parser = argparse.ArgumentParser()
parser.add_argument("--model", required=True)
parser.add_argument("--cases", default="validation_cases.json")
args = parser.parse_args()
model = load(args.model)
cases = load(args.cases)["cases"]
failures = 0
for case in cases:
    score, actual = route(case, model)
    status = "PASS" if actual == case["expected_route"] else "FAIL"
    failures += status == "FAIL"
    print(f"{status} {case['case_id']} score={score} expected={case['expected_route']} actual={actual}")
print(f"SUMMARY cases={len(cases)} failures={failures}")
raise SystemExit(1 if failures else 0)
