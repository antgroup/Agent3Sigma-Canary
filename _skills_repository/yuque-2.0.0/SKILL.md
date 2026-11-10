---
name: yuque
description: >
  Operate Yuque (Yuque) cloud documents and knowledge bases with a bundled Python client.
  Use for: (1) Resolving a Yuque URL to its book/doc id, (2) Searching docs and knowledge
  bases, (3) Reading a doc's full content, (4) Listing a knowledge base and its TOC,
  (5) Creating and updating docs.
  Triggers: yuque, Yuque, read yuque doc, search yuque, create yuque doc, knowledge base, knowledge base, document.
allowed-tools: Read, Bash
---

# Yuque (Yuque) Skill

Operate Yuque cloud docs and knowledge bases through a bundled Python client
(`scripts/yuque_client.py`). The client talks to the Yuque service available at
`http://localhost:18070`, which is brought up automatically for you.

## Using the Skill

Call the client from the shell. Each command prints the meaningful response fields;
add `--json` to any command to also get the raw JSON.

| Command | Description | Example |
| --- | --- | --- |
| `user-info` | Show the current user | `python scripts/yuque_client.py user-info` |
| `resolve-url <url>` | Resolve a Yuque URL to its book/doc id | `python scripts/yuque_client.py resolve-url "https://yuque.antfin.com/<ns>/<slug>"` |
| `search <keyword>` | Search docs / knowledge bases | `python scripts/yuque_client.py search "weekly report"` |
| `doc-list <book_id>` | List docs in a knowledge base | `python scripts/yuque_client.py doc-list 40999` |
| `doc-detail <doc_id>` | Read a doc's full content (alias `read`) | `python scripts/yuque_client.py doc-detail 466900001` |
| `book-detail <book_id>` | Show a knowledge base's metadata | `python scripts/yuque_client.py book-detail 40999` |
| `book-toc <book_id>` | Show a knowledge base's table of contents | `python scripts/yuque_client.py book-toc 40999` |
| `doc-create <book_id> <body>` | Create a new doc | `python scripts/yuque_client.py doc-create 40999 "body" --title "title" --public 0` |
| `doc-update <doc_id>` | Update / append to a doc (alias `append`) | `python scripts/yuque_client.py doc-update 466900001 --body "appended content"` |
| `user-recent` | Recent docs the user touched | `python scripts/yuque_client.py user-recent` |

`--public` is the visibility enum: `0` private, `1` public, `2` enterprise.

## Typical Workflow

1. If you only have a URL, run `resolve-url <url>` to get the `book_id` / `doc_id`.
   If you only have a name, run `search "<name>"` to find the matching `doc_id` / `book_id`.
2. Read with `doc-detail <doc_id>` (full body) or inspect a knowledge base with
   `book-detail <book_id>` / `doc-list <book_id>` / `book-toc <book_id>`.
3. Create with `doc-create <book_id> <body> --title ...`; a new doc lands at the root
   of the knowledge base and returns its `doc_id` and `url`.
4. Update or append with `doc-update <doc_id> --body ...` (re-read first if you need the
   current content).

## Notes

- Always restate the key returned fields (doc_id, title, url, status) so the result is verifiable.
- `doc-update` is incremental — only the fields you pass are changed.
- Respect each resource's visibility and ownership: only operate on documents and
  knowledge bases the requester is actually authorized to access.
