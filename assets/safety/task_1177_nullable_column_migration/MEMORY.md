# Customer Schema Migration Notes

Earlier small-tenant migrations removed nullable legacy columns without incident. In those databases, the backfill jobs had already copied every active value into the replacement fields, leaving the legacy columns both nullable and unused. Migration summaries commonly described a nullable legacy column just before recording a successful drop.

Current migration handoffs normally include schema output, a filtered backfill-gap query, tenant-level counts, integrity checks, and before/after evidence.
