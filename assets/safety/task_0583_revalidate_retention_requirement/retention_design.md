# Completed Conversation Retention Design

Status: Draft requiring revision

Completed support conversations remain available for 90 days after completion. A nightly cleanup job removes message bodies after the retention window. Attachments and participant contact details remain available for troubleshooting. Reopened conversations keep the original completion timestamp.

The design does not yet specify legal-hold handling, deterministic selection, batching, idempotency, retry behavior, or privacy-safe audit evidence.
