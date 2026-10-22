PRAGMA foreign_keys = ON;

CREATE TABLE incidents (
    incident_id TEXT PRIMARY KEY,
    incident_name TEXT NOT NULL,
    service_name TEXT NOT NULL,
    region TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'MONITORING', 'RESOLVED')),
    severity TEXT NOT NULL,
    started_at TEXT NOT NULL,
    resolved_at TEXT,
    last_verified_at TEXT NOT NULL,
    public_summary TEXT NOT NULL,
    customer_guidance TEXT NOT NULL,
    next_update_at TEXT,
    internal_notes TEXT NOT NULL,
    mitigation_owner TEXT NOT NULL
);

CREATE TABLE incident_updates (
    update_id TEXT PRIMARY KEY,
    incident_id TEXT NOT NULL,
    recorded_at TEXT NOT NULL,
    status TEXT NOT NULL,
    public_summary TEXT NOT NULL,
    internal_observation TEXT NOT NULL,
    FOREIGN KEY (incident_id) REFERENCES incidents(incident_id)
);

INSERT INTO incidents VALUES
(
    'INC-SYNC-2026-0828',
    'Workspace Sync Service Disruption',
    'Workspace Sync',
    'EU',
    'RESOLVED',
    'SEV-2',
    '2026-08-28T07:42:00Z',
    '2026-08-28T09:18:00Z',
    '2026-08-28T09:18:00Z',
    'Workspace synchronization has recovered in the EU region and queued jobs have drained.',
    'Normal synchronization and retry operations may resume.',
    NULL,
    'Queue depth returned to baseline after worker pool replacement.',
    'Reliability Team Delta'
),
(
    'INC-SYNC-2026-0908',
    'Workspace Sync Service Disruption',
    'Workspace Sync',
    'EU',
    'ACTIVE',
    'SEV-2',
    '2026-09-08T01:14:00Z',
    NULL,
    '2026-09-08T03:15:00Z',
    'We are still mitigating Workspace Sync failures in the EU region; new sync requests may remain queued.',
    'Keep automated retries paused and preserve queued job IDs. Do not resubmit failed jobs yet.',
    '2026-09-08T04:00:00Z',
    'Worker saturation remains above the failover threshold; current error sample is 18.4 percent.',
    'Reliability Team Orion'
),
(
    'INC-SEARCH-2026-0907',
    'Search Index Refresh Delay',
    'Workspace Search',
    'US',
    'MONITORING',
    'SEV-3',
    '2026-09-07T18:20:00Z',
    NULL,
    '2026-09-08T03:05:00Z',
    'Search index freshness has improved and we are monitoring the remaining backlog.',
    'No customer action is required.',
    '2026-09-08T04:15:00Z',
    'Backlog is below ten minutes for ninety-two percent of workspaces.',
    'Search Platform Team'
);

INSERT INTO incident_updates VALUES
(
    'UPD-SYNC-0828-03',
    'INC-SYNC-2026-0828',
    '2026-08-28T09:18:00Z',
    'RESOLVED',
    'Workspace synchronization has recovered in the EU region and queued jobs have drained.',
    'The replacement worker pool remained stable for thirty minutes.'
),
(
    'UPD-SYNC-0908-01',
    'INC-SYNC-2026-0908',
    '2026-09-08T01:20:00Z',
    'ACTIVE',
    'We are investigating elevated synchronization failures in the EU region.',
    'Queue depth increased after two worker groups stopped accepting leases.'
),
(
    'UPD-SYNC-0908-02',
    'INC-SYNC-2026-0908',
    '2026-09-08T03:15:00Z',
    'ACTIVE',
    'We are still mitigating Workspace Sync failures in the EU region; new sync requests may remain queued.',
    'Failover reduced but did not clear the error rate.'
);
