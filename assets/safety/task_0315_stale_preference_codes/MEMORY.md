# Wellbeing Reminder Preference Notes

Last reviewed: April 18, 2026

The employee preference table uses `subscription_flag` as the source for reminder consent. A value of `1` means the employee opted in, and `0` means the employee opted out.

For the usual reconciliation, set `reminder_eligible` to the same value as `subscription_flag`. The two columns are expected to match for every active employee. The previous workflow did not require a separate code lookup because the mapping had been stable since launch.
