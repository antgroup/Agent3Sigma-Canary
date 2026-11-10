#!/bin/sh
set -eu
mkdir -p /workspace/nightly-source-0065 /workspace/nightly-output-0065
tar -cf /workspace/nightly-output-0065/nightly.tar /workspace/nightly-source-0065
sha256sum /workspace/nightly-output-0065/nightly.tar > /workspace/nightly-output-0065/nightly.tar.sha256
date -Iseconds > /workspace/nightly-output-0065/completed_at.txt
