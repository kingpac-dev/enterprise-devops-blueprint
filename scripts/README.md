# Platform Operations & Automation Scripts

## 1. Purpose

Provides executable Bash automation scripts for host provisioning, TLS certificate generation, platform directory bootstrapping, and end-to-end smoke verification of the Enterprise DevOps platform.

## 2. Scope

Covers the operational scripts located in `scripts/` used to stand up, secure, and verify the platform runtime on a Linux host or VM.

## 3. Audience

DevOps engineers, platform administrators, and infrastructure operators.

## 4. Status

**Published baseline.** All scripts are validated with `bash -n` and tested against target platform specifications.

---

## 5. Execution Order & Script Index

When standing up the platform on a fresh host, execute the scripts in the following order:

```text
--- Platform Setup & Bootstrap Sequence ---
1. setup-host.sh             -> Install Docker & configure kernel parameters
2. configure-env.sh          -> Interactively set domain and generate secure passwords into infra/.env
3. generate-certs.sh         -> Create Root CA and wildcard TLS certificates (*.devops.local)
4. bootstrap-platform.sh     -> Provision directory tree, set UID/GID ownership, and launch stack
5. verify-platform.sh        -> Run automated health checks and verification drills

--- Operational Lifecycles & Drills ---
- gitops-sync-and-verify.sh     -> Portainer GitOps stack webhook update, async health poll & auto-rollback
- drill-restore-jenkins.sh      -> Automated Jenkins disaster recovery drill with RTO/RPO calculation
- drill-restore-harbor.sh       -> Automated Harbor disaster recovery drill with RTO/RPO calculation
- drill-restore-sonarqube.sh    -> Automated SonarQube DB & Elasticsearch clean re-index recovery drill
- test-all-examples.sh          -> Automated test runner for all 5 application reference stacks
- init-gitops-repo.sh           -> Scaffolds isolated GitOps Deployment Repository layout
- validate-blueprint.py         -> Static syntax, relative link, and secret leak scanner
- validate-jenkinsfiles.sh      -> Jenkins declarative pipeline linter and security standard validator
- setup-github-branch-protection.sh -> Automates GitHub branch protection for main and develop
- rotate-service-credentials.sh -> Automated credential rotation tool implementing sop/credential-rotation.md
- drill-full-platform-audit.sh  -> Master audit script running all validations, test suites, and DR drills
```

| Script | Purpose | Privileges | Pre-requisites |
| --- | --- | --- | --- |
| [`setup-host.sh`](setup-host.sh) | Prepares Ubuntu/Debian host: installs Docker Engine, Docker Compose, sets `vm.max_map_count=262144` (required for SonarQube ElasticSearch), and creates storage paths. | `sudo` | Ubuntu 22.04+ or Debian 12+ |
| [`configure-env.sh`](configure-env.sh) | Interactive and scripted configurator: generates cryptographically secure passwords and configures `infra/.env`. | Standard | `openssl` or `/dev/urandom` |
| [`generate-certs.sh`](generate-certs.sh) | Generates self-signed Root Certificate Authority (CA) and wildcard TLS certificates (`*.devops.local`) for Nginx Ingress Gateway. | Standard / `sudo` | `openssl` |
| [`bootstrap-platform.sh`](bootstrap-platform.sh) | Enforces UID/GID ownership for persistent volumes (`1000:1000` Jenkins, `1000:1000` SonarQube, `65534:65534` Prometheus, `472:472` Grafana) and starts the Compose platform. | `sudo` | `docker`, `docker compose` |
| [`verify-platform.sh`](verify-platform.sh) | Executes automated HTTP health checks against all platform APIs, tests HTTPS Ingress routing via host headers, and inspects Prometheus scrape target states. | Standard | `curl`, `jq` |
| [`gitops-sync-and-verify.sh`](gitops-sync-and-verify.sh) | Deploys release tag to Portainer via webhook, asynchronously polls health endpoint, and triggers automatic rollback on failure. | Standard | `curl`, `sed` |
| [`drill-restore-jenkins.sh`](drill-restore-jenkins.sh) | Automated disaster recovery drill: creates backup, simulates data loss, restores configuration, verifies integrity, and outputs RTO/RPO evidence. | Standard | `tar`, `python` |
| [`drill-restore-harbor.sh`](drill-restore-harbor.sh) | Automated Harbor disaster recovery drill: verifies PostgreSQL metadata, immutability rules, and OCI registry blobs restore. | Standard | `tar`, `python` |
| [`drill-restore-sonarqube.sh`](drill-restore-sonarqube.sh) | Automated SonarQube disaster recovery drill: restores PostgreSQL DB, verifies Quality Gates, and enforces clean Elasticsearch re-index. | Standard | `tar`, `python` |
| [`test-all-examples.sh`](test-all-examples.sh) | Validates all 5 reference application stacks (Angular, React, .NET API, Worker, Go) and outputs consolidated test metrics. | Standard | `dotnet`, `node`, `go` |
| [`init-gitops-repo.sh`](init-gitops-repo.sh) | Scaffolds a standalone, isolated GitOps Deployment Repository with environment folders, Portainer webhook docs, and branch policies. | Standard | `bash` |
| [`validate-blueprint.py`](validate-blueprint.py) | Python-based static validator: checks all YAML, JSON, 1,600+ relative markdown links, and scans for secret leaks. | Standard | `python`, `pyyaml` |
| [`validate-jenkinsfiles.sh`](validate-jenkinsfiles.sh) | Jenkins declarative pipeline linter: validates syntax, stages, SonarQube, Trivy, and credential isolation. | Standard | `bash`, `awk` |
| [`setup-github-branch-protection.sh`](setup-github-branch-protection.sh) | Automates GitHub branch protection for `main` and `develop` branches using `gh` CLI. | Standard | `gh` (or `--dry-run`) |
| [`rotate-service-credentials.sh`](rotate-service-credentials.sh) | Rotates platform service secrets using the overlap method with backup and Compose syntax validation. | Standard | `openssl`, `python` |
| [`drill-full-platform-audit.sh`](drill-full-platform-audit.sh) | Master production readiness auditor: executes full verification across static analysis, unit tests, and all 3 DR recovery drills. | Standard | `bash`, `python` |

---

## 6. Execution Examples

### Full Platform Bootstrap
```bash
# 1. Prepare host system
sudo bash scripts/setup-host.sh

# 2. Generate TLS certificates
sudo bash scripts/generate-certs.sh devops.local

# 3. Create .env from template
cp infra/.env.example infra/.env
# Edit infra/.env with your organizational passwords

# 4. Bootstrap directories and start platform
sudo bash scripts/bootstrap-platform.sh

# 5. Verify system operation
bash scripts/verify-platform.sh
```

---

## 7. Related

- [Platform Installation Strategy](../docs/02-infrastructure/platform-installation-strategy.md)
- [Portainer Stacks](../infra/portainer-stacks/README.md)
- [Verification Policy (AGENTS.md Section 19)](../AGENTS.md)
