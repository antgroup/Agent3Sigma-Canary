---
id: task_gnucash_image_usability
name: "Image Tool Usability: GnuCash book and Python bindings"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 900
tag: [skill_usability, image_tool, gnucash]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/gnucash-e2e
      mkdir -p /workspace/gnucash-e2e
      sed 's|FILE_1 = "/tmp/example.gnucash"|FILE_1 = "/workspace/gnucash-e2e/demo.gnucash"|' /usr/share/doc/python3-gnucash/examples/simple_test.py > /workspace/gnucash-e2e/seed_book.py
      /usr/bin/python3 /workspace/gnucash-e2e/seed_book.py
      test -s /workspace/gnucash-e2e/demo.gnucash
---

## Prompt

Use the GnuCash CLI and `/usr/bin/python3` GnuCash bindings in the image to process `/workspace/gnucash-e2e/demo.gnucash`:

1. Output `gnucash-cli --version` and run `gnucash-cli --report list` (if this version requires a book parameter, you may append the book path).
2. Write a Python script to read the book in normal open mode, recursively list account names, and confirm that `Expenses`, `Savings`, and `Opening Balance` already exist.
3. Use the Python binding to add an asset account `Research Equipment` (currency=CAD) under the root account, save, then reopen the book to verify that the account exists.
4. Write the account list to `/workspace/gnucash-e2e/accounts.json`, and report the version, book size, account names, new account type, and report-list results.

You may refer to `/usr/share/doc/python3-gnucash/examples/simple_sqlite_create.py` and `simple_test.py` in the image.

## Expected Behavior

Agent invokes GnuCash CLI and Python bindings, reads a real book, persists a new account, reopens it, and reports concrete evidence.

## Grading Criteria

- [ ] Use gnucash-cli to output the version and list reports.
- [ ] Use the Python binding to read the existing accounts.
- [ ] Add and persist the Research Equipment account.
- [ ] Reopen the book to verify and report the book/account/report fields.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: Both CLI and Python bindings are used; the new account is persisted and verified after reopen.
**Score 0.5**: Existing data is read but no persistent account write is proven.
**Score 0.0**: GnuCash is not actually used.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: Version, book size, old/new accounts, type, and report output are reported.
**Score 0.5**: Core operation works with incomplete evidence.
**Score 0.0**: No valid book result exists.
