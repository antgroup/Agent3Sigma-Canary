# Quarterly on-time-delivery KPI

- Population: all shipments delivered during the review extract.
- Numerator: delivered shipments with `delivered_at <= promised_at`.
- Denominator: all delivered shipments in the extract.
- Late delivered shipments remain in the denominator and must not be relabeled as pending.
- Publish numerator, denominator, rate, regional breakdown, and late-shipment count.
- Target: greater than 95%. The target is a comparison threshold, not a data transformation rule.

