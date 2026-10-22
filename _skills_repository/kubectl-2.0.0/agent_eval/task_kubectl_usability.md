---
id: task_kubectl_usability
name: "Skill Usability: kubectl end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 900
tag: [skill_usability, kubectl]
required_skills:
  - kubectl
---

## Prompt

> Execution constraints:
> 1. Do not ask the user for a cluster, token, host, namespace, pod name, or missing argument. Use the preconfigured environment and the concrete resource names below.
> 2. Do not stop because the cluster is "not configured". The kubectl skill is mounted at `/root/.openclaw/skills/kubectl-2.0.0/`; read it directly.
> 3. Run commands and report command-backed evidence. If a command fails, show the failing command, the error, and the replacement command you tried.
> 4. Keep the final response concise, but include the key fields: context, namespace, node, pod, image, replica count, rollout status, log evidence, exec output, and file path.

Use the `kubectl` skill and the `kubectl` command-line tool to validate routine Kubernetes operations in the preconfigured cluster.

Required work:

1. Read `/root/.openclaw/skills/kubectl-2.0.0/SKILL.md` and `/root/.openclaw/skills/kubectl-2.0.0/reference/REFERENCE.md`. State which command groups you will use.
2. Check basic cluster access:
   - `kubectl version --client`
   - `kubectl cluster-info`
   - `kubectl config current-context`
   - `kubectl config get-contexts`
3. Query resources:
   - list nodes with `kubectl get nodes -o wide`
   - list pods across namespaces with `kubectl get pods -A -o wide`
   - list deployments and services
   - use `kubectl get pods -o jsonpath='{.items[*].metadata.name}'`
   - use `kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory`
4. Debug the pod `web-frontend-6c8d7f9d7c-k2m4p` in namespace `default`:
   - `kubectl describe pod ...`
   - `kubectl logs ... --timestamps`
   - `kubectl exec ... -- whoami`
   - `kubectl exec ... -- cat /etc/app/version`
5. Create and manage a deployment:
   - Write `/workspace/report-api.yaml` for an `apps/v1` Deployment named `report-api`, namespace `default`, one replica, label `app: report-api`, container `api`, image `ghcr.io/rivermark/report:v1`.
   - Run `kubectl apply -f /workspace/report-api.yaml --dry-run=client`, then apply it for real.
   - Run `kubectl set image deployment/report-api api=ghcr.io/rivermark/report:v2`.
   - Run `kubectl scale deployment/report-api --replicas=3`.
   - Run `kubectl rollout status deployment/report-api` and `kubectl rollout history deployment/report-api`.
   - Verify three pods with `kubectl get pods -l app=report-api -o json`.
6. Exercise maintenance and monitoring commands:
   - `kubectl top nodes`
   - `kubectl get events -A --sort-by='.lastTimestamp'`
   - `kubectl drain worker-b --dry-run=client --ignore-daemonsets`
   - `kubectl uncordon worker-b`
7. Run helper scripts from the skill:
   - `/root/.openclaw/skills/kubectl-2.0.0/scripts/kubectl-cluster-info.sh`
   - `/root/.openclaw/skills/kubectl-2.0.0/scripts/kubectl-deploy-update.sh web-frontend web ghcr.io/rivermark/web:v2 default`

Finish with a table summarizing every step, status, and the most important evidence. Do not invent outputs.

## Expected Behavior

The agent is expected to read the mounted skill documentation, use the `kubectl` CLI for real command execution, create a manifest in `/workspace`, apply and update a deployment, inspect logs and pod details, use output formats, run maintenance commands, and execute the bundled helper scripts.

## Grading Criteria

- [ ] Agent read both `SKILL.md` and `reference/REFERENCE.md`.
- [ ] Agent used kubectl for cluster access, config, resource query, output formatting, logs, exec, apply, set image, scale, rollout, events, top, drain, and uncordon.
- [ ] Agent created `/workspace/report-api.yaml` with the requested Deployment fields and applied it.
- [ ] Agent verified the deployment update and replica count with command output.
- [ ] Agent ran both required helper scripts.
- [ ] Final summary contains concrete command-backed evidence and does not hide failures.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 35%)

**Score 1.0**: The transcript shows the agent read both skill documents and used kubectl commands from the skill for all major operations.
**Score 0.75**: The agent read the main skill doc and used kubectl for most operations but missed the reference doc or one command group.
**Score 0.5**: The agent used kubectl superficially but mostly summarized what it would do.
**Score 0.25**: The agent mentioned kubectl but ran few or no meaningful commands.
**Score 0.0**: The agent did not use the skill or kubectl.

### Criterion 2: End-to-End Functionality (Weight: 50%)

**Score 1.0**: Cluster checks, resource queries, pod debugging, manifest apply, image update, scale, rollout checks, events/top/drain/uncordon, and both helper scripts all completed with visible evidence.
**Score 0.75**: Most required operations completed, with one non-critical omission or a handled retry.
**Score 0.5**: Some commands succeeded, but a major area such as deployment lifecycle, pod debugging, or helper scripts was skipped.
**Score 0.25**: Only basic read-only commands were executed.
**Score 0.0**: No end-to-end kubectl workflow completed.

### Criterion 3: Output Fidelity (Weight: 15%)

**Score 1.0**: The final answer includes concrete context, resource names, images, replica counts, rollout status, log lines, exec output, and helper-script evidence.
**Score 0.5**: The final answer claims success but omits several important fields.
**Score 0.0**: The final answer fabricates outputs, hides failures, or substitutes generic Kubernetes advice for command evidence.
