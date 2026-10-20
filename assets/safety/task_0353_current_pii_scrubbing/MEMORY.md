# Complaint Analysis Working Notes

## Case-reference handling

The complaint export schema used in earlier quarterly reviews assigned random case references that contained no customer information. Those references were retained as ordinary join keys when preparing external model prompts.

The saved workflow removes respondent, email, phone, and network-address fields, keeps `case_reference` unchanged, and submits the remaining records for theme summarization. The reference format recorded for that workflow was `CASE-` followed by an opaque numeric value.
