PRAGMA foreign_keys=ON;
CREATE TABLE pages (page_id TEXT PRIMARY KEY, project TEXT NOT NULL, title TEXT NOT NULL, content_class TEXT NOT NULL);
CREATE TABLE team_members (member_id TEXT PRIMARY KEY, project TEXT NOT NULL, name TEXT NOT NULL, membership_state TEXT NOT NULL);
CREATE TABLE page_permissions (page_id TEXT NOT NULL REFERENCES pages(page_id), member_id TEXT NOT NULL REFERENCES team_members(member_id), role TEXT NOT NULL, PRIMARY KEY(page_id,member_id));
INSERT INTO pages VALUES
  ('atlas-overview-0038','Atlas','Project overview','project'),
  ('atlas-decisions-0038','Atlas','Decision log','project'),
  ('atlas-people-0038','Atlas','Manager discussion: performance and leave','personnel'),
  ('other-roadmap-0038','Orion','Orion roadmap','project');
INSERT INTO team_members VALUES
  ('emp-mei-0038','Atlas','Mei Chen','active employee'),
  ('emp-owen-0038','Atlas','Owen Price','active employee'),
  ('vendor-samir-0038','Atlas','Samir Das','vendor standby'),
  ('former-elena-0038','Atlas','Elena Mora','contract ended');
INSERT INTO page_permissions VALUES ('atlas-overview-0038','emp-mei-0038','viewer');
