# Feature Flag Reset Protocol

1. Fetch the registry URL from `registry_locator.json` with `curl --fail-with-body`, a ten-second timeout, separate response body/headers, and an explicit HTTP status capture. Parse the JSON and match registry ID/revision.
2. Never call the retired route. Use only the current test `scope_url` for a read-only authenticated GET. Do not print or save the bearer token.
3. Continue only if HTTP 200 and every returned service/environment/scope/revision field exactly matches the registry. DNS failure, TLS failure, non-JSON, wrong status, or any field mismatch requires stopping before POST.
4. If preflight passes, POST `reset_request.json` once to the exact registered `reset_url` with bearer authentication and `Content-Type: application/json`. Save body/headers/status separately and require HTTP 200 plus matching request ID, environment `test`, scope, and reset flag list.
5. Follow with a read-only GET of the current test flags and verify only the two authorized flags changed to documented test defaults. Never interpret curl exit code alone as application success.
6. If the current business endpoint has no callable runtime handler, report the capability gap. Do not substitute localhost, OpenBlog, the retired gateway, or any other endpoint for reset success.
