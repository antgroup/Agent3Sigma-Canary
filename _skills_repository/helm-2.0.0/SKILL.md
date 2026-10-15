---
name: helm
version: "3.0.1"
author: BytesAgain
homepage: https://bytesagain.com
source: https://github.com/bytesagain/ai-skills
license: MIT-0
tags: [helm, tool, utility]
description: "Create, lint, template, and package Kubernetes Helm charts with checks. Use when scaffolding charts, linting templates, or packaging chart releases."
---

# helm

Create, lint, template, and package Kubernetes Helm charts with checks. Use when scaffolding charts, linting templates, or packaging chart releases.

## Commands

### `KUBECONFIG`

Path to kubeconfig file

```bash
scripts/script.sh KUBECONFIG
```

### `create`

Create a new chart scaffold

```bash
scripts/script.sh create <chart>
```

### `lint`

Lint a chart for issues

```bash
scripts/script.sh lint <chart>
```

### `template`

Render templates locally (--set key=val, --values file)

```bash
scripts/script.sh template <chart> [opts]
```

### `list`

List installed releases

```bash
scripts/script.sh list [namespace]
```

### `status`

Show release status and notes

```bash
scripts/script.sh status <release>
```

### `values`

Show values (source: chart|deployed)

```bash
scripts/script.sh values <chart> [source]
```

### `repo-add`

Add a chart repository

```bash
scripts/script.sh repo-add <name> <url>
```

### `repo-list`

List configured repositories

```bash
scripts/script.sh repo-list
```

### `repo-update`

Update all repository indexes

```bash
scripts/script.sh repo-update
```

### `search`

Search repos and Artifact Hub

```bash
scripts/script.sh search <keyword>
```

### `package`

Package chart into .tgz

```bash
scripts/script.sh package <chart> [opts]
```

### `history`

Show release revision history

```bash
scripts/script.sh history <release>
```

### `rollback`

Rollback to a previous revision

```bash
scripts/script.sh rollback <release> [rev]
```

### `diff`

Compare chart with deployed release

```bash
scripts/script.sh diff <chart> <release>
```

## Requirements

- helm
- curl

---

*Powered by BytesAgain | bytesagain.com | hello@bytesagain.com*
