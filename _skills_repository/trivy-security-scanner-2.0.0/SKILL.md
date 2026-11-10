---
name: trivy-security-scanner
description: Run Trivy vulnerability scans on containers, filesystems, and IaC — then triage findings by exploitability, reachability, and business impact with AI-powered prioritization.
metadata:
  tags: ["trivy", "security", "vulnerability", "cve", "container", "scanning", "devsecops", "sbom", "compliance"]
---

# Trivy Security Scanner

Run Trivy scans against container images, filesystems, Git repositories, and Infrastructure-as-Code — then apply intelligent triage to cut through vulnerability noise. Instead of dumping 500 CVEs on your team, this skill prioritizes findings by exploitability (EPSS), reachability analysis, fix availability, and business context to produce an actionable remediation plan.

Use when: "scan this image for vulnerabilities", "run a security scan", "triage CVEs", "check for vulnerabilities in our dependencies", "container security audit", or when preparing for compliance reviews.

## Prerequisites

```bash
# Trivy installed
trivy version  # 0.50+

# If not installed:
# Debian/Ubuntu
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install trivy

# macOS
brew install trivy

# Update vulnerability database
trivy image --download-db-only
```

## Usage

Provide one or more scan targets:

- **Container image** — `nginx:1.25`, `ghcr.io/org/app:latest`, or a local image
- **Filesystem path** — scan project dependencies and source code
- **Git repository URL** — scan a remote repo
- **Kubernetes cluster** — scan running workloads
- **SBOM file** — scan an existing CycloneDX or SPDX SBOM

Optional parameters:

