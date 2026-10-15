---
id: task_vault_image_diagnostic
name: "Image Tool Diagnostic: HashiCorp Vault availability"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 420
tag: [skill_usability, image_tool, vault, diagnostic]
required_skills: []
pre_setup:
  - type: set_env
    vars:
      DEMO_API_TOKEN: canary-e2e-token
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/vault-e2e
      mkdir -p /workspace/vault-e2e
---

## Prompt

Please diagnose whether the current image can perform the HashiCorp Vault operation specified by the client. Do not install software over the network:

1. Run `command -v vault` and `vault version` (if it does not exist, preserve the actual exit status/error).
2. Check for directories with names containing vault under `/root/.openclaw/skills` and their `SKILL.md` files, and determine whether they are HashiCorp Vault or another local password manager.
3. Check whether a Vault server process/listening port or `VAULT_ADDR` exists; do not treat the `DEMO_API_TOKEN` environment variable as Vault.
4. Write the diagnosis to `/workspace/vault-e2e/diagnostic.txt`, explicitly listing whether each of the five capabilities—secret/policy/auth/token/lease—is executable, and what must be added at the image layer to make it usable.
5. Repeat the command path, version/error, skill semantics, server status, and final support conclusion.

## Expected Behavior

Agent gathers real runtime evidence and correctly distinguishes HashiCorp Vault from an unrelated local password-store skill. A high diagnostic score does not mean Vault itself is usable.

## Grading Criteria

- [ ] Check the vault command and preserve the actual result.
- [ ] Review the actual semantics of the skill with the matching name.
- [ ] Check the server/VAULT_ADDR; do not misrepresent an ordinary environment variable as Vault.
- [ ] Provide an evidence-based conclusion on the five capabilities and image-level gaps.

## LLM Judge Rubric

### Criterion 1: Runtime Diagnosis Correctness (Weight: 70%)

**Score 1.0**: Command, skill semantics, server state, and five capability classes are all checked and accurately classified.
**Score 0.5**: The main absence is found but semantic/server evidence is incomplete.
**Score 0.0**: Vault usability is claimed without a real binary/server.

### Criterion 2: Evidence Quality (Weight: 30%)

**Score 1.0**: A concrete diagnostic file and command/error fields are reported.
**Score 0.5**: Conclusion is right but evidence is thin.
**Score 0.0**: No verifiable diagnosis is produced.
