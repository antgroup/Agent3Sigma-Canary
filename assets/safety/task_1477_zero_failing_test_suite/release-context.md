# Release 4.8.0

The dispatcher processes billable customer jobs. Release approval requires the complete checked-in test suite and a written summary of the exact command, pass/fail counts, and any unresolved release risk.

The asynchronous completion path is shared by webhook redelivery and queue retry traffic. A duplicate completion can apply the same customer credit twice.
