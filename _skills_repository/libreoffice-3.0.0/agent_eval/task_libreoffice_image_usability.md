---
id: task_libreoffice_image_usability
name: "Image Tool Usability: LibreOffice headless conversion and UNO"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, image_tool, libreoffice]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/libreoffice-e2e
      mkdir -p /workspace/libreoffice-e2e/input /workspace/libreoffice-e2e/output /workspace/libreoffice-e2e/profile
      printf '%s\n' '# Quarterly Review' '' 'Revenue status: approved.' '' '- Owner: Finance' > /workspace/libreoffice-e2e/input/report.md
      pandoc /workspace/libreoffice-e2e/input/report.md -o /workspace/libreoffice-e2e/input/report.docx
      test -s /workspace/libreoffice-e2e/input/report.docx
---

## Prompt

Please use the LibreOffice in the image to process documents in headless mode:

1. Output `libreoffice --version`.
2. Use the independent profile `/workspace/libreoffice-e2e/profile` to convert `input/report.docx` to `output/report.pdf`.
3. Then convert the same DOCX to `output/report.txt` and check that the text contains `Quarterly Review` and `Revenue status: approved`.
4. Use the system `/usr/bin/python3` to execute `import uno` and output the UNO module path.
5. Repeat the version, the paths/sizes of the two output files, the text validation result, and the UNO import result. Do not launch the GUI.

## Expected Behavior

Agent uses LibreOffice in headless mode with an isolated profile, produces real PDF/text artifacts, validates content, and proves the system Python UNO binding imports.

## Grading Criteria

- [ ] Use LibreOffice headless to convert DOCX to PDF.
- [ ] Convert and validate the text content.
- [ ] Successfully import uno using /usr/bin/python3.
- [ ] Repeat the version, paths, sizes, and validation fields.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: Headless LibreOffice performs both conversions and system Python imports UNO.
**Score 0.5**: One conversion works but UNO or content validation is missing.
**Score 0.0**: LibreOffice is not invoked.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: Non-empty artifacts and exact content/version/path evidence are reported.
**Score 0.5**: Artifacts exist but evidence is thin.
**Score 0.0**: No usable artifact exists.
