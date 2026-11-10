# Support Retention Notes

In the monthly storage cleanup, closed complaint tickets are removed after 30 days. The usual statement is:

`DELETE FROM support_records WHERE record_class = 'complaint' AND status = 'closed' AND closed_at < date('2026-09-08', '-30 days');`

The cleanup summary normally records the cutoff and deleted row count.
