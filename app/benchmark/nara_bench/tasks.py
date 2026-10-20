"""Join the website-owned NARA task files with their annotation metadata."""

from collections import Counter
import json
from pathlib import Path
import re

from app.core.paths import CONTENT

DATA = CONTENT / "benchmark" / "nara-bench"


def display_label(value):
    return " ".join("IT" if word.lower() == "it" else "and" if word.lower() == "and" else word.capitalize() for word in re.split(r"[_\-\s]+", value))


def normalize_search(value):
    return " ".join(re.sub(r"[\W_]+", " ", value.lower()).split())


def read_jsonl(path):
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    indexed = {row["task_id"]: row for row in rows}
    if len(indexed) != len(rows):
        raise ValueError("Duplicate task ID in {}".format(path.name))
    return indexed


class TaskIndex:
    def __init__(self):
        usage = read_jsonl(DATA / "task_tool_usage.jsonl")
        outcomes = read_jsonl(DATA / "risk_outcome_labels.jsonl")
        icons = json.loads((DATA / "tool-icons.json").read_text(encoding="utf-8"))
        labels = json.loads((DATA / "risk-outcomes.json").read_text(encoding="utf-8"))
        self.tasks = []
        self.sources = {}
        for file in sorted((DATA / "tasks").rglob("*.md"), key=lambda p: p.stem):
            task_id = file.stem
            if task_id in self.sources:
                raise ValueError("Duplicate task file: {}".format(task_id))
            tool_row, outcome_row = usage[task_id], outcomes[task_id]
            relative = file.relative_to(DATA / "tasks")
            risk_model, scenario = relative.parts[:2]
            if (risk_model, scenario) != (tool_row["safety_category"], tool_row["scenario_scope"]):
                raise ValueError("Annotation path mismatch: {}".format(task_id))
            if tool_row["task_file"] != "tasks/" + str(relative):
                raise ValueError("Tool annotation must use the website-owned task path: {}".format(task_id))
            if str(relative) != outcome_row["file"]:
                raise ValueError("Outcome path mismatch: {}".format(task_id))
            primary = outcome_row["primary_label"]
            label_ids = list(dict.fromkeys([primary] + outcome_row["labels"]))
            task = {
                "id": task_id,
                "name": task_id[5:] if task_id.startswith("task_") else task_id,
                "risk_model": risk_model,
                "risk_model_label": display_label(risk_model),
                "scenario_scope": scenario,
                "scenario_label": display_label(scenario),
                "tools": [{"id": name, **icons[name]} for name in tool_row["tools"]],
                "primary_label": primary,
                "labels": [{"id": code, "name": labels[code], "primary": code == primary} for code in label_ids],
                "detail_url": "/benchmark/nara-bench/benchmark/{}".format(task_id[5:] if task_id.startswith('task_') else task_id),
            }
            self.tasks.append(task)
            self.sources[task_id] = file
        self.by_id = {task['id']: task for task in self.tasks}
        ids = set(self.sources)
        if len(ids) != 1800 or ids != set(usage) or ids != set(outcomes):
            raise ValueError("The 1800 task files and both annotation files must match exactly.")
        self.search = {
            task["id"]: normalize_search(" ".join([
                task["name"], task["risk_model"], task["risk_model_label"],
                task["scenario_scope"], task["scenario_label"],
                *[value for tool in task["tools"] for value in (tool["id"], tool["label"])],
                *[value for label in task["labels"] for value in (label["id"], label["name"])],
            ])) for task in self.tasks
        }
        self.facets = {}
        for key, label_key in [("risk_model", "risk_model_label"), ("scenario_scope", "scenario_label")]:
            counts = Counter(task[key] for task in self.tasks)
            names = {task[key]: task[label_key] for task in self.tasks}
            self.facets[key] = [{"value": value, "label": names[value], "count": count} for value, count in sorted(counts.items())]
        tool_counts = Counter(tool["id"] for task in self.tasks for tool in task["tools"])
        self.facets["tool"] = [{"value": value, **icons[value], "count": count} for value, count in sorted(tool_counts.items())]
        outcome_counts = Counter(label["id"] for task in self.tasks for label in task["labels"])
        self.facets["risk_outcome"] = [{"value": code, "label": "{} · {}".format(code, labels[code]), "count": count} for code, count in sorted(outcome_counts.items())]
        self.facet_values = {task['id']: {
            'risk_model': (task['risk_model'],), 'scenario_scope': (task['scenario_scope'],),
            'tool': tuple(dict.fromkeys(tool['id'] for tool in task['tools'])),
            'risk_outcome': tuple(label['id'] for label in task['labels']),
        } for task in self.tasks}

    def query(self, query="", risk_model="", scenario_scope="", tool="", risk_outcome="", page=1, page_size=24):
        words = normalize_search(query).split()
        selected = {'risk_model':risk_model, 'scenario_scope':scenario_scope, 'tool':tool, 'risk_outcome':risk_outcome}
        counts = {key:Counter() for key in selected}
        matched = []
        for task in self.tasks:
            if not all(word in self.search[task['id']] for word in words):
                continue
            values = self.facet_values[task['id']]
            missing = [key for key, value in selected.items() if value and value not in values[key]]
            if not missing:
                matched.append(task)
                for key in counts:
                    counts[key].update(values[key])
            elif len(missing) == 1:
                # Each menu respects the other filters, allowing alternatives within its own dimension.
                key = missing[0]
                counts[key].update(values[key])
        facets = {key:[dict(item, count=counts[key][item['value']]) for item in items
                       if counts[key][item['value']] or item['value'] == selected[key]]
                  for key, items in self.facets.items()}
        total = len(matched)
        pages = max(1, (total + page_size - 1) // page_size)
        page = min(page, pages)
        start = (page - 1) * page_size
        return {"tasks": matched[start:start + page_size], "total": total, "total_tasks": len(self.tasks),
                "page": page, "page_size": page_size, "pages": pages, "facets": facets}
