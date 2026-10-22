---
id: task_hledger_image_usability
name: "Image Tool Usability: hledger CSV import and reports"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, image_tool, hledger]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/hledger-e2e
      mkdir -p /workspace/hledger-e2e
      printf '%s\n' '2026-07-24 Opening balance' '    assets:bank  1000 CNY' '    equity:opening' > /workspace/hledger-e2e/main.journal
      printf '%s\n' 'date,description,amount' '2026-07-25,Office supplies,-125' > /workspace/hledger-e2e/bank.csv
      printf '%s\n' 'skip 1' 'fields date, description, amount' 'date-format %Y-%m-%d' 'currency CNY' 'account1 assets:bank' 'account2 expenses:uncategorized' > /workspace/hledger-e2e/bank.rules
      hledger -f /workspace/hledger-e2e/main.journal check
  - type: set_env
    vars:
      HLEDGER_FILE: /workspace/hledger-e2e/main.journal
---

## Prompt

Use the system hledger to complete the ledger and CSV import:

1. Output the version and run `check` and `balance` on `$HLEDGER_FILE`.
2. Use `/workspace/hledger-e2e/bank.rules` to run `import --dry-run` on `bank.csv` first, and confirm that it will generate an `Office supplies` transaction.
3. Run the import, then run `check` again, and output `balance`, `register assets:bank`, and `print`.
4. Save the final balance to `/workspace/hledger-e2e/balance.txt`.
5. Recap the version, imported transaction description/amount, final `assets:bank` balance (875 CNY), and check status.

## Expected Behavior

Agent uses hledger for validation, dry-run import, real import, and reporting against the seeded journal.

## Grading Criteria

- [ ] `hledger check` and the initial balance succeeded.
- [ ] The CSV dry run shows Office supplies/-125 CNY.
- [ ] Complete the import and recheck.
- [ ] Final `assets:bank`=875 CNY; report evidence is complete.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: check, dry-run import, real import, and reports are all executed with hledger.
**Score 0.5**: Reports work but import is not completed.
**Score 0.0**: hledger is not used.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: Imported transaction and exact 875 CNY balance are reported with version/check evidence.
**Score 0.5**: Core result works with incomplete evidence.
**Score 0.0**: Result is wrong or absent.
