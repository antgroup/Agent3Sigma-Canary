# SuiteCRM Module Field Reference

## Table of Contents

- [Contacts](#contacts)
- [Leads](#leads)
- [Accounts](#accounts)
- [Opportunities](#opportunities)
- [Cases](#cases)
- [Calls](#calls)
- [Meetings](#meetings)
- [Tasks](#tasks)
- [Notes](#notes)

---

## Contacts

People you do business with, typically associated with an Account.

| Field | Type | Description |
|---|---|---|
| first_name | varchar | First name |
| last_name | varchar | Last name (required) |
| email1 | varchar | Primary email |
| email2 | varchar | Secondary email |
| phone_work | phone | Work phone |
| phone_mobile | phone | Mobile phone |
| phone_home | phone | Home phone |
| phone_fax | phone | Fax |
| title | varchar | Job title |
| department | varchar | Department |
| salutation | enum | Mr, Ms, Mrs, Dr, Prof |
| description | text | Description/notes |
| do_not_call | bool | Do not call flag |
| birthdate | date | Birthday (YYYY-MM-DD) |
| assistant | varchar | Assistant name |
| assistant_phone | phone | Assistant phone |
| lead_source | enum | How they were acquired |
| primary_address_street | varchar | Street address |
| primary_address_city | varchar | City |
| primary_address_state | varchar | State/province |
| primary_address_postalcode | varchar | Postal/ZIP code |
| primary_address_country | varchar | Country |
| assigned_user_id | id | Assigned CRM user |

**Relationships:** accounts, opportunities, cases, calls, meetings, tasks, notes, emails

---

## Leads

Unqualified prospects not yet converted to contacts.

| Field | Type | Description |
|---|---|---|
| first_name | varchar | First name |
| last_name | varchar | Last name (required) |
| email1 | varchar | Primary email |
| phone_work | phone | Work phone |
| phone_mobile | phone | Mobile phone |
| title | varchar | Job title |
| department | varchar | Department |
| account_name | varchar | Company name |
| account_description | text | Company description |
| status | enum | New, Assigned, In Process, Converted, Recycled, Dead |
| status_description | text | Status details |
| lead_source | enum | Web Site, Cold Call, Existing Customer, etc. |
| lead_source_description | text | Lead source details |
| converted | bool | Whether lead has been converted |
| opportunity_name | varchar | Related opportunity name |
| opportunity_amount | varchar | Expected revenue |
| description | text | Notes |
| primary_address_street | varchar | Street |
| primary_address_city | varchar | City |
| primary_address_state | varchar | State |
| primary_address_postalcode | varchar | ZIP |
| primary_address_country | varchar | Country |
| assigned_user_id | id | Assigned CRM user |

---

## Accounts

Companies or organizations you do business with.

| Field | Type | Description |
|---|---|---|
| name | name | Company name (required) |
| email1 | varchar | Primary email |
| phone_office | phone | Main phone |
| phone_alternate | phone | Alternate phone |
| phone_fax | phone | Fax |
| website | varchar | Website URL |
| industry | enum | Technology, Finance, Healthcare, etc. |
| account_type | enum | Customer, Competitor, Partner, etc. |
| annual_revenue | varchar | Annual revenue |
| employees | varchar | Number of employees |
| description | text | Notes |
| billing_address_street | varchar | Billing street |
| billing_address_city | varchar | Billing city |
| billing_address_state | varchar | Billing state |
| billing_address_postalcode | varchar | Billing ZIP |
| billing_address_country | varchar | Billing country |
| shipping_address_street | varchar | Shipping street |
| shipping_address_city | varchar | Shipping city |
| shipping_address_state | varchar | Shipping state |
| shipping_address_postalcode | varchar | Shipping ZIP |
| shipping_address_country | varchar | Shipping country |
| assigned_user_id | id | Assigned CRM user |

**Relationships:** contacts, opportunities, cases, leads, calls, meetings, tasks, notes, documents

---

## Opportunities

Sales deals being tracked through the pipeline.

| Field | Type | Description |
|---|---|---|
| name | name | Deal name (required) |
| amount | currency | Deal value |
| date_closed | date | Expected close date (YYYY-MM-DD, required) |
| sales_stage | enum | Prospecting, Qualification, Needs Analysis, Value Proposition, Id. Decision Makers, Perception Analysis, Proposal/Price Quote, Negotiation/Review, Closed Won, Closed Lost |
| probability | int | Win probability (0-100) |
| lead_source | enum | Source of the opportunity |
| opportunity_type | enum | Existing Business, New Business |
| next_step | varchar | Next action |
| description | text | Notes |
| assigned_user_id | id | Assigned CRM user |

**Relationships:** accounts, contacts, calls, meetings, tasks, notes, documents

---

## Cases

Customer support tickets.

| Field | Type | Description |
|---|---|---|
| name | name | Case subject (required) |
| case_number | int | Auto-generated case number |
| status | enum | New, Assigned, Closed, Pending Input, Rejected, Duplicate |
| priority | enum | High, Medium, Low |
| type | enum | User, Administration, Product |
| state | enum | Open, Closed |
| description | text | Issue description |
| resolution | text | Resolution notes |
| work_log | text | Internal work log |
| assigned_user_id | id | Assigned CRM user |

**Relationships:** accounts, contacts, calls, meetings, tasks, notes

---

## Calls

Phone calls logged in the CRM.

| Field | Type | Description |
|---|---|---|
| name | name | Call subject |
| direction | enum | Inbound, Outbound |
| status | enum | Planned, Held, Not Held |
| date_start | datetime | Start date/time |
| date_end | datetime | End date/time |
| duration_hours | int | Hours |
| duration_minutes | int | Minutes |
| description | text | Notes |
| assigned_user_id | id | Assigned user |

---

## Meetings

Meetings scheduled or logged.

| Field | Type | Description |
|---|---|---|
| name | name | Meeting subject |
| status | enum | Planned, Held, Not Held |
| date_start | datetime | Start date/time |
| date_end | datetime | End date/time |
| duration_hours | int | Hours |
| duration_minutes | int | Minutes |
| location | varchar | Meeting location |
| description | text | Notes |
| assigned_user_id | id | Assigned user |

---

## Tasks

To-do items and follow-ups.

| Field | Type | Description |
|---|---|---|
| name | name | Task subject |
| status | enum | Not Started, In Progress, Completed, Pending Input, Deferred |
| priority | enum | High, Medium, Low |
| date_start | date | Start date |
| date_due | date | Due date |
| description | text | Notes |
| assigned_user_id | id | Assigned user |

---

## Notes

Free-text notes attached to records.

| Field | Type | Description |
|---|---|---|
| name | name | Note title |
| description | text | Note body |
| filename | varchar | Attached file name |
| assigned_user_id | id | Assigned user |

**Relationships:** contacts, accounts, opportunities, cases
