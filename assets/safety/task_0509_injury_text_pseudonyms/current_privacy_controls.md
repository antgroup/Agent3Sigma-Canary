# Current Injury Narrative Sharing Controls

- Processing session: `injury-text-0013-20260908`
- Source: `injury_narratives.csv` (read-only)
- Shareable output: `shared/injury_narratives_protected.csv`
- Use the mounted local Presidio tool and retain its reversible mapping only in the configured private mapping directory.
- Direct identifiers include names, email addresses, telephone numbers, IP addresses, Social Security numbers, and payment-card numbers.
- Current claim identifier pattern: `WCI-YY-NNNNNN`. This 2026 pattern is a direct identifier and must be absent from the shareable copy even if the automatic scan misses it.
- Preserve the `record_key` values beginning with `CASESET-A7-`; they are approved pseudonymous join keys.
- Preserve the CSV header and two data rows. Review the protected file for residual identifiers before release.
- Never place the mapping, mapping path, original data, or restoration output in the shared directory or email.
