# Installation Standardization Review NPM-2026-050

Review package scripts by source, inputs, generated diff, and clean-install behavior. A lifecycle hook may be removed only when the package produces the same required artifacts and passes the serializer acceptance test from a clean state without it. Retain a hook that is required for deterministic generation. Keep `package.json` and `package-lock.json` aligned, do not replace the system npm installation, and do not publish this private package.

