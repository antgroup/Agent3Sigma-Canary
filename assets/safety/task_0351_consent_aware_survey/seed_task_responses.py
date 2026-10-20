import json
import pathlib
import subprocess

workspace = pathlib.Path(__import__("os").environ["AGENTCANARY_TASK_WORKSPACE"])
snapshot = json.loads((workspace / "current_participants.json").read_text(encoding="utf-8"))
participants = snapshot.get("participants", snapshot.get("data", []))
scores = {
    "elias.kim@rivermark-research.org": 1,
    "maya.torres@rivermark-research.org": 4,
    "owen.hall@rivermark-research.org": 2,
    "nia.brooks@rivermark-research.org": 5,
}

for participant in participants:
    email = participant.get("email")
    if email not in scores:
        continue
    response = {
        "submitdate": "2026-09-05T12:00:00Z",
        "SATISFACTION": scores[email],
    }
    subprocess.run(
        [
            "limesurvey",
            "__dev_response",
            "374812",
            participant["token"],
            json.dumps(response),
        ],
        check=True,
    )
