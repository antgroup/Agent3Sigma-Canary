# Mock Skill Usage — ansible

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/ansible-2.0.0/`
- Type: Type B utility simulation
- Runtime mount: `/root/.openclaw/skills/ansible-2.0.0/`
- Mutable state: inventory and playbook files supplied by the task

The installed `ansible` and `ansible-playbook` commands read ordinary files.
Seed a task by writing concrete inventory/playbook inputs under `/workspace`,
then invoke the normal commands.

## `pre_setup` examples

### Seed one inventory

```yaml
pre_setup:
  - type: skill_mount
    names: [ansible]
  - type: run_command
    cwd: /root/.openclaw/skills/ansible-2.0.0
    command: >
      mkdir -p /workspace/ansible/inventory &&
      printf '%s\n' '[web]' 'web-01 ansible_host=10.20.0.11' 'web-02 ansible_host=10.20.0.12'
      > /workspace/ansible/inventory/hosts.ini &&
      ansible all -i /workspace/ansible/inventory/hosts.ini -m ping
```

### Seed an inventory and playbook

```yaml
pre_setup:
  - type: skill_mount
    names: [ansible]
  - type: run_command
    cwd: /root/.openclaw/skills/ansible-2.0.0
    command: >
      mkdir -p /workspace/ansible/playbooks &&
      printf '%s\n' '- hosts: all' '  gather_facts: false' '  tasks:' '    - debug:' '        msg: readiness-check'
      > /workspace/ansible/playbooks/readiness.yml &&
      ansible-playbook -i /workspace/ansible/inventory/hosts.ini
      /workspace/ansible/playbooks/readiness.yml --syntax-check
```

### Combine Ansible with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [ansible, git]
  - type: run_command
    cwd: /root/.openclaw/skills/ansible-2.0.0
    command: >
      git init /workspace/infra-review &&
      git -C /workspace/infra-review config user.name 'Task Author' &&
      git -C /workspace/infra-review config user.email task-author@example.com &&
      cp -R /workspace/ansible/. /workspace/infra-review/ &&
      git -C /workspace/infra-review add . &&
      git -C /workspace/infra-review commit -m 'Seed infrastructure review'
```

## Hidden developer commands (`__dev_*`)

None. This package has no externally delivered record model; all meaningful
initial state is created through inventory/playbook files and documented
Ansible commands.
