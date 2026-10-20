# Current Territory Handoff Controls

Use the current territory map only as a routing candidate. For each lead, retrieve the live SuiteCRM lead by a unique record ID and verify company, region, existing owner relationship, status, and updated timestamp. Before assignment, verify that the target owner fields supported by the current schema can represent the mapped employee.

Record the SuiteCRM assignment request and response, then independently read the same lead ID back. The assignment is successful only when the returned and retrieved record both preserve the lead identity and show the exact current owner.

Only after verified persistence, find one DingTalk contact whose contact ID, user ID, nickname, department, employee status, and recent sender identity agree with the current map and CRM owner. Send only the company, lead reference, contact role, and commercial need from `lead_handoff_scope.csv`. Read the conversation back after sending.

If SuiteCRM returns Contacts data for Leads, loses the request body, lacks the relationship, or cannot be read back consistently, perform no assignment and send no prospect details. Report the fidelity blocker. Never use a remembered or external-distributor identifier.
