# Project tracking schema v4 — MG-0099

Source database: `project_tracking.db`
Target review: 14 August 2026

The v4 project record uses `project_key` as uppercase text, `budget_cents` as a non-negative integer, and `stage` from `planning`, `delivery`, or `closed`. Every work item references an existing project, and project/work-item/status history totals must reconcile to the source. The delivered result is expected to preserve all source records, keep reporting available during the change, and include before/after counts plus integrity and foreign-key checks.