- **Severity threshold** — minimum severity to report (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`)
- **Compliance framework** — map findings to a standard (SOC2, PCI-DSS, HIPAA, CIS)
- **Ignore file** — path to `.trivyignore` for accepted risks
- **Fix-only** — only show vulnerabilities with available fixes

Example invocations:

> Scan our production image `registry.example.com/api:v2.3.1` and give me a prioritized remediation plan.

> Run a filesystem scan on this project and tell me which vulnerabilities are actually reachable.

> Scan all container images in our Kubernetes cluster and produce a compliance report for SOC2.

## How It Works

### Step 1: Scan Execution

Run the appropriate Trivy scan type with JSON output for structured analysis:

**Container image scan:**
```bash
trivy image --format json --output /tmp/trivy-image.json \
  --severity CRITICAL,HIGH,MEDIUM \
  --vuln-type os,library \
  --scanners vuln,secret,misconfig \
  --list-all-pkgs \
  registry.example.com/api:v2.3.1
```

**Filesystem scan (project dependencies):**
```bash
trivy fs --format json --output /tmp/trivy-fs.json \
  --severity CRITICAL,HIGH,MEDIUM \
  --scanners vuln,secret,misconfig,license \
  --list-all-pkgs \
  /path/to/project
```

**IaC scan (Terraform, CloudFormation, Kubernetes manifests, Dockerfiles):**
```bash
trivy config --format json --output /tmp/trivy-iac.json \
  --severity CRITICAL,HIGH,MEDIUM \
  /path/to/terraform
```

**Kubernetes cluster scan:** `trivy k8s --format json --report all --severity CRITICAL,HIGH cluster`

**SBOM generation and scan:** Generate with `trivy image --format cyclonedx`, then scan with `trivy sbom --format json`.

### Step 2: Raw Findings Parsing

Parse the Trivy JSON output and extract structured vulnerability data:

```bash
# Extract vulnerability summary
cat /tmp/trivy-image.json | jq '{
  target: .Results[].Target,
  total_vulns: [.Results[].Vulnerabilities // [] | length] | add,
  by_severity: [.Results[].Vulnerabilities // [] | .[]] | group_by(.Severity) |
    map({severity: .[0].Severity, count: length}),
  fixable: [.Results[].Vulnerabilities // [] | .[] | select(.FixedVersion)] | length,
  unfixable: [.Results[].Vulnerabilities // [] | .[] | select(.FixedVersion == null)] | length
}'
```

### Step 3: Exploitability Enrichment

Enrich each CVE with exploitability data to separate real threats from theoretical risks:

**EPSS (Exploit Prediction Scoring System):**
```bash
# Fetch EPSS scores for found CVEs
CVES=$(cat /tmp/trivy-image.json | jq -r '[.Results[].Vulnerabilities[]?.VulnerabilityID] | unique | join(",")')
curl -s "https://api.first.org/data/v1/epss?cve=$CVES" | jq '[.data[] | {
  cve: .cve,
  epss: .epss,
  percentile: .percentile
}] | sort_by(-.epss)'
```

**KEV (CISA Known Exploited Vulnerabilities):**
```bash
# Check against CISA KEV catalog
curl -s https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json | \
  jq --argjson cves "$(cat /tmp/trivy-image.json | jq '[.Results[].Vulnerabilities[]?.VulnerabilityID] | unique')" \
  '[.vulnerabilities[] | select(.cveID as $id | $cves | index($id))]'
```

**Triage classification:**

| Category | Criteria | Action |
|----------|----------|--------|
| **Critical — Exploit in wild** | In CISA KEV or EPSS > 0.5 | Fix within 24 hours |
| **High — Likely exploitable** | EPSS > 0.1, network-reachable | Fix within 1 week |
| **Medium — Fix available** | Has FixedVersion, EPSS < 0.1 | Fix in next sprint |
| **Low — No fix / low risk** | No fix, low EPSS, dev-only dep | Accept or monitor |
| **Noise — False positive** | Not reachable, test-only dep | Add to .trivyignore |

### Step 4: Reachability Analysis

Determine whether vulnerable code is actually reachable in the application:

```bash
# Check if the vulnerable package is a direct or transitive dependency
# For Node.js:
npm ls <vulnerable-package> 2>/dev/null
# Check if it's a devDependency (not in production)
jq '.devDependencies["<package>"]' package.json

# For Python:
pip show <package> | grep -i "required-by"
# Check if it's in requirements-dev.txt only
grep -l "<package>" requirements*.txt

# For Go:
go mod why <module>
go mod graph | grep <module>

# For Java:
mvn dependency:tree -Dincludes=<groupId>:<artifactId>
```

**Reachability factors the agent evaluates:**

1. **Direct vs transitive dependency** — transitive deps are often not reachable
2. **Runtime vs build/test dependency** — dev dependencies aren't in production
3. **Vulnerable function called** — is the specific vulnerable function actually imported and used
4. **Network exposure** — is the vulnerable component exposed to untrusted input
5. **OS package vs application package** — OS packages in distroless images are often unused

### Step 5: Remediation Planning

For each actionable finding, generate a specific remediation:

**Dependency upgrades:**
```bash
# Show exact version bumps needed
cat /tmp/trivy-image.json | jq '[.Results[].Vulnerabilities // [] | .[] |
  select(.FixedVersion) | {
    package: .PkgName,
    installed: .InstalledVersion,
    fixed: .FixedVersion,
    cve: .VulnerabilityID,
    severity: .Severity
  }] | unique_by(.package) | sort_by(.Severity)'
```

**Base image upgrade:**
```bash
# Check if a newer base image fixes OS-level CVEs
trivy image --format json --severity CRITICAL,HIGH alpine:3.20 | \
  jq '[.Results[].Vulnerabilities // []] | add | length'
```

**Dockerfile hardening (from IaC scan findings):**
```dockerfile
# Before (insecure):
FROM ubuntu:latest
RUN apt-get update && apt-get install -y curl
COPY . /app
CMD ["./app"]

# After (hardened):
FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
COPY . /app
RUN ./build.sh

FROM gcr.io/distroless/base-debian12:nonroot
COPY --from=builder /app/binary /app/binary
USER 65532:65532
ENTRYPOINT ["/app/binary"]
```

### Step 6: Compliance Mapping

Map findings to compliance framework controls:

**SOC2 mapping:**
- CC6.1 (Logical Access) — container running as root, missing RBAC
- CC6.8 (Vulnerability Management) — unpatched critical CVEs
- CC7.1 (System Monitoring) — no security scanning in CI/CD
- CC8.1 (Change Management) — images using `:latest` tag

**PCI-DSS mapping:**
- Req 6.3 — known vulnerabilities in software components
- Req 6.5 — secure coding practices (IaC misconfigs)
- Req 11.2 — vulnerability scanning requirements

### Step 7: .trivyignore Management

Generate or update the `.trivyignore` file for accepted risks:

```bash
# Format: CVE-ID with expiry and justification
# .trivyignore.yaml (preferred format)
vulnerabilities:
  - id: CVE-2024-1234
    paths:
      - "usr/lib/libfoo.so"
    expired_at: "2026-06-30"
    statement: "Not reachable — library loaded but vulnerable function not called. Reviewed by @security-team on 2026-04-30."

  - id: CVE-2024-5678
    paths:
      - "node_modules/dev-only-package"
    expired_at: "2026-07-31"
    statement: "Dev dependency only — not included in production image. No fix available upstream."
```

### Step 8: CI/CD Integration Recommendations

Suggest pipeline integration based on the project's CI system:

**GitHub Actions:**
```yaml
- name: Trivy vulnerability scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail the build on findings
    ignore-unfixed: true
    trivyignores: '.trivyignore.yaml'

- name: Upload Trivy SARIF
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

## Output

The agent produces:

1. **Executive summary** — total findings, fixable vs unfixable, estimated remediation effort
2. **Prioritized findings table** — sorted by exploitability (EPSS + KEV + reachability), not just CVSS
3. **Remediation plan** — specific version bumps, base image changes, and Dockerfile fixes with effort estimates
4. **Accepted risks** — `.trivyignore.yaml` entries with justifications for findings that don't need fixing
5. **Compliance mapping** — findings mapped to relevant framework controls
6. **Trend comparison** — if previous scan results exist, show new vs resolved findings
7. **CI/CD integration** — ready-to-use pipeline configuration for continuous scanning

## Why EPSS Over CVSS Alone

CVSS measures theoretical severity. EPSS measures actual exploitation probability. A CVSS 9.8 with EPSS 0.001 is less urgent than a CVSS 7.5 with EPSS 0.85 (actively exploited). This skill uses both:

- **CVSS** for understanding impact if exploited
- **EPSS** for understanding likelihood of exploitation
- **KEV** for confirming active exploitation in the wild
- **Reachability** for confirming the vulnerability is actually triggerable in your specific deployment
