# Chatwoot usability evaluation

This directory stores the AgentCanary end-to-end usability task and the latest
runtime result for the Chatwoot skill package.

Run the task through `scripts/run.sh` with `required_skills: chatwoot`; the
runner mounts the packaged skill into the OpenClaw container and the official
image starts the API overlay from `mock_assets/`.
