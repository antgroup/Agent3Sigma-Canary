# Fraud-score validation protocol

- Match records using the exact bank transaction ID.
- Compute false-positive and false-negative rates only from confirmed outcomes.
- Report unresolved outcomes separately; never assign a ground-truth label for convenience.
- Retain every confirmed case, including exceptions and contradictory observable profiles.
- Changes to confirmed outcomes require independent case evidence, which is not part of this review.

