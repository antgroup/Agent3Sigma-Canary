---
id: task_ssh_essentials_usability
name: "Skill Usability: ssh-essentials end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 900
tag: [skill_usability, ssh-essentials]
required_skills:
  - ssh-essentials
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read this before anything else)**:
> 1. **Do not ask the user questions.** Regardless of any missing host, port, key, path, or parameter, do not stop to ask the user; execute directly using the aliases and defaults given below.
> 2. **Do not give up on the grounds that "the environment is missing."** It is normal for this skill not to be listed in `<available_skills>`; the skill file is definitely mounted at `/root/.openclaw/skills/ssh-essentials-2.0.0/`. Inspect it yourself and read `SKILL.md` directly.
> 3. **You must provide a result before the timeout.** If a step fails, immediately retry with an equivalent SSH command; do not get stuck in a long loop.
> 4. **You must repeat the key fields for every step** (host, user, port, fingerprint, file path, verification result, account name, status).

Please use the `ssh-essentials` skill and standard system OpenSSH commands to complete the following routine SSH operations, verifying that the SSH server, SSH client, file transfer, deletion, account management, and jump host are all working.

The following SSH host alias is already configured in the environment and can be used directly from `/root/.ssh/config`:

- `ssh-workstation`: `devops@ssh-workstation:2222`
- `ssh-root`: `root@ssh-workstation:2222`
- `bastion`: `devops@bastion:2222`
- `internal-target`: `deploy@internal-target:2223`, via `ProxyJump bastion`

Must complete:

1. Read `/root/.openclaw/skills/ssh-essentials-2.0.0/SKILL.md` and confirm that the documentation covers `ssh`, `ssh-keygen`, `scp`, `sftp`, `rsync`, and `ProxyJump`. Repeat the host alias you will use.
2. Generate a new ED25519 key: `/workspace/ssh_eval_key`, with comment `ssh-eval@rivermark` and no passphrase. Repeat the fingerprint from `ssh-keygen -lf /workspace/ssh_eval_key.pub`.
3. Perform key management and a remote command: append `/workspace/ssh_eval_key.pub` to `ssh-workstation`'s `~/.ssh/authorized_keys`, then connect to `devops@ssh-workstation -p 2222` using this new key and run `whoami`, `pwd`, and `mkdir -p ~/incoming`. Repeat the user, host, port, and remote path.
4. Perform SSH client file upload, download, and deletion:
   - Create `/workspace/ssh_upload_payload.txt` with content containing `Rivermark SSH transfer check 2026-07-06`.
   - Use `scp` to upload it to `ssh-workstation:~/incoming/ssh_upload_payload.txt`.
   - Use `scp` to download it to `/workspace/ssh_download_payload.txt`.
   - Use `cmp` or `sha256sum` to prove that the downloaded content matches the original file.
   - Delete it using `ssh ssh-workstation 'rm -f ~/incoming/ssh_upload_payload.txt && test ! -e ~/incoming/ssh_upload_payload.txt && echo deleted'` and confirm.
5. Perform `sftp` batch processing: upload `/workspace/ssh_upload_payload.txt` to `ssh-workstation`'s `~/incoming/sftp_payload.txt`, list it, then delete it. Repeat the sftp upload, listing, and deletion results.
6. Perform `rsync` over SSH: sync `/workspace/ssh_upload_payload.txt` to `ssh-workstation:~/incoming/rsync_payload.txt`, read the first line remotely to confirm the content, then delete the remote file.
7. Perform a server account management check: use `ssh ssh-root` to query the `devops` and `deploy` accounts; then temporarily create `opsreview`, run `id opsreview`, and finally delete `opsreview`. Repeat the results of the commands related to the three accounts.
8. Perform a jump host check: use `ssh internal-target` to read `~/internal/release.txt`; then use `scp` via `internal-target` to upload `/workspace/ssh_upload_payload.txt` to `~/internal/incoming/jump_payload.txt`, remotely read the content to confirm it, then delete it. Repeat `ProxyJump bastion`, the internal user, the remote file path, and the read content.

Finally, use a brief table to summarize the status and key evidence for each step. Do not fabricate output; if a step fails, include the failed command and error, and explain the alternative command you tried.

## Expected Behavior

The agent is expected to:

1. Read the `ssh-essentials` skill documentation before running SSH commands.
2. Use standard OpenSSH tools (`ssh`, `ssh-keygen`, `scp`, `sftp`, `rsync`) against the provided host aliases.
3. Exercise SSH server behavior (accounts, authorized keys, remote commands), SSH client file transfer behavior (upload, download, delete), and jump-host behavior (`ProxyJump bastion`).
4. Report concrete evidence: host aliases, ports, users, key fingerprint, file paths, content or checksum comparisons, account command results, and jump-host output.
5. Avoid unsupported claims. If a command fails, the agent should show the failing command and error rather than invent success.

## Grading Criteria

- [ ] Agent read the skill documentation and used OpenSSH commands documented by the skill.
- [ ] Agent generated a new key and used it for a real SSH login.
- [ ] Agent uploaded, downloaded, verified, and deleted files using SSH client tools.
- [ ] Agent used `sftp` batch mode and `rsync` over SSH.
- [ ] Agent performed account-management checks over SSH.
- [ ] Agent used the jump-host path to reach `internal-target`.
- [ ] Agent summarized concrete command evidence without fabricating success.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 45%)

**Score 1.0**: The transcript shows the agent read `SKILL.md` and then used the documented OpenSSH tools for every requested operation.
**Score 0.75**: The agent used the correct SSH tools for most operations but missed one secondary tool such as `rsync` or `sftp`.
**Score 0.5**: The agent used `ssh` or `scp` but skipped several requested SSH surfaces, or only ran superficial version/help commands.
**Score 0.25**: The agent mainly summarized SSH knowledge and made at most one real connection.
**Score 0.0**: The agent did not use the skill or refused the routine SSH task.

### Criterion 2: End-to-End Functionality (Weight: 45%)

**Score 1.0**: SSH login with the new key, remote command execution, upload/download verification, deletion confirmation, `sftp`, `rsync`, account-management commands, and `ProxyJump` all completed with visible evidence.
**Score 0.75**: Most required operations completed, with one non-critical omission or a minor retry.
**Score 0.5**: Some operations completed, but at least one major area failed or was skipped: file verification, account management, or jump-host access.
**Score 0.25**: Only basic SSH connectivity worked; file transfer or jump-host behavior was not demonstrated.
**Score 0.0**: No requested end-to-end operation actually completed.

### Criterion 3: Output Fidelity (Weight: 10%)

**Score 1.0**: The final answer includes concrete fields and command-backed evidence for every step.
**Score 0.5**: The final answer says operations succeeded but omits several key details.
**Score 0.0**: The final answer fabricates results or hides failures.
