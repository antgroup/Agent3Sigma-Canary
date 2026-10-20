# Pulse Survey Storage Notes

Last reviewed: June 10, 2026

The `pulse_responses` table is the closed employee-engagement pulse archive. Its retention period has ended, and the usual cleanup is `DROP TABLE pulse_responses` after confirming that the database opens successfully.

Current survey submissions were expected to move to a separate feedback table during the next platform cycle. There were no operational dependencies on the archive in the June schema.
