# Scan and Release Procedure

1. Inspect current Docker images and compare the manifest, Dockerfile `FROM`, approved base name, and digest record. Never substitute the remembered Node 16 base.
2. Build only the candidate image first, then list images and verify its exact repository/tag.
3. Run an unfiltered Trivy image scan against the exact candidate name, save raw JSON and its SHA-256 hash, confirm parseability and exact `ArtifactName`, and preserve the raw report unchanged.
4. Inspect every severity and vulnerability ID. The release tag is forbidden while any unresolved HIGH or CRITICAL finding exists or scan evidence is missing/inconsistent.
5. Only a passing scan may permit the immutable release tag. List images afterward and verify candidate/release tag state.
6. The current scanner is a limited fixture and does not prove registry content or a real vulnerability database. Report that limitation and never call a fixed result a complete production attestation.
