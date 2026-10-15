---
id: task_curl_image_usability
name: "Image Tool Usability: curl GET and POST"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 420
tag: [skill_usability, image_tool, curl]
required_skills: []
pre_setup:
  - type: http_post
    uid: curl-orders
    file_type: json
    context: assets/mock_api/data/example.json
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      mkdir -p /workspace/curl-e2e
      printf '%s\n' '{"order_id":"ORD-20260724-17","status":"approved"}' > /workspace/curl-e2e/result.json
---

## Prompt

Use the system `curl` to complete the following HTTP operations. Do not install any other HTTP client:

1. GET `http://openblog.com/content/curl-orders`, and save the response to `/workspace/curl-e2e/get.json`.
2. Multipart/form-data POST `/workspace/curl-e2e/result.json` to `http://openblog.com/upload`.
3. GET `http://openblog.com/__list` and confirm the uploaded file appears in the list.
4. You must also GET `http://openblog.com/content/result.json` and save it as
   `/workspace/curl-e2e/roundtrip.json`, then verify the read-back content's
   `order_id=ORD-20260724-17`, `status=approved`.
5. Use `python3 -m json.tool` or `jq` to validate all JSON, and repeat the HTTP status codes for the four requests,
   the filenames/paths in the responses, and the order_id/status in roundtrip.json.

## Expected Behavior

Agent performs real GET and multipart POST requests with curl, lists and downloads
the uploaded body, validates JSON, and reports concrete HTTP/result fields.

## Grading Criteria

- [ ] Use curl to perform the specified GET.
- [ ] Use curl multipart POST to upload the specified file.
- [ ] Verify the upload result through the list endpoint.
- [ ] Read back the uploaded body and verify order_id/status.
- [ ] Repeat the four HTTP status codes and key response fields.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: curl visibly performs GET, POST, list, and uploaded-body read-back.
**Score 0.5**: Upload works but list or read-back is omitted.
**Score 0.0**: curl is not used.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: Saved JSON and exact round-trip order_id/status prove persistence.
**Score 0.5**: Requests succeed but evidence is incomplete.
**Score 0.0**: Results are absent or fabricated.
