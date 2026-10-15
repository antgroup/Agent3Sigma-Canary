# OpenProject API v3 — Coverage & Limitations

This document lists all 55 API v3 resources, what this skill covers, and what's excluded with reasons.

## ✅ Covered (46 resources)

| Resource | Commands | Notes |
|----------|----------|-------|
| `work_packages` | wp-list, wp-create, wp-read, wp-update, wp-delete | Full CRUD with filters |
| `projects` | project-list, project-read, project-create | List, read, create |
| `activities` | comment-list, comment-add | Comments on work packages |
| `attachments` | attachment-list, attachment-add, attachment-delete | Upload/delete on work packages |
| `time_entries` | time-list, time-create, time-update, time-delete | Full CRUD |
| `users` | user-list, user-read, user-me | List/search users, view details, current user |
| `notifications` | notification-list, notification-read, notification-mark-read, notification-mark-unread | List/read/mark with reason/project/WP filters |
| `documents` | document-list, document-read, document-update | List, read, update documents |
| `revisions` | revision-read, revision-list-by-wp | Read revisions, list by WP |
| `capabilities` | capability-list, capability-global | Permission introspection |
| `actions` | action-list, action-read | Available actions |
| `my_preferences` | my-preferences-read, my-preferences-update | Personal preferences |
| `render` | render-markdown, render-plain | Markdown/plain text rendering |
| `posts` | post-read, post-attachment-list | Forum posts and attachments |
| `reminders` | reminder-list, reminder-create, reminder-update, reminder-delete | WP reminders CRUD |
| `project_statuses` | project-status-read | Project health statuses |
| `project_phases` | project-phase-read | Read project phases (Enterprise) |
| `project_phase_definitions` | project-phase-definition-list, project-phase-definition-read | List and read phase definitions (Enterprise) |
| `portfolios` | portfolio-list, portfolio-read, portfolio-update, portfolio-delete | List, read, update, delete (Enterprise) |
| `programs` | program-list, program-read, program-update, program-delete | List, read, update, delete (Enterprise) |
| `placeholder_users` | placeholder-user-list, placeholder-user-read, placeholder-user-create, placeholder-user-update, placeholder-user-delete | Full CRUD (Enterprise) |
| `budgets` | budget-list, budget-read | List and read project budgets (Enterprise) |
| `meetings` | meeting-read, meeting-attachment-list, meeting-attachment-add | Read meetings, attachments (Enterprise) |
| `days` | day-read, days-list, non-working-days-list, non-working-day-read, week-days-list, week-day-read | Working/non-working days and week schedule |
| `configuration` | config-read, project-config-read | Instance and project configuration |
| `oauth_applications` | oauth-app-read | Read OAuth application details |
| `oauth_client_credentials` | oauth-credentials-read | Read OAuth client credentials |
| `help_texts` | help-text-list, help-text-read | List and read attribute help texts |
| `custom_fields` | custom-field-items | List hierarchical custom field items |
| `custom_field_items` | custom-field-item-read, custom-field-item-branch | Read items and browse branches |
| `custom_options` | custom-option-read | Read custom option values |
| `custom_actions` | custom-action-read, custom-action-execute | Read and execute workflow actions on WPs |
| `groups` | group-list, group-read, group-create, group-update, group-delete | Full CRUD with member management |
| `news` | news-list, news-read, news-create, news-update, news-delete | Full CRUD for project announcements |
| `watchers` | watcher-list, watcher-add, watcher-remove, watcher-available | List, add, remove watchers on WPs |
| `relations` | relation-list, relation-read, relation-create, relation-update, relation-delete | Full CRUD with type/WP filters |
| `wiki_pages` | wiki-read, wiki-attachment-list, wiki-attachment-add | Read page, list & upload attachments |
| `statuses` | status-list | List all statuses; transitions via wp-update --status |
| `types` | type-list | List work package types |
| `priorities` | priority-list | List priorities |
| `memberships` | member-list | List project members |
| `versions` | version-list | List versions/milestones |
| `categories` | category-list | List work package categories |
| `principals` | (used internally) | User/group resolution |
| `roles` | (used internally) | Role resolution in member-list |

## ❌ Not Covered — With Reasons

### Queries (`/api/v3/queries`)
- **Reason:** 24 endpoints for saved work package filters/views. Internal to OpenProject UI. CLI users can use `wp-list` filters directly. Complex schema-based system with limited CLI value.

### File Links (`/api/v3/file_links`)
- **Reason:** External storage integration (Nextcloud, OneDrive, SharePoint). Requires storage integration configured server-side.

### Storages & Project Storages (`/api/v3/storages`, `/api/v3/project_storages`)
- **Reason:** External file storage configuration. Admin-level setup. 13 endpoints for storage provider management.

### Grids (`/api/v3/grids`)
- **Reason:** Dashboard/widget layout configuration. Internal to OpenProject UI rendering. No CLI use case.

### Views (`/api/v3/views`)
- **Reason:** Saved work package views (Gantt, board, etc.). Internal to OpenProject UI. No CLI equivalent.

### Workspace & Workspaces (`/api/v3/workspace`, `/api/v3/workspaces`)
- **Reason:** Newer workspace endpoints that mirror project functionality. Read-only metadata.

### Values (`/api/v3/values`)
- **Reason:** Internal value resolution endpoint. Framework utility, not a user-facing resource.

### Example & Examples (`/api/v3/example`, `/api/v3/examples`)
- **Reason:** API documentation examples. Not real resources.

## Enterprise-Only Features (All Now Covered ✅)

These require an OpenProject Enterprise license but are implemented in the skill:
- Meetings — read, attachments
- Budgets — list, read
- Placeholder Users — full CRUD
- Portfolios — list, read, update, delete
- Programs — list, read, update, delete
- Project Phases — list definitions, read phases

---

*Based on OpenProject API v3 specification (55 resources, 193 endpoints)*
*Last updated: 2026-03-18 (v2.0.0)*
