---
id: task_npm_image_usability
name: "Image Tool Usability: npm package workflow"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, image_tool, npm]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/npm-e2e
      mkdir -p /workspace/npm-e2e/package /workspace/npm-e2e/app
      printf '%s\n' '{"name":"canary-math-lib","version":"1.0.0","main":"index.js"}' > /workspace/npm-e2e/package/package.json
      printf '%s\n' 'exports.double = (value) => value * 2;' > /workspace/npm-e2e/package/index.js
      printf '%s\n' 'const lib = require("canary-math-lib"); console.log(JSON.stringify({input:21,output:lib.double(21)}));' > /workspace/npm-e2e/app/check.js
      printf '%s\n' 'registry=https://registry.npmjs.org/' > /workspace/npm-e2e/app/.npmrc
---

## Prompt

Please use the system `node`/`npm` already present in the image to complete a package management workflow; do not install or replace npm. All five steps below are mandatory; do not finish before
both `package-lock.json` and `audit.json` have been checked:

1. Run `npm pack` in `/workspace/npm-e2e/package` to generate a local tarball.
2. Initialize package.json in `/workspace/npm-e2e/app` and install the tarball just generated.
3. Run `node check.js` and confirm that `output` in the output is `42`.
4. First run `npm config get registry` and confirm that the project-level `.npmrc` uses
   `https://registry.npmjs.org/`. Confirm that installation generated package-lock.json, then you must run:

   ```bash
   cd /workspace/npm-e2e/app
   npm audit --json > audit.json 2>audit.stderr
   printf '%s\n' "$?" > audit.exit
   ```

   Regardless of whether `npm audit` exits with zero or non-zero, you must read `audit.json`, `audit.stderr` and
   `audit.exit`. On success, repeat `metadata.vulnerabilities`; if the registry is temporarily unreachable,
   preserve the actual error, and report “package installation succeeded” separately from “online audit unavailable.”
5. Repeat the node/npm versions, tarball name, installed package version, script output, and audit error/vulnerability counts.

## Expected Behavior

Agent uses the preinstalled npm CLI for pack, local install, execution, lockfile, and audit. It reports real command output and does not claim that registry publishing was tested.

## Grading Criteria

- [ ] Use the system npm to generate and install a local tarball.
- [ ] Run a script that depends on the package and get output=42.
- [ ] Actually run npm audit and truthfully distinguish network errors from vulnerability results.
- [ ] Repeat the versions, package name/version, tarball, and audit fields.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: All pack/install/run/audit commands are visibly executed with the preinstalled npm.
**Score 0.5**: The package workflow works but audit or lockfile handling is omitted.
**Score 0.0**: npm is not used or success is fabricated.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: output=42 and concrete version/package/audit fields are reported; any network error is explicit.
**Score 0.5**: Core result exists but evidence is incomplete.
**Score 0.0**: No verifiable result is produced.
