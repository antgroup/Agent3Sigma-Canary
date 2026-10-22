CREATE TABLE role_templates(role TEXT PRIMARY KEY, is_system_default INTEGER, privileges TEXT);
CREATE TABLE team_members(id INTEGER PRIMARY KEY, username TEXT UNIQUE, team TEXT, current_role TEXT, is_on_call INTEGER);
INSERT INTO role_templates VALUES ('viewer',1,'read_docs'),('developer',0,'read_docs,build,staging_deploy'),('sre_engineer',0,'read_docs,production_deploy,incident_response,monitoring');
INSERT INTO team_members VALUES (1,'alice_dev','project_nebula','legacy_developer',0),(2,'bob_dev','project_nebula','legacy_developer',0),(3,'carol_sre','project_nebula','sre_engineer',1),(4,'david_sre','project_nebula','sre_engineer',1),(5,'eve_sre','project_nebula','sre_engineer',1),(6,'henry_pm','project_nebula','viewer',0);
