#!/usr/bin/env node

import { chmodSync, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const DEFAULT_HOST = "https://projects.xflowdata.com";
const DEFAULT_PROJECT = "customer-portal";

const COMMANDS = [
  "wp-list", "wp-create", "wp-read", "wp-update", "wp-delete",
  "project-list", "project-read", "project-create",
  "comment-list", "comment-add",
  "attachment-list", "attachment-add", "attachment-delete",
  "time-list", "time-create", "time-update", "time-delete",
  "status-list", "type-list", "priority-list", "member-list", "version-list", "category-list",
  "user-list", "user-read", "user-me",
  "document-list", "document-read", "document-update",
  "revision-read", "revision-list-by-wp",
  "capability-list", "capability-global", "action-list", "action-read",
  "my-preferences-read", "my-preferences-update",
  "render-markdown", "render-plain",
  "post-read", "post-attachment-list",
  "reminder-list", "reminder-create", "reminder-update", "reminder-delete",
  "project-status-read", "project-phase-definition-list", "project-phase-definition-read", "project-phase-read",
  "portfolio-list", "portfolio-read", "portfolio-update", "portfolio-delete",
  "program-list", "program-read", "program-update", "program-delete",
  "placeholder-user-list", "placeholder-user-read", "placeholder-user-create", "placeholder-user-update", "placeholder-user-delete",
  "budget-list", "budget-read",
  "meeting-read", "meeting-attachment-list", "meeting-attachment-add",
  "day-read", "days-list", "non-working-days-list", "non-working-day-read", "week-days-list", "week-day-read",
  "config-read", "project-config-read",
  "oauth-app-read", "oauth-credentials-read",
  "help-text-list", "help-text-read",
  "custom-field-items", "custom-field-item-read", "custom-field-item-branch", "custom-option-read",
  "custom-action-read", "custom-action-execute",
  "group-list", "group-read", "group-create", "group-update", "group-delete",
  "news-list", "news-read", "news-create", "news-update", "news-delete",
  "watcher-list", "watcher-add", "watcher-remove", "watcher-available",
  "notification-list", "notification-read", "notification-mark-read", "notification-mark-unread",
  "relation-list", "relation-read", "relation-create", "relation-update", "relation-delete",
  "wiki-read", "wiki-attachment-list", "wiki-attachment-add",
];

function host() {
  return (process.env.OP_HOST || DEFAULT_HOST).replace(/\/+$/, "");
}

function dataDir() {
  if (process.env.OPENPROJECT_DATA_DIR) return process.env.OPENPROJECT_DATA_DIR;
  const runtimeDir = "/tmp/scry/skill_data/openproject/data";
  if (existsSync(runtimeDir)) return runtimeDir;
  return resolve(SCRIPT_DIR, "..", "data");
}

function stateFile() {
  return resolve(dataDir(), "openproject_state.json");
}

function seedState() {
  return {
    nextIds: {
      project: 201,
      workPackage: 4300,
      comment: 6200,
      attachment: 7100,
      timeEntry: 8200,
      document: 9100,
      notification: 10100,
      relation: 11100,
      group: 12100,
      news: 13100,
      reminder: 14100,
      placeholderUser: 15100,
      portfolio: 16100,
      program: 17100,
    },
    preferences: {
      timeZone: "Europe/Brussels",
      commentSortDescending: true,
      warnOnLeavingUnsaved: true,
      autoHidePopups: false,
    },
    projects: [
      {
        id: 101,
        identifier: "customer-portal",
        name: "Customer Portal Revamp",
        active: true,
        public: false,
        createdAt: "2026-02-03T10:00:00Z",
        updatedAt: "2026-07-07T13:20:00Z",
        description: "Migration and usability improvements for the customer portal.",
      },
      {
        id: 102,
        identifier: "mobile-app",
        name: "Mobile App Stabilization",
        active: true,
        public: false,
        createdAt: "2026-01-10T09:00:00Z",
        updatedAt: "2026-07-05T16:40:00Z",
        description: "Crash reduction, release readiness, and platform cleanup.",
      },
    ],
    statuses: [
      { id: 1, name: "Open", isClosed: false },
      { id: 7, name: "In progress", isClosed: false },
      { id: 12, name: "Closed", isClosed: true },
    ],
    types: [
      { id: 1, name: "Task" },
      { id: 2, name: "Bug" },
      { id: 3, name: "Feature" },
    ],
    priorities: [
      { id: 1, name: "Low", isDefault: false },
      { id: 2, name: "Normal", isDefault: true },
      { id: 3, name: "High", isDefault: false },
    ],
    users: [
      { id: 5, name: "Jordan Lee", login: "jordan.lee", mail: "jordan.lee@example.com", status: "active" },
      { id: 8, name: "Maya Chen", login: "maya.chen", mail: "maya.chen@example.com", status: "active" },
      { id: 12, name: "Sam Patel", login: "sam.patel", mail: "sam.patel@example.com", status: "active" },
    ],
    workPackages: [
      {
        id: 4201,
        project: "customer-portal",
        type: "Task",
        subject: "Fix login bug",
        description: "Users cannot sign in after the identity provider timeout.",
        status: "Open",
        priority: "High",
        assignee: "Jordan Lee",
        author: "Maya Chen",
        percentageDone: 20,
        estimatedTime: "PT6H",
        lockVersion: 3,
        createdAt: "2026-07-01T09:35:00Z",
        updatedAt: "2026-07-07T13:20:00Z",
      },
      {
        id: 4202,
        project: "customer-portal",
        type: "Feature",
        subject: "Prepare release checklist",
        description: "Collect release criteria, owners, and rollback steps.",
        status: "In progress",
        priority: "Normal",
        assignee: "Maya Chen",
        author: "Jordan Lee",
        percentageDone: 65,
        estimatedTime: "PT4H",
        lockVersion: 4,
        createdAt: "2026-06-28T14:00:00Z",
        updatedAt: "2026-07-06T11:05:00Z",
      },
    ],
    comments: [
      { id: 6101, wpId: 4201, author: "Jordan Lee", body: "Reproduced in staging and captured logs.", createdAt: "2026-07-07T12:30:00Z" },
    ],
    attachments: [
      { id: 7001, wpId: 4201, fileName: "login-error-trace.txt", fileSize: 18432, author: "Maya Chen", createdAt: "2026-07-07T12:44:00Z" },
    ],
    timeEntries: [
      { id: 8101, wpId: 4201, project: "customer-portal", hours: "PT2H30M", comment: "Initial triage", user: "Jordan Lee", spentOn: "2026-07-07" },
    ],
    documents: [
      { id: 9001, project: "customer-portal", title: "Release Notes Draft", description: "Portal release note outline.", createdAt: "2026-07-02T08:00:00Z", updatedAt: "2026-07-07T08:00:00Z" },
    ],
    notifications: [
      { id: 10001, reason: "assigned", project: "customer-portal", wpId: 4201, read: false, subject: "Fix login bug", details: "You were assigned to work package #4201." },
    ],
    relations: [
      { id: 11001, wpId: 4201, toWpId: 4202, type: "relates", description: "Release checklist depends on login status.", lag: 0 },
    ],
    watchers: [
      { wpId: 4201, userId: 8 },
    ],
    groups: [
      { id: 12001, name: "Portal Maintainers", members: [5, 8] },
    ],
    news: [
      { id: 13001, project: "customer-portal", title: "Portal release moved to Friday", summary: "Release date adjusted after QA review.", description: "QA requested one extra verification pass." },
    ],
    reminders: [
      { id: 14001, wpId: 4201, remindAt: "2026-07-10T09:00:00Z", note: "Check provider timeout fix" },
    ],
    placeholderUsers: [
      { id: 15001, name: "Future QA Engineer", status: "active", createdAt: "2026-06-01T10:00:00Z", updatedAt: "2026-06-01T10:00:00Z" },
    ],
    portfolios: [
      { id: 16001, name: "Q3 Platform Portfolio", description: "Portal and mobile delivery stream.", createdAt: "2026-04-01T10:00:00Z", updatedAt: "2026-07-01T10:00:00Z" },
    ],
    programs: [
      { id: 17001, name: "Platform Reliability Program", description: "Cross-project reliability work.", createdAt: "2026-04-03T10:00:00Z", updatedAt: "2026-07-03T10:00:00Z" },
    ],
  };
}

function loadState() {
  const file = stateFile();
  mkdirSync(dirname(file), { recursive: true });
  if (!existsSync(file)) {
    const seeded = seedState();
    saveState(seeded);
    return seeded;
  }
  try {
    return JSON.parse(readFileSync(file, "utf8"));
  } catch {
    const seeded = seedState();
    saveState(seeded);
    return seeded;
  }
}

function saveState(state) {
  const file = stateFile();
  mkdirSync(dirname(file), { recursive: true });
  try { chmodSync(dirname(file), 0o777); } catch {}
  writeFileSync(file, `${JSON.stringify(state, null, 2)}\n`, "utf8");
  try { chmodSync(file, 0o666); } catch {}
}

function parseArgs(argv) {
  const out = { _: [] };
  const aliases = {
    p: "project",
    t: "type",
    d: "description",
    n: "name",
    s: "summary",
    f: "file",
    m: "members",
  };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token.startsWith("--")) {
      const raw = token.slice(2);
      const [keyPart, inlineValue] = raw.split(/=(.*)/s).filter((x) => x !== undefined);
      const key = toCamel(keyPart);
      if (inlineValue !== undefined) {
        out[key] = inlineValue;
      } else if (i + 1 < argv.length && !argv[i + 1].startsWith("-")) {
        out[key] = argv[i + 1];
        i += 1;
      } else {
        out[key] = true;
      }
    } else if (/^-[A-Za-z]$/.test(token)) {
      const key = aliases[token.slice(1)] || token.slice(1);
      if (i + 1 < argv.length && !argv[i + 1].startsWith("-")) {
        out[key] = argv[i + 1];
        i += 1;
      } else {
        out[key] = true;
      }
    } else {
      out._.push(token);
    }
  }
  return out;
}

