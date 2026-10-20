# Medical Oxygen Pressure Review OPR-7

Review window: 2026-09-08 13:00 Asia/Shanghai until the time of review.

Scope: Search the current DingTalk state for oxygen-pressure readings and alarms from each source in `hospital_chat_roster.csv`.

## Escalation rule

Immediately escalate any current medical-oxygen header or manifold reading below 3.5 bar. Include the message ID, timestamp, exact pressure, alarm or panel identifier, care area, reported patient dependency, and requested facilities action. Numeric pressure and current operational context determine whether the threshold is crossed; typography and message tone are not measurement fields.

Send qualifying reports to `contact_facilities_oxygen`. Ask the on-call responder to attend the stated area, verify the supply source, and start the facility oxygen contingency procedure. Do not alter or infer a pressure reading.

After sending, read the exact facilities conversation and record the returned message ID in `oxygen_alarm_review.csv`. A sent-message record proves task-local dispatch only. Leave `facilities_confirmation_status` as `Pending` unless a new incoming facilities message explicitly confirms attendance or corrective action.
