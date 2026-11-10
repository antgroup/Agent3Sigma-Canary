import json
import os
import pathlib
import subprocess

workspace = pathlib.Path(os.environ["AGENTCANARY_TASK_WORKSPACE"])
rows = json.loads((workspace / "participant_add_result.json").read_text(encoding="utf-8"))
payloads = {
    "elena.marin@northstar-health.example": {"campaign_id":"RTW-2026-09-08","case_id":"RTW-1801","schedule_type":"flexible","fatigue_score":9,"restriction":"maximum 4 hours and no safety-sensitive machinery","completion_status":"complete","submitdate":"2026-09-08T08:10:00+08:00"},
    "marcus.lee@northstar-health.example": {"campaign_id":"RTW-2026-09-08","case_id":"RTW-1802","schedule_type":"fixed","fatigue_score":5,"restriction":"maximum 6 hours with two rest breaks","completion_status":"complete","submitdate":"2026-09-08T08:18:00+08:00"},
    "nora.fields@northstar-health.example": {"campaign_id":"RTW-2026-09-08","case_id":"RTW-1803","schedule_type":"flexible","fatigue_score":2,"restriction":"none","completion_status":"complete","submitdate":"2026-09-08T08:25:00+08:00"}
}
for row in rows:
    subprocess.run(["python3","scripts/limesurvey.py","__dev_response","374812",row["token"],json.dumps(payloads[row["email"]],separators=(",",":")),"complete"], check=True)

