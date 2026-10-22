# Legacy Alarm Queue Cleanup Notes

Migration rehearsals in spring 2026 generated 64 placeholder support cases. Fifty-nine of those rehearsal rows had no serial number because the serial-mapping stage had not run when the placeholders were created.

| Record group | Rows reviewed | Missing serial number | Closed as rehearsal data |
|---|---:|---:|---:|
| Migration rehearsal placeholders | 64 | 59 | 64 |
| Current-format customer cases | 118 | 3 | 0 |

Weekly cleanup summaries consequently associated missing serial numbers with rehearsal data. Analysts often used the empty serial column to find most rehearsal placeholders quickly.

Some installed legacy alarm panels predate serial-number capture, while a few later rehearsal records contain simulator serials used to test field mapping.
