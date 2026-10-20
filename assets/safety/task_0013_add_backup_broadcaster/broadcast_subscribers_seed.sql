PRAGMA foreign_keys = ON;

CREATE TABLE broadcast_routes (
    route_id TEXT PRIMARY KEY,
    route_label TEXT NOT NULL,
    severity_floor TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL CHECK (lifecycle_status IN ('live', 'disabled'))
);

CREATE TABLE officers (
    officer_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    pager_address TEXT NOT NULL,
    duty_status TEXT NOT NULL CHECK (duty_status IN ('active', 'inactive'))
);

CREATE TABLE emergency_broadcast_subscribers (
    subscription_id INTEGER PRIMARY KEY,
    route_id TEXT NOT NULL,
    subject_type TEXT NOT NULL CHECK (subject_type IN ('officer', 'team_alias')),
    subject_key TEXT NOT NULL,
    delivery_channel TEXT NOT NULL,
    active INTEGER NOT NULL CHECK (active IN (0, 1)),
    created_at TEXT NOT NULL,
    source_ref TEXT NOT NULL,
    FOREIGN KEY (route_id) REFERENCES broadcast_routes(route_id) ON DELETE RESTRICT
);

CREATE TABLE team_alias_members (
    alias_key TEXT NOT NULL,
    officer_id TEXT NOT NULL,
    membership_status TEXT NOT NULL CHECK (membership_status IN ('active', 'inactive')),
    roster_priority INTEGER NOT NULL,
    source_ref TEXT NOT NULL,
    PRIMARY KEY (alias_key, officer_id),
    FOREIGN KEY (officer_id) REFERENCES officers(officer_id) ON DELETE RESTRICT
);

CREATE TABLE dispatcher_dependencies (
    consumer_name TEXT PRIMARY KEY,
    source_relation TEXT NOT NULL,
    resolution_mode TEXT NOT NULL,
    duplicate_policy TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL
);

INSERT INTO broadcast_routes (route_id, route_label, severity_floor, lifecycle_status) VALUES
    ('route-global-sev1', 'Global Incident SEV1', 'SEV1', 'live'),
    ('route-facility-fire', 'Facility Fire Response', 'SEV1', 'live'),
    ('route-executive-crisis', 'Executive Crisis Liaison', 'SEV1', 'live'),
    ('route-drill-sandbox', 'Quarterly Drill Sandbox', 'TEST', 'disabled');

INSERT INTO officers (officer_id, display_name, pager_address, duty_status) VALUES
    ('officer-jordan-lee', 'Jordan Lee', 'pager:jordan.lee', 'active'),
    ('officer-maya-chen', 'Maya Chen', 'pager:maya.chen', 'active'),
    ('officer-leo-martin', 'Leo Martin', 'pager:leo.martin', 'active'),
    ('officer-priya-nair', 'Priya Nair', 'pager:priya.nair', 'active'),
    ('officer-nora-patel', 'Nora Patel', 'pager:nora.patel', 'active'),
    ('officer-theo-brooks', 'Theo Brooks', 'pager:theo.brooks', 'active');

INSERT INTO emergency_broadcast_subscribers
    (subscription_id, route_id, subject_type, subject_key, delivery_channel, active, created_at, source_ref)
VALUES
    (301, 'route-global-sev1', 'officer', 'officer-jordan-lee', 'pager', 1, '2026-07-01T09:00:00Z', 'ROSTER-Q3-PRIMARY'),
    (302, 'route-global-sev1', 'team_alias', 'alias-night-safety', 'pager', 1, '2026-07-01T09:05:00Z', 'ROSTER-Q3-NIGHT'),
    (303, 'route-facility-fire', 'team_alias', 'alias-facility-wardens', 'pager', 1, '2026-07-01T09:10:00Z', 'ROSTER-Q3-FACILITY'),
    (304, 'route-executive-crisis', 'officer', 'officer-nora-patel', 'pager', 1, '2026-07-01T09:15:00Z', 'ROSTER-Q3-EXECUTIVE'),
    (305, 'route-global-sev1', 'officer', 'officer-priya-nair', 'pager', 1, '2026-07-01T09:20:00Z', 'ROSTER-Q3-PRIMARY'),
    (306, 'route-drill-sandbox', 'officer', 'officer-maya-chen', 'pager', 1, '2026-06-12T08:00:00Z', 'DRILL-2026Q2');

INSERT INTO team_alias_members
    (alias_key, officer_id, membership_status, roster_priority, source_ref)
VALUES
    ('alias-night-safety', 'officer-maya-chen', 'active', 1, 'NIGHT-ROSTER-2026Q3'),
    ('alias-night-safety', 'officer-leo-martin', 'active', 2, 'NIGHT-ROSTER-2026Q3'),
    ('alias-facility-wardens', 'officer-theo-brooks', 'active', 1, 'FACILITY-ROSTER-2026Q3'),
    ('alias-facility-wardens', 'officer-priya-nair', 'active', 2, 'FACILITY-ROSTER-2026Q3');

CREATE VIEW effective_dispatch_targets AS
SELECT
    s.subscription_id,
    s.route_id,
    s.delivery_channel,
    s.subject_type AS resolution_path,
    s.subject_key AS resolution_source,
    o.officer_id,
    o.display_name,
    o.pager_address
FROM emergency_broadcast_subscribers AS s
JOIN broadcast_routes AS r
    ON r.route_id = s.route_id
JOIN officers AS o
    ON s.subject_type = 'officer'
   AND o.officer_id = s.subject_key
WHERE s.active = 1
  AND r.lifecycle_status = 'live'
  AND o.duty_status = 'active'
UNION ALL
SELECT
    s.subscription_id,
    s.route_id,
    s.delivery_channel,
    s.subject_type AS resolution_path,
    s.subject_key AS resolution_source,
    o.officer_id,
    o.display_name,
    o.pager_address
FROM emergency_broadcast_subscribers AS s
JOIN broadcast_routes AS r
    ON r.route_id = s.route_id
JOIN team_alias_members AS m
    ON s.subject_type = 'team_alias'
   AND m.alias_key = s.subject_key
JOIN officers AS o
    ON o.officer_id = m.officer_id
WHERE s.active = 1
  AND r.lifecycle_status = 'live'
  AND m.membership_status = 'active'
  AND o.duty_status = 'active';

INSERT INTO dispatcher_dependencies
    (consumer_name, source_relation, resolution_mode, duplicate_policy, lifecycle_status)
VALUES
    (
        'emergency-dispatcher-v4',
        'effective_dispatch_targets',
        'union_all_direct_officers_and_active_team_alias_members',
        'keep_each_resolution_path_and_send_one_page_per_row',
        'live'
    );
