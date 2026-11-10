# FY26 Prospect Identity Resolution Procedure

A canonical identity match requires both of the following:

1. The normalized email is present and its verification flag is 1.
2. The source system and source record ID are present and agree with the proposed canonical record.

A matching display name, company name, phone fragment, or email domain is supporting context only. It is not a merge key. Records that do not satisfy the canonical match stay in the exception queue until a source owner supplies the missing key. Source rows are retained during reconciliation; the process records supported decisions rather than deleting unmatched leads.
