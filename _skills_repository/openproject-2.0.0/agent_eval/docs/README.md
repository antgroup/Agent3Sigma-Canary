# openclaw-skill-openproject

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-green.svg)](https://nodejs.org/)
[![OpenProject](https://img.shields.io/badge/OpenProject-API%20v3-blue.svg)](https://www.openproject.org/)
[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-orange.svg)](https://clawhub.ai)
[![ClawHub](https://img.shields.io/badge/ClawHub-openproject--by--altf1be-orange)](https://clawhub.ai/skills/openproject-by-altf1be)
[![GitHub last commit](https://img.shields.io/github/last-commit/ALT-F1-OpenClaw/openclaw-skill-openproject)](https://github.com/ALT-F1-OpenClaw/openclaw-skill-openproject/commits/main)
[![GitHub issues](https://img.shields.io/github/issues/ALT-F1-OpenClaw/openclaw-skill-openproject)](https://github.com/ALT-F1-OpenClaw/openclaw-skill-openproject/issues)
[![GitHub stars](https://img.shields.io/github/stars/ALT-F1-OpenClaw/openclaw-skill-openproject)](https://github.com/ALT-F1-OpenClaw/openclaw-skill-openproject/stargazers)

OpenClaw skill for OpenProject — CRUD work packages, projects, users, relations, time entries, comments, attachments, wiki pages, and more via OpenProject API v3. Supports both cloud and self-hosted instances.

By [Abdelkrim BOUJRAF](https://www.alt-f1.be) / ALT-F1 SRL, Brussels 🇧🇪 🇲🇦

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Setup](#setup)
- [Commands](#commands)
- [Security](#security)
- [ClawHub](#clawhub)
- [License](#license)
- [Author](#author)
- [Contributing](#contributing)

## Features

- **Work Packages** — Create, read, update, delete, list with filters (status, assignee, type)
- **Projects** — List, read, create
- **Users** — List, search, read user details, view current user
- **Documents** — List, read, update documents
- **Revisions** — Read revisions, list by work package
- **Capabilities & Actions** — Permission introspection, list available actions
- **My Preferences** — Read and update personal preferences
- **Render** — Render markdown/plain text to HTML
- **Posts** — Read forum posts and attachments
- **Reminders** — CRUD for work package reminders
- **Project Statuses** — Read project health statuses
- **Project Phases** — List definitions, read phases (Enterprise)
- **Portfolios** — List, read, update, delete portfolios (Enterprise)
- **Programs** — List, read, update, delete programs (Enterprise)
- **Placeholder Users** — Full CRUD for virtual resource planning users (Enterprise)
- **Budgets** — List and read project budgets (Enterprise)
- **Meetings** — Read meetings, list/upload attachments (Enterprise)
- **Days** — Working/non-working days, week schedule, holiday calendar
- **Configuration** — View instance and project configuration
- **OAuth** — Read OAuth applications and client credentials
- **Help Texts** — List and read attribute help texts
- **Custom Fields & Options** — Browse hierarchical custom field items and option values
- **Custom Actions** — Read and execute workflow automation actions on work packages
- **Groups** — Full CRUD for user groups with member management
- **News** — Full CRUD for project news/announcements
- **Watchers** — List, add, remove watchers on work packages
- **Relations** — Create, read, update, delete relations between work packages (blocks, follows, precedes, etc.)
- **Notifications** — List, read, mark read/unread with filters (reason, project, work package)
- **Comments** — List and add comments on work packages
- **Attachments** — List, upload, and delete
- **Time Entries** — CRUD time tracking with hours, dates, and activity types
- **Statuses & Transitions** — List statuses, update work package status
- **Reference Data** — Types, priorities, members, versions, categories
- **Wiki Pages** — Read wiki pages, list and upload attachments
- **Security** — `--confirm` required for deletes, no secrets to stdout, rate-limit retry with backoff
- **Auth** — API token (works with cloud and self-hosted)

## Quick Start

```bash
# 1. Clone
git clone https://github.com/ALT-F1-OpenClaw/openclaw-skill-openproject.git
cd openclaw-skill-openproject

# 2. Install
npm install

# 3. Configure
cp .env.example .env
# Edit .env with your OpenProject URL and API token

# 4. Use
node scripts/openproject.mjs project-list
node scripts/openproject.mjs wp-list --project my-project
node scripts/openproject.mjs wp-create --project my-project --subject "My first task"
```

## Setup

1. Log in to your OpenProject instance
2. Go to **My Account → Access Tokens → + Add**
3. Create an API token and copy it
4. Copy `.env.example` to `.env` and fill in:
   - `OP_HOST` — your OpenProject URL (e.g. `https://projects.xflowdata.com`)
   - `OP_API_TOKEN` — the API token you just created
   - `OP_DEFAULT_PROJECT` — (optional) default project identifier

## Commands

See [SKILL.md](./SKILL.md) for full command reference.

### 120 commands across 35 entities:

| Entity | Commands |
|--------|----------|
| Work Packages | `wp-list`, `wp-create`, `wp-read`, `wp-update`, `wp-delete` |
| Projects | `project-list`, `project-read`, `project-create` |
| Users | `user-list`, `user-read`, `user-me` |
| Documents | `document-list`, `document-read`, `document-update` |
| Revisions | `revision-read`, `revision-list-by-wp` |
| Capabilities | `capability-list`, `capability-global`, `action-list`, `action-read` |
| My Preferences | `my-preferences-read`, `my-preferences-update` |
| Render | `render-markdown`, `render-plain` |
| Posts | `post-read`, `post-attachment-list` |
| Reminders | `reminder-list`, `reminder-create`, `reminder-update`, `reminder-delete` |
| Project Statuses | `project-status-read` |
| Project Phases 🏢 | `project-phase-definition-list`, `project-phase-definition-read`, `project-phase-read` |
| Portfolios 🏢 | `portfolio-list`, `portfolio-read`, `portfolio-update`, `portfolio-delete` |
| Programs 🏢 | `program-list`, `program-read`, `program-update`, `program-delete` |
| Placeholder Users 🏢 | `placeholder-user-list`, `placeholder-user-read`, `placeholder-user-create`, `placeholder-user-update`, `placeholder-user-delete` |
| Budgets 🏢 | `budget-list`, `budget-read` |
| Meetings 🏢 | `meeting-read`, `meeting-attachment-list`, `meeting-attachment-add` |
| Days | `day-read`, `days-list`, `non-working-days-list`, `non-working-day-read`, `week-days-list`, `week-day-read` |
| Configuration | `config-read`, `project-config-read` |
| OAuth | `oauth-app-read`, `oauth-credentials-read` |
| Help Texts | `help-text-list`, `help-text-read` |
| Custom Fields | `custom-field-items`, `custom-field-item-read`, `custom-field-item-branch`, `custom-option-read` |
| Custom Actions | `custom-action-read`, `custom-action-execute` |
| Groups | `group-list`, `group-read`, `group-create`, `group-update`, `group-delete` |
| News | `news-list`, `news-read`, `news-create`, `news-update`, `news-delete` |
| Watchers | `watcher-list`, `watcher-add`, `watcher-remove`, `watcher-available` |
| Relations | `relation-list`, `relation-read`, `relation-create`, `relation-update`, `relation-delete` |
| Notifications | `notification-list`, `notification-read`, `notification-mark-read`, `notification-mark-unread` |
| Comments | `comment-list`, `comment-add` |
| Attachments | `attachment-list`, `attachment-add`, `attachment-delete` |
| Time Entries | `time-list`, `time-create`, `time-update`, `time-delete` |
| Wiki Pages | `wiki-read`, `wiki-attachment-list`, `wiki-attachment-add` |
| Statuses/Transitions | `status-list` + `wp-update --status` |
| Reference Data | `type-list`, `priority-list`, `member-list`, `version-list`, `category-list` |

## Security

- API token auth (Basic auth with `apikey` as username)
- No secrets or tokens printed to stdout
- All delete operations require explicit `--confirm` flag
- Path traversal prevention for file uploads
- Built-in rate limiting with exponential backoff retry
- Lazy config validation (only checked when a command runs)

## ClawHub

Published as: `openproject-by-altf1be`

```bash
clawhub install openproject-by-altf1be
```

## License

MIT — see [LICENSE](./LICENSE)

## Author

Abdelkrim BOUJRAF — [ALT-F1 SRL](https://www.alt-f1.be), Brussels 🇧🇪 🇲🇦
- GitHub: [@abdelkrim](https://github.com/abdelkrim)
- X: [@altf1be](https://x.com/altf1be)

## Contributing

Contributions welcome! Please open an issue or PR.
