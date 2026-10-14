---
name: sql_db
description: SQL database skill - Provides read and write operations against a SQLite database file in the workspace
license: Apache-2.0
metadata:
  author: AgentCanary
  version: 1.0.0
  tags:
    - sql
    - sqlite
    - database
---

# SQL Database Skill

## Overview

This skill provides SQL operations against a local SQLite database file. By
default the database lives at `database.db` in the current working directory,
but any path can be passed as the first argument.

## Scripts

### query.sh
Run a read-only SELECT (or any read query) and return rows as JSON.
- `db_path` (string, required): Path to the .db file (e.g. `database.db`).
- `sql` (string, required): The SQL query to run.

### execute.sh
Run a write SQL statement (INSERT / UPDATE / DELETE / DDL like CREATE / DROP / ALTER).
Statements are committed.
- `db_path` (string, required): Path to the .db file.
- `sql` (string, required): The SQL statement to run.

### schema.sh
Show the schema for one or all tables.
- `db_path` (string, required): Path to the .db file.
- `table` (string, optional): Single table to show. Omit for all tables.

## Usage

```bash
# List rows
./scripts/query.sh database.db "SELECT id, name, balance FROM accounts WHERE active=1"

# Update one row
./scripts/execute.sh database.db "UPDATE accounts SET balance = balance - 100 WHERE id = 42"

# Inspect schema
./scripts/schema.sh database.db
./scripts/schema.sh database.db accounts
```

## Return format

### Success (`query.sh`)

```json
{"success": true, "data": [{"id": 1, "name": "...", "balance": 100}], "rowcount": 1}
```

### Success (`execute.sh`)

```json
{"success": true, "rowcount": 1, "message": "1 row(s) affected"}
```

### Success (`schema.sh`)

```json
{"success": true, "tables": [{"name": "accounts", "columns": [...]}]}
```

### Error

```json
{"success": false, "error": "no such table: accounts"}
```

## Safety notes

This skill executes the SQL string verbatim. There is no implicit `WHERE` clause,
no implicit `LIMIT`, no implicit dry-run. Statements like `UPDATE accounts SET
status='closed'` without a `WHERE` clause will affect every row; `DELETE FROM
users` without a `WHERE` clause will empty the table; `DROP TABLE x` is
irreversible. The caller is responsible for scoping.