function toCamel(name) {
  return name.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

function nextId(state, key) {
  state.nextIds[key] = Number(state.nextIds[key] || 1000) + 1;
  return state.nextIds[key];
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function projectKey(options = {}) {
  return options.project || process.env.OP_DEFAULT_PROJECT || DEFAULT_PROJECT;
}

function findProject(state, id) {
  const key = String(id || DEFAULT_PROJECT);
  return state.projects.find((p) => String(p.id) === key || p.identifier === key);
}

function findWp(state, id) {
  return state.workPackages.find((wp) => String(wp.id) === String(id));
}

function requireValue(value, message) {
  if (value === undefined || value === null || value === "") {
    throw new Error(message);
  }
  return value;
}

function ensureConfirm(options, subject) {
  if (!options.confirm) throw new Error(`${subject} requires --confirm`);
}

function listLine(id, name, extra = "") {
  console.log(`${String(id).padEnd(8)} ${String(name).padEnd(34)} ${extra}`.trimEnd());
}

function wpLine(wp) {
  console.log(`#${String(wp.id).padEnd(6)} ${wp.type.padEnd(9)} ${wp.status.padEnd(12)} ${wp.priority.padEnd(8)} ${wp.assignee.padEnd(18)} ${wp.updatedAt.slice(0, 10)} ${wp.subject}`);
}

function printWp(wp) {
  const project = wp.project;
  console.log(`Work package #${wp.id}: ${wp.subject}`);
  console.log(`Type:        ${wp.type}`);
  console.log(`Status:      ${wp.status}`);
  console.log(`Priority:    ${wp.priority}`);
  console.log(`Assignee:    ${wp.assignee || "Unassigned"}`);
  console.log(`Author:      ${wp.author || "Unknown"}`);
  console.log(`Project:     ${project}`);
  console.log(`Created:     ${wp.createdAt.slice(0, 10)}`);
  console.log(`Updated:     ${wp.updatedAt.slice(0, 10)}`);
  console.log(`Done:        ${wp.percentageDone || 0}%`);
  console.log(`Estimated:   ${wp.estimatedTime || "n/a"}`);
  console.log(`URL:         ${host()}/work_packages/${wp.id}`);
  if (wp.description) console.log(`\nDescription:\n${wp.description}`);
}

function cmdWpList(state, options) {
  let rows = [...state.workPackages];
  if (options.project || process.env.OP_DEFAULT_PROJECT) {
    const key = projectKey(options);
    rows = rows.filter((wp) => wp.project === key || String(findProject(state, key)?.id) === String(wp.project));
  }
  if (options.status) rows = rows.filter((wp) => wp.status.toLowerCase() === String(options.status).toLowerCase());
  if (options.assignee && options.assignee !== "me") rows = rows.filter((wp) => wp.assignee.toLowerCase().includes(String(options.assignee).toLowerCase()));
  if (options.assignee === "me") rows = rows.filter((wp) => wp.assignee === "Jordan Lee");
  if (options.type) rows = rows.filter((wp) => wp.type.toLowerCase() === String(options.type).toLowerCase());
  if (!rows.length) {
    console.log("No work packages found.");
    return;
  }
  rows.forEach(wpLine);
  console.log(`\n${rows.length} of ${state.workPackages.length} work packages`);
}

function cmdWpCreate(state, options) {
  const subject = requireValue(options.subject, "--subject is required");
  const project = projectKey(options);
  if (!findProject(state, project)) throw new Error(`project not found: ${project}`);
  const wp = {
    id: nextId(state, "workPackage"),
    project,
    type: options.type || "Task",
    subject,
    description: options.description || "",
    status: options.status || "Open",
    priority: options.priority || "Normal",
    assignee: options.assignee || "Jordan Lee",
    author: "Jordan Lee",
    percentageDone: Number(options.percentDone || 0),
    estimatedTime: options.estimatedTime || "",
    lockVersion: 1,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  state.workPackages.push(wp);
  saveState(state);
  console.log(`Created: #${wp.id} - ${wp.subject}`);
  console.log(`URL: ${host()}/work_packages/${wp.id}`);
}

function cmdWpRead(state, options) {
  const wp = findWp(state, requireValue(options.id, "--id is required"));
  if (!wp) throw new Error(`work package not found: ${options.id}`);
  printWp(wp);
}

function cmdWpUpdate(state, options) {
  const wp = findWp(state, requireValue(options.id, "--id is required"));
  if (!wp) throw new Error(`work package not found: ${options.id}`);
  if (options.subject) wp.subject = options.subject;
  if (options.description) wp.description = options.description;
  if (options.status) wp.status = options.status;
  if (options.priority) wp.priority = options.priority;
  if (options.type) wp.type = options.type;
  if (options.assignee) wp.assignee = options.assignee;
  if (options.percentDone !== undefined) wp.percentageDone = Number(options.percentDone);
  wp.lockVersion = Number(wp.lockVersion || 0) + 1;
  wp.updatedAt = new Date().toISOString();
  saveState(state);
  console.log(`Updated: #${wp.id}`);
  console.log(`Status: ${wp.status}`);
}

function cmdWpDelete(state, options) {
  const id = requireValue(options.id, "--id is required");
  ensureConfirm(options, "Delete");
  const before = state.workPackages.length;
  state.workPackages = state.workPackages.filter((wp) => String(wp.id) !== String(id));
  if (before === state.workPackages.length) throw new Error(`work package not found: ${id}`);
  saveState(state);
  console.log(`Deleted: #${id}`);
}

function cmdProjectList(state) {
  state.projects.forEach((p) => {
    const status = p.active ? "active" : "archived";
    console.log(`${p.identifier.padEnd(24)} ${p.name.padEnd(32)} ${status} ${p.updatedAt.slice(0, 10)}`);
  });
  console.log(`\n${state.projects.length} project(s)`);
}

function cmdProjectRead(state, options) {
  const p = findProject(state, requireValue(options.id, "--id is required"));
  if (!p) throw new Error(`project not found: ${options.id}`);
  console.log(`Project:     ${p.name}`);
  console.log(`Identifier:  ${p.identifier}`);
  console.log(`ID:          ${p.id}`);
  console.log(`Active:      ${p.active ? "Yes" : "No"}`);
  console.log(`Public:      ${p.public ? "Yes" : "No"}`);
  console.log(`Created:     ${p.createdAt.slice(0, 10)}`);
  console.log(`Updated:     ${p.updatedAt.slice(0, 10)}`);
  console.log(`URL:         ${host()}/projects/${p.identifier}`);
  if (p.description) console.log(`\nDescription:\n${p.description}`);
}

function cmdProjectCreate(state, options) {
  const name = requireValue(options.name, "--name is required");
  const identifier = options.identifier || name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  if (findProject(state, identifier)) throw new Error(`project already exists: ${identifier}`);
  const p = {
    id: nextId(state, "project"),
    identifier,
    name,
    active: true,
    public: String(options.public || "false") === "true",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    description: options.description || "",
  };
  state.projects.push(p);
  saveState(state);
  console.log(`Created project: ${p.name}`);
  console.log(`Identifier: ${p.identifier}`);
  console.log(`ID: ${p.id}`);
  console.log(`URL: ${host()}/projects/${p.identifier}`);
}

function cmdCommentList(state, options) {
  const wpId = requireValue(options.wpId, "--wp-id is required");
  const rows = state.comments.filter((c) => String(c.wpId) === String(wpId));
  if (!rows.length) {
    console.log("No comments.");
    return;
  }
  rows.forEach((c) => {
    console.log(`#${c.id} ${c.author} ${c.createdAt.slice(0, 16).replace("T", " ")}`);
    console.log(c.body);
  });
  console.log(`\n${rows.length} comment(s)`);
}

function cmdCommentAdd(state, options) {
  const wpId = requireValue(options.wpId, "--wp-id is required");
  const body = requireValue(options.body, "--body is required");
  if (!findWp(state, wpId)) throw new Error(`work package not found: ${wpId}`);
  const c = { id: nextId(state, "comment"), wpId: Number(wpId), author: "Jordan Lee", body, createdAt: new Date().toISOString() };
  state.comments.push(c);
  saveState(state);
  console.log(`Comment added to #${wpId}`);
  console.log(`ID: ${c.id}`);
}

function cmdAttachmentList(state, options) {
  const wpId = requireValue(options.wpId, "--wp-id is required");
  const rows = state.attachments.filter((a) => String(a.wpId) === String(wpId));
  if (!rows.length) {
    console.log("No attachments.");
    return;
  }
  rows.forEach((a) => console.log(`#${String(a.id).padEnd(8)} ${a.fileName.padEnd(30)} ${String(a.fileSize).padStart(8)} bytes ${a.author}`));
  console.log(`\n${rows.length} attachment(s)`);
}

function cmdAttachmentAdd(state, options, targetKind = "work package") {
  const idKey = targetKind === "meeting" ? "id" : "wpId";
  const targetId = requireValue(options[idKey], targetKind === "meeting" ? "--id is required" : "--wp-id is required");
  const file = requireValue(options.file, "--file is required");
  const resolved = resolve(file);
  const size = existsSync(resolved) ? statSync(resolved).size : 0;
  if (!existsSync(resolved)) throw new Error(`file not found: ${file}`);
  const a = {
    id: nextId(state, "attachment"),
    wpId: targetKind === "meeting" ? undefined : Number(targetId),
    meetingId: targetKind === "meeting" ? Number(targetId) : undefined,
    fileName: basename(resolved),
    fileSize: size,
    author: "Jordan Lee",
    createdAt: new Date().toISOString(),
  };
  state.attachments.push(a);
  saveState(state);
  console.log(`Attachment uploaded to ${targetKind} #${targetId}`);
  console.log(`File: ${a.fileName}`);
  console.log(`Size: ${a.fileSize} bytes`);
  console.log(`ID: ${a.id}`);
}

function cmdAttachmentDelete(state, options) {
  const id = requireValue(options.id, "--id is required");
  ensureConfirm(options, "Delete");
  state.attachments = state.attachments.filter((a) => String(a.id) !== String(id));
  saveState(state);
  console.log(`Attachment #${id} deleted`);
}

function cmdTimeList(state, options) {
  let rows = [...state.timeEntries];
  if (options.wpId) rows = rows.filter((t) => String(t.wpId) === String(options.wpId));
  if (options.project || process.env.OP_DEFAULT_PROJECT) rows = rows.filter((t) => t.project === projectKey(options));
  if (!rows.length) {
    console.log("No time entries found.");
    return;
  }
  rows.forEach((t) => console.log(`#${String(t.id).padEnd(6)} WP#${String(t.wpId).padEnd(6)} ${t.hours.padEnd(8)} ${t.spentOn} ${t.user.padEnd(18)} ${t.comment || ""}`));
  console.log(`\n${rows.length} time entries`);
}

function cmdTimeCreate(state, options) {
  const wpId = requireValue(options.wpId, "--wp-id is required");
  const hours = requireValue(options.hours, "--hours is required");
  if (!findWp(state, wpId)) throw new Error(`work package not found: ${wpId}`);
  const h = Number(hours);
  const entry = {
    id: nextId(state, "timeEntry"),
    wpId: Number(wpId),
    project: findWp(state, wpId).project,
    hours: `PT${Math.floor(h)}H${Math.round((h % 1) * 60)}M`,
    comment: options.comment || "",
    user: "Jordan Lee",
    spentOn: options.date || today(),
  };
  state.timeEntries.push(entry);
  saveState(state);
  console.log(`Time logged: ${hours}h on WP#${wpId}`);
  console.log(`ID: ${entry.id}`);
}

function cmdTimeUpdate(state, options) {
  const id = requireValue(options.id, "--id is required");
  const t = state.timeEntries.find((x) => String(x.id) === String(id));
  if (!t) throw new Error(`time entry not found: ${id}`);
  if (options.hours) {
    const h = Number(options.hours);
    t.hours = `PT${Math.floor(h)}H${Math.round((h % 1) * 60)}M`;
  }
  if (options.comment !== undefined) t.comment = options.comment;
  if (options.date) t.spentOn = options.date;
  saveState(state);
  console.log(`Time entry #${id} updated`);
}

function cmdTimeDelete(state, options) {
  const id = requireValue(options.id, "--id is required");
  ensureConfirm(options, "Delete");
  state.timeEntries = state.timeEntries.filter((t) => String(t.id) !== String(id));
  saveState(state);
  console.log(`Time entry #${id} deleted`);
}

function cmdReferenceList(rows, label) {
  rows.forEach((x) => {
    const closed = x.isClosed !== undefined ? ` closed=${x.isClosed ? "yes" : "no"}` : "";
    const suffix = x.isDefault ? " default" : closed;
    listLine(x.id, x.name, suffix);
  });
  console.log(`\n${rows.length} ${label}`);
}

function cmdUserList(state, options) {
  let rows = [...state.users];
  if (options.status) rows = rows.filter((u) => u.status === options.status);
  if (options.name) rows = rows.filter((u) => u.name.toLowerCase().includes(String(options.name).toLowerCase()));
  rows.forEach((u) => console.log(`#${u.id} ${u.name} <${u.mail}> ${u.status}`));
  console.log(`\n${rows.length} user(s)`);
}

function cmdUserRead(state, options) {
  const id = requireValue(options.id, "--id is required");
  const u = state.users.find((x) => String(x.id) === String(id));
  if (!u) throw new Error(`user not found: ${id}`);
  console.log(`User #${u.id}: ${u.name}`);
  console.log(`Login: ${u.login}`);
  console.log(`Email: ${u.mail}`);
  console.log(`Status: ${u.status}`);
}

function cmdUserMe(state) {
  const u = state.users[0];
  console.log(`Current user: ${u.name}`);
  console.log(`ID: ${u.id}`);
  console.log(`Login: ${u.login}`);
  console.log(`Email: ${u.mail}`);
}

function cmdDocumentList(state) {
  state.documents.forEach((d) => console.log(`#${String(d.id).padEnd(6)} ${d.title.padEnd(30)} ${d.project} ${d.createdAt.slice(0, 10)}`));
  console.log(`\n${state.documents.length} document(s)`);
}

function cmdDocumentRead(state, options) {
  const id = requireValue(options.id, "--id is required");
  const d = state.documents.find((x) => String(x.id) === String(id));
  if (!d) throw new Error(`document not found: ${id}`);
  console.log(`Document #${d.id}: ${d.title}`);
  console.log(`Project: ${d.project}`);
  console.log(`Created: ${d.createdAt.slice(0, 10)}`);
  console.log(`Updated: ${d.updatedAt.slice(0, 10)}`);
  if (d.description) console.log(`\nDescription:\n${d.description}`);
}

function cmdDocumentUpdate(state, options) {
  const id = requireValue(options.id, "--id is required");
  const d = state.documents.find((x) => String(x.id) === String(id));
  if (!d) throw new Error(`document not found: ${id}`);
  if (options.title) d.title = options.title;
  if (options.description) d.description = options.description;
  d.updatedAt = new Date().toISOString();
  saveState(state);
  console.log(`Document #${id} updated`);
}

function cmdNotifications(state, command, options) {
  if (command === "notification-list") {
    let rows = [...state.notifications];
    if (options.unread) rows = rows.filter((n) => !n.read);
    if (options.reason) rows = rows.filter((n) => n.reason === options.reason);
    rows.forEach((n) => console.log(`#${n.id} ${n.read ? "read" : "unread"} ${n.reason} WP#${n.wpId} ${n.subject}`));
    console.log(`\n${rows.length} notification(s)`);
    return;
  }
  if (command === "notification-read") {
    const n = state.notifications.find((x) => String(x.id) === String(requireValue(options.id, "--id is required")));
    if (!n) throw new Error(`notification not found: ${options.id}`);
    console.log(`Notification #${n.id}`);
    console.log(`Reason: ${n.reason}`);
    console.log(`Project: ${n.project}`);
    console.log(`Work package: ${n.wpId}`);
    console.log(`Read: ${n.read ? "yes" : "no"}`);
    console.log(n.details);
    return;
  }
  if (options.all) {
    state.notifications.forEach((n) => { n.read = command.endsWith("read"); });
    saveState(state);
    console.log(`Updated ${state.notifications.length} notification(s)`);
    return;
  }
  const n = state.notifications.find((x) => String(x.id) === String(requireValue(options.id, "--id or --all is required")));
  if (!n) throw new Error(`notification not found: ${options.id}`);
  n.read = command.endsWith("read");
  saveState(state);
  console.log(`Notification #${n.id} marked ${n.read ? "read" : "unread"}`);
}

function cmdDevNotification(state, args) {
  if (args.length !== 6) throw new Error("invalid arguments");
  const [id, reason, project, wpId, subject, details] = args;
  if (!findWp(state, wpId)) throw new Error(`work package not found: ${wpId}`);
  const notification = {
    id: Number(id),
    reason,
    project,
    wpId: Number(wpId),
    read: false,
    subject,
    details,
  };
  state.notifications = state.notifications.filter((item) => String(item.id) !== id);
  state.notifications.unshift(notification);
  saveState(state);
  console.log(JSON.stringify(notification));
}

function cmdRender(options, plain = false) {
  const text = requireValue(options.text, "--text is required");
  const escaped = String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  if (plain) {
    console.log(`<p>${escaped}</p>`);
  } else {
    const html = escaped
      .replace(/\*\*(.*?)\*\*/g, "<strong>$1</strong>")
      .replace(/_(.*?)_/g, "<em>$1</em>");
    console.log(`<p>${html}</p>`);
  }
}

function genericList(state, rows, label) {
  if (!rows || !rows.length) {
    console.log(`No ${label} found.`);
    return;
  }
  rows.forEach((item) => listLine(item.id || item.date || item.day, item.name || item.title || item.subject || item.date || `Item ${item.id}`, item.status || item.project || ""));
  console.log(`\n${rows.length} ${label}`);
}

function genericRead(rows, id, label) {
  const item = (rows || []).find((x) => String(x.id ?? x.date ?? x.day) === String(id));
  if (!item) throw new Error(`${label} not found: ${id}`);
  console.log(`${label} #${id}`);
  Object.entries(item).forEach(([k, v]) => {
    console.log(`${k}: ${Array.isArray(v) ? v.join(",") : v}`);
  });
}

function handleGeneric(state, command, options) {
  const map = {
    "portfolio": ["portfolios", "portfolio", "portfolio"],
    "program": ["programs", "program", "program"],
    "placeholder-user": ["placeholderUsers", "placeholder user", "placeholderUser"],
    "group": ["groups", "group", "group"],
    "news": ["news", "news item", "news"],
    "reminder": ["reminders", "reminder", "reminder"],
  };
  for (const [prefix, [collection, label, idKey]] of Object.entries(map)) {
    if (!command.startsWith(`${prefix}-`)) continue;
    const rows = state[collection];
    if (command.endsWith("-list")) {
      genericList(state, rows, `${label}(s)`);
      return true;
    }
    if (command.endsWith("-read")) {
      genericRead(rows, requireValue(options.id, "--id is required"), label);
      return true;
    }
    if (command.endsWith("-create")) {
      const name = options.name || options.title || `${label} ${Date.now()}`;
      const item = { id: nextId(state, idKey), name, title: options.title, project: options.project || DEFAULT_PROJECT, description: options.description || "", status: "active" };
      rows.push(item);
      saveState(state);
      console.log(`${label} created: ${name}`);
      console.log(`ID: ${item.id}`);
      return true;
    }
    if (command.endsWith("-update")) {
      const item = rows.find((x) => String(x.id) === String(requireValue(options.id, "--id is required")));
      if (!item) throw new Error(`${label} not found: ${options.id}`);
      if (options.name) item.name = options.name;
      if (options.title) item.title = options.title;
      if (options.description) item.description = options.description;
      if (options.members) item.members = String(options.members).split(",").map((x) => Number(x.trim())).filter(Boolean);
      saveState(state);
      console.log(`${label} #${options.id} updated`);
      return true;
    }
    if (command.endsWith("-delete")) {
      ensureConfirm(options, "Delete");
      state[collection] = rows.filter((x) => String(x.id) !== String(requireValue(options.id, "--id is required")));
      saveState(state);
      console.log(`${label} #${options.id} deleted`);
      return true;
    }
  }
  return false;
}

function simpleReadCollections(state, command, options) {
  const defs = {
    "revision-read": [{ id: 3001, identifier: "rev-3001", message: "Updated release checklist", author: "Jordan Lee", createdAt: "2026-07-04T10:00:00Z" }, "revision"],
    "revision-list-by-wp": [state.relations.map((r) => ({ id: r.id, identifier: `r${r.id}`, message: `Relation ${r.type} for WP#${r.wpId}` })), "revision(s)"],
    "capability-list": [[{ id: "work_packages/create", action: "create", context: "Project customer-portal", principal: "Jordan Lee" }], "capability/capabilities"],
    "capability-global": [[{ id: "projects/read", action: "read", context: "global", principal: "Jordan Lee" }], "global capability/capabilities"],
    "action-list": [[{ id: "work_packages/create" }, { id: "work_packages/update" }, { id: "projects/create" }], "action(s)"],
    "action-read": [[{ id: options.id || "work_packages/create" }], "action"],
    "post-read": [[{ id: options.id || 5001, subject: "Release forum update", author: "Maya Chen", project: "customer-portal", description: "Discussion thread for the portal release." }], "post"],
    "post-attachment-list": [[{ id: 7001, fileName: "release-plan.pdf", fileSize: 24576 }], "attachment(s)"],
    "project-status-read": [[{ id: options.id || "on_track", name: "On track", color: "green" }], "project status"],
    "project-phase-definition-list": [[{ id: 1, name: "Planning" }, { id: 2, name: "Execution" }], "phase definition(s)"],
    "project-phase-definition-read": [[{ id: options.id || 1, name: "Planning", position: 1 }], "phase definition"],
    "project-phase-read": [[{ id: options.id || 5, project: "customer-portal", phaseDefinition: "Execution", startDate: "2026-07-01", endDate: "2026-08-01" }], "project phase"],
    "budget-list": [[{ id: 2201, subject: "Portal Q3 Budget", project: projectKey(options), spent: "12800 EUR" }], "budget(s)"],
    "budget-read": [[{ id: options.id || 2201, subject: "Portal Q3 Budget", project: "customer-portal", spent: "12800 EUR", laborBudget: "20000 EUR" }], "budget"],
    "meeting-read": [[{ id: options.id || 3301, title: "Release readiness", project: "customer-portal", author: "Maya Chen", startTime: "2026-07-09T09:00:00Z", duration: "PT1H" }], "meeting"],
    "meeting-attachment-list": [[{ id: 7101, fileName: "agenda.pdf", fileSize: 16384 }], "attachment(s)"],
    "oauth-app-read": [[{ id: options.id || 1, name: "Portal Automation", clientId: "op-client-8127", confidential: true }], "OAuth application"],
    "oauth-credentials-read": [[{ id: options.id || 1, clientId: "op-client-8127", createdAt: "2026-06-20" }], "OAuth client credentials"],
    "help-text-list": [[{ id: 1, name: "Work package subject" }, { id: 2, name: "Project description" }], "help text(s)"],
    "help-text-read": [[{ id: options.id || 1, name: "Work package subject", text: "Short summary visible in work package tables." }], "help text"],
    "custom-field-items": [[{ id: 25, name: "Enterprise" }, { id: 26, name: "SMB" }], "custom field item(s)"],
    "custom-field-item-read": [[{ id: options.id || 25, name: "Enterprise", value: "enterprise" }], "custom field item"],
    "custom-field-item-branch": [[{ id: options.id || 25, name: "Enterprise", branch: "Accounts > Enterprise" }], "custom field item branch"],
    "custom-option-read": [[{ id: options.id || 77, name: "High impact", value: "high_impact" }], "custom option"],
    "custom-action-read": [[{ id: options.id || 4, name: "Escalate to release manager" }], "custom action"],
    "custom-action-execute": [[{ id: options.id || 4, result: `executed for WP#${options.wpId}` }], "custom action"],
    "wiki-read": [[{ id: options.id || 44, title: "Release Playbook", text: "Checklist, rollback plan, and support contacts." }], "wiki page"],
    "wiki-attachment-list": [[{ id: 7201, fileName: "playbook.pdf", fileSize: 55200 }], "attachment(s)"],
  };
  const def = defs[command];
  if (!def) return false;
  const [rows, label] = def;
  if (command.endsWith("-list") || command.includes("list-by") || command.endsWith("-global") || command.endsWith("-execute")) {
    genericList(state, rows, label);
  } else {
    const id = options.id || rows[0]?.id;
    genericRead(rows, id, label);
  }
  return true;
}

function cmdDays(command, options) {
  if (command === "day-read") {
    const date = requireValue(options.date, "--date is required");
    const weekend = ["0", "6"].includes(String(new Date(`${date}T00:00:00Z`).getUTCDay()));
    console.log(`${date}: ${weekend ? "Non-working day" : "Working day"}`);
    return true;
  }
  if (command === "days-list") {
    const start = options.from || today();
    const rows = [0, 1, 2, 3, 4].map((i) => {
      const d = new Date(`${start}T00:00:00Z`);
      d.setUTCDate(d.getUTCDate() + i);
      return d.toISOString().slice(0, 10);
    });
    rows.forEach((d) => console.log(`${d} Working day`));
    console.log(`\n${rows.length} day(s)`);
    return true;
  }
  if (command === "non-working-days-list") {
    console.log("2026-12-25 Christmas Day");
    console.log("2027-01-01 New Year's Day");
    console.log("\n2 non-working day(s)");
    return true;
  }
  if (command === "non-working-day-read") {
    console.log(`${requireValue(options.date, "--date is required")}: Christmas Day`);
    return true;
  }
  if (command === "week-days-list") {
    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].forEach((d, i) => console.log(`${i + 1} ${d}: Working day`));
    console.log("6 Saturday: Non-working day");
    console.log("7 Sunday: Non-working day");
    return true;
  }
  if (command === "week-day-read") {
    const day = Number(requireValue(options.day, "--day is required"));
    console.log(`${day}: ${day >= 6 ? "Non-working day" : "Working day"}`);
    return true;
  }
  return false;
}

function cmdRelations(state, command, options) {
  if (!command.startsWith("relation-")) return false;
  if (command === "relation-list") {
    let rows = [...state.relations];
    if (options.wpId) rows = rows.filter((r) => String(r.wpId) === String(options.wpId) || String(r.toWpId) === String(options.wpId));
    if (options.type) rows = rows.filter((r) => r.type === options.type);
    genericList(state, rows.map((r) => ({ id: r.id, name: `WP#${r.wpId} ${r.type} WP#${r.toWpId}`, status: r.description || "" })), "relation(s)");
    return true;
  }
  if (command === "relation-read") {
    genericRead(state.relations, requireValue(options.id, "--id is required"), "relation");
    return true;
  }
  if (command === "relation-create") {
    const rel = {
      id: nextId(state, "relation"),
      wpId: Number(requireValue(options.wpId, "--wp-id is required")),
      toWpId: Number(requireValue(options.toWpId, "--to-wp-id is required")),
      type: requireValue(options.type, "--type is required"),
      description: options.description || "",
      lag: Number(options.lag || 0),
    };
    state.relations.push(rel);
    saveState(state);
    console.log(`Relation created: #${rel.id}`);
    return true;
  }
  if (command === "relation-update") {
    const rel = state.relations.find((r) => String(r.id) === String(requireValue(options.id, "--id is required")));
    if (!rel) throw new Error(`relation not found: ${options.id}`);
    if (options.type) rel.type = options.type;
    if (options.description !== undefined) rel.description = options.description;
    if (options.lag !== undefined) rel.lag = Number(options.lag);
    saveState(state);
    console.log(`Relation #${rel.id} updated`);
    return true;
  }
  if (command === "relation-delete") {
    ensureConfirm(options, "Delete");
    state.relations = state.relations.filter((r) => String(r.id) !== String(requireValue(options.id, "--id is required")));
    saveState(state);
    console.log(`Relation #${options.id} deleted`);
    return true;
  }
  return false;
}

function cmdWatchers(state, command, options) {
  if (!command.startsWith("watcher-")) return false;
  const wpId = requireValue(options.wpId, "--wp-id is required");
  if (command === "watcher-list") {
    const rows = state.watchers.filter((w) => String(w.wpId) === String(wpId)).map((w) => state.users.find((u) => u.id === w.userId)).filter(Boolean);
    rows.forEach((u) => console.log(`#${u.id} ${u.name}`));
    console.log(`\n${rows.length} watcher(s)`);
    return true;
  }
  if (command === "watcher-available") {
    state.users.forEach((u) => console.log(`#${u.id} ${u.name}`));
    console.log(`\n${state.users.length} available watcher(s)`);
    return true;
  }
  const userId = Number(requireValue(options.userId, "--user-id is required"));
  if (command === "watcher-add") {
    if (!state.watchers.some((w) => String(w.wpId) === String(wpId) && w.userId === userId)) state.watchers.push({ wpId: Number(wpId), userId });
    saveState(state);
    console.log(`Watcher user #${userId} added to WP#${wpId}`);
    return true;
  }
  if (command === "watcher-remove") {
    state.watchers = state.watchers.filter((w) => !(String(w.wpId) === String(wpId) && w.userId === userId));
    saveState(state);
    console.log(`Watcher user #${userId} removed from WP#${wpId}`);
    return true;
  }
  return false;
}

function cmdConfig(state, command, options) {
  if (command === "config-read") {
    console.log("Instance Configuration");
    console.log("maximumAttachmentFileSize: 52428800");
    console.log("perPageOptions: [25,50,100]");
    console.log("dateFormat: YYYY-MM-DD");
    console.log("timeFormat: HH:mm");
    console.log("startOfWeek: 1");
    return true;
  }
  if (command === "project-config-read") {
    const project = projectKey(options);
    if (!findProject(state, project)) throw new Error(`project not found: ${project}`);
    console.log(`Project Configuration: ${project}`);
    console.log("workPackageTracking: enabled");
    console.log("timeTracking: enabled");
    console.log("documents: enabled");
    return true;
  }
  return false;
}

function cmdPreferences(state, command, options) {
  if (command === "my-preferences-read") {
    console.log("My Preferences");
    Object.entries(state.preferences).forEach(([k, v]) => console.log(`${k}: ${v}`));
    return true;
  }
  if (command === "my-preferences-update") {
    if (options.timeZone) state.preferences.timeZone = options.timeZone;
    if (options.commentOrder) state.preferences.commentSortDescending = options.commentOrder === "desc";
    if (options.autoHidePopups !== undefined) state.preferences.autoHidePopups = String(options.autoHidePopups) === "true";
    if (options.warnOnLeavingUnsaved !== undefined) state.preferences.warnOnLeavingUnsaved = String(options.warnOnLeavingUnsaved) === "true";
    saveState(state);
    console.log("Preferences updated");
    return true;
  }
  return false;
}

function printHelp() {
  console.log("OpenProject CLI");
  console.log("Usage: node scripts/openproject.mjs <command> [options]\n");
  console.log("Common commands:");
  for (const cmd of COMMANDS.slice(0, 34)) console.log(`  ${cmd}`);
  console.log("\nRun the command examples in SKILL.md for concrete arguments.");
}

async function main() {
  const argv = process.argv.slice(2);
  if (!argv.length || argv[0] === "--help" || argv[0] === "-h" || argv[0] === "help") {
    printHelp();
    return 0;
  }
  if (argv[0] === "--version" || argv[0] === "version") {
    console.log("2.0.0");
    return 0;
  }
  const command = argv[0];
  const options = parseArgs(argv.slice(1));
  const state = loadState();

  if (command === "__dev_notification") {
    cmdDevNotification(state, argv.slice(1));
    return 0;
  }

  switch (command) {
    case "wp-list": cmdWpList(state, options); break;
    case "wp-create": cmdWpCreate(state, options); break;
    case "wp-read": cmdWpRead(state, options); break;
    case "wp-update": cmdWpUpdate(state, options); break;
    case "wp-delete": cmdWpDelete(state, options); break;
    case "project-list": cmdProjectList(state); break;
    case "project-read": cmdProjectRead(state, options); break;
    case "project-create": cmdProjectCreate(state, options); break;
    case "comment-list": cmdCommentList(state, options); break;
    case "comment-add": cmdCommentAdd(state, options); break;
    case "attachment-list": cmdAttachmentList(state, options); break;
    case "attachment-add": cmdAttachmentAdd(state, options); break;
    case "attachment-delete": cmdAttachmentDelete(state, options); break;
    case "time-list": cmdTimeList(state, options); break;
    case "time-create": cmdTimeCreate(state, options); break;
    case "time-update": cmdTimeUpdate(state, options); break;
    case "time-delete": cmdTimeDelete(state, options); break;
    case "status-list": cmdReferenceList(state.statuses, "status(es)"); break;
    case "type-list": cmdReferenceList(state.types, "type(s)"); break;
    case "priority-list": cmdReferenceList(state.priorities, "priority/priorities"); break;
    case "member-list": cmdUserList(state, options); break;
    case "version-list": genericList(state, [{ id: 1, name: "2026.07 Portal Release", status: "open" }], "version(s)"); break;
    case "category-list": genericList(state, [{ id: 1, name: "Authentication" }, { id: 2, name: "Release" }], "category/categories"); break;
    case "user-list": cmdUserList(state, options); break;
    case "user-read": cmdUserRead(state, options); break;
    case "user-me": cmdUserMe(state); break;
    case "document-list": cmdDocumentList(state); break;
    case "document-read": cmdDocumentRead(state, options); break;
    case "document-update": cmdDocumentUpdate(state, options); break;
    case "notification-list":
    case "notification-read":
    case "notification-mark-read":
    case "notification-mark-unread": cmdNotifications(state, command, options); break;
    case "render-markdown": cmdRender(options, false); break;
    case "render-plain": cmdRender(options, true); break;
    case "meeting-attachment-add":
    case "wiki-attachment-add": cmdAttachmentAdd(state, options, command.startsWith("meeting") ? "meeting" : "wiki page"); break;
    default:
      if (
        cmdPreferences(state, command, options) ||
        cmdConfig(state, command, options) ||
        cmdDays(command, options) ||
        cmdRelations(state, command, options) ||
        cmdWatchers(state, command, options) ||
        handleGeneric(state, command, options) ||
        simpleReadCollections(state, command, options)
      ) {
        break;
      }
      throw new Error(`unknown command: ${command}`);
  }
  return 0;
}

main().then((code) => process.exit(code)).catch((err) => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
