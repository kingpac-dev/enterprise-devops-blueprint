# Changelog

All notable changes to the Enterprise DevOps Blueprint are recorded in this file.

Format is based on Keep a Changelog conventions. Versioning follows the policy described in [README.md](README.md#11-versioning-policy).

Version impact:

| Change | Impact |
| --- | --- |
| A requirement is added, tightened, or removed in a way that breaks existing adopters | MAJOR |
| A new standard, template, or document is added without breaking adopters | MINOR |
| Clarification, correction, or editorial change | PATCH |

---

## [Unreleased]

## [v1.0.0] - 2026-09-04

### Added — Full Production Readiness Baseline

- **Cross-Cutting Standards (`standards/`)**: Published `naming-conventions.md`, `environment-identifiers.md`, and `documentation-standard.md`. Establishes canonical rules for Git repositories, branch naming, container image tagging, Harbor hierarchy, environment boundaries (`DEV`, `UAT`, `PROD`), code/config block standards, document maturity lifecycle, and terminology precision.
- **Architecture Diagrams (`architecture/diagrams/`)**: Published `ci-pipeline.md`, `cd-pipeline.md`, `network-flows.md`, and `observability-flow.md`. All 6 platform architectural diagrams are now complete, validated in Mermaid, and diffable.
- **Architecture Decision Support (`architecture/decisions/`)**: Published comparative analyses supporting key ADRs: `adr-0002-harbor-registry-comparison.md` (Harbor vs Nexus vs Artifactory), `adr-0005-runtime-platform-options.md` (Compose+Portainer vs K8s vs Nomad), and `adr-0010-gitops-convergence-analysis.md` (GitOps convergence loop, lag, and rollback).
- **Complete Application Reference Implementations (`examples/`)**: Added `react-vite/` (React 18 + TypeScript + Vite with dynamic runtime config injection via window object) and `go-fiber/` (Go 1.22 + Fiber REST API with `/healthz`, `/readyz`, `/metrics`, and non-root static binary). All 5 application types mandated by `AGENTS.md` (Angular, React, .NET API, Go Fiber, .NET Worker) now possess full working reference implementations with passing automated unit tests.
- **Platform Infrastructure as Code (`infra/`)**: Generated production-grade Docker Compose stacks for Core Toolchain (Jenkins JCasC, SonarQube LTS, PostgreSQL 15, Portainer CE), Observability (Prometheus, Grafana, Loki, Promtail, cAdvisor, Node Exporter), and Edge Ingress (Nginx TLS Reverse Proxy).
- **Portainer.io "Create Stack" Support (`infra/portainer-stacks/`)**: Provided zero-build Portainer stack manifests (`stack-devops-all-in-one.yml`, `stack-core-devops.yml`, `stack-observability.yml`, `stack-gateway-proxy.yml`), ready-to-paste environment variables (`portainer-env.txt`), and Portainer Custom App Template definition (`portainer-templates.json`).
- **Platform Automation Scripts (`scripts/`)**: Added `configure-env.sh` (interactive/scripted environment & credential generator), `gitops-sync-and-verify.sh` (Portainer webhook trigger, async health poll, and auto-rollback controller per ADR-0010), `drill-restore-jenkins.sh` (automated Jenkins recovery drill), `drill-restore-harbor.sh` (automated Harbor registry recovery drill), `drill-restore-sonarqube.sh` (automated SonarQube DB & Elasticsearch clean re-index drill), `test-all-examples.sh` (unified test runner for all 5 stacks), `init-gitops-repo.sh` (isolated GitOps repository scaffolder), `validate-blueprint.py` (static validator and secret scanner), `drill-full-platform-audit.sh` (master audit runner), `setup-host.sh`, `generate-certs.sh`, `bootstrap-platform.sh`, `verify-platform.sh`, and `scripts/README.md`.
- **Observability Notification & Silent Failure Prevention (`templates/monitoring/`)**: Published `dead-mans-snitch.md` (inverted heartbeat standard), `heartbeat-probe.sh` (cron probe script), `alertmanager.example.yml` (production Alertmanager config with routing, inhibit rules, and receivers), and `alertmanager-templates.md` (Slack/Teams channel guidance).
- **Templates Status**: Published all templates across 7 categories (`jenkins/`, `docker/`, `compose/`, `sonar/`, `security/`, `monitoring/`, `project-template/`) and updated `templates/README.md` to Published status.

- CI/CD standards in `docs/05-ci-cd/`, network documentation in `docs/03-network/`, and operational runbooks in `docs/09-operations/`. Drafts. The parts that depend on the undecided deployment mechanism are written as per-option tables rather than left blank — and doing so surfaced that pull-based deployment (option C in `adr/0009`) changes the CD standard itself, because deployment becomes asynchronous and health verification then needs an explicit feedback path.
- Reference examples in `examples/`: a .NET Worker, a .NET Web API, and the Angular runtime-configuration files. Each addresses one specific failure the blueprint exists to prevent, rather than teaching the framework. **The .NET examples build with warnings-as-errors and their tests pass (9 and 9); the Angular example type-checks under `strict` and its tests pass (7).** No container image has been built.
- Infrastructure standards in `docs/02-infrastructure/`: `infrastructure-standard.md`, `server-sizing-guideline.md`, `platform-installation-strategy.md`, and `high-availability-roadmap.md`. Drafts. No host has been built and no workload measured, so sizing figures are labelled as starting points and the growth drivers are given instead.
- Platform runbooks in `runbooks/`: Jenkins backup/restore and upgrade, Harbor restore and storage management, SonarQube maintenance, and observability stack recovery. Drafts. **None has ever been executed** — they are written from design, and their first execution is itself the first restore test.
- Project template in `templates/project-template/`: application `README`, project `AGENTS.md`, release notes template, `VERSION`, and per-language ignore rules. With the other template directories, a new repository can be assembled today except for its deployment configuration.
- Standard operating procedures in `sop/`: restore test, credential rotation, access request, access review, offboarding, new-project provisioning, and scheduled maintenance. Drafts; frequencies and approving roles are `TBD`. These close procedural `TBD` items deferred from the security and governance standards. Several depend on a credential inventory that does not yet exist.
- Jenkins pipeline templates in `templates/jenkins/`: a heavily commented generic reference plus one per application type. Stages from checkout through publication are complete; deploy, health verification, and rollback are explicit stubs blocked by `adr/0009`. The .NET templates place static analysis so that it wraps build and test, because the .NET scanner hooks the compiler — running it afterwards produces an analysis with no results and a Quality Gate that passes on nothing. Structurally checked only; no Groovy or Jenkins is available in the authoring environment, so none has been parsed or executed.
- SonarQube, security, and monitoring templates in `templates/sonar/`, `templates/security/`, and `templates/monitoring/`: 11 files covering scanner configuration, exception format, SBOM generation, secret scanning, Prometheus scrape and alert rules, a Grafana service dashboard, and Loki label conventions. Drafts; every threshold is `TBD`. YAML and JSON are validated for syntax and structure; the dashboard palette is validated computationally for colour-vision separation rather than by eye. No template has been executed against a real Trivy, SonarQube, Prometheus, or Grafana.
- Container templates in `templates/docker/` and `templates/compose/`: three Dockerfiles with supporting nginx configuration and entrypoint script, two `.dockerignore` variants, three environment-specific Compose files, and `.env.example`. Drafts; base image versions and resource limits are placeholders. The Compose files are validated against the real `docker compose` parser; the Dockerfiles have **not been built**, because no Docker daemon is available in the authoring environment.
- These templates resolve the Angular runtime-configuration `TBD` that several standards deferred: configuration is written to `assets/config.json` at container start rather than compiled in, so one image is promoted to all three environments.
- Architecture decision records `adr/0001` through `adr/0009`. All are `Proposed`; none is `Accepted`, because no deciding role has been assigned and no review has taken place. ADRs 0001–0008 record the baseline platform decisions with their negative consequences and rejected alternatives stated explicitly. **ADR-0009 records no decision** — it sets out the five options for how the pipeline reaches runtime hosts, assesses them against the constraints, and lists the six questions the organization must answer to choose. That decision blocks six documents and all of Phase 2.
- Onboarding in `docs/12-onboarding/`: `developer-onboarding.md`, `new-project-onboarding.md`, and `devops-team-onboarding.md`. Drafts. The new-project checklist consolidates 47 steps previously distributed across the source control, container, security, observability, governance, and disaster recovery standards, and marks which are currently blocked rather than presenting an unachievable sequence.
- Disaster recovery in `docs/11-disaster-recovery/`: `backup-standard.md`, `disaster-recovery-plan.md`, and `restore-testing.md`. Drafts. No backup is taken and no restore has ever been performed, so recovery capability is unproven and RPO and RTO are unmeasured rather than merely undecided.
- Executive material in `docs/00-executive/`: `executive-summary.md`, `business-value.md`, `devops-roadmap.md`, `kpi-and-success-metrics.md`, and `risk-register.md`. Drafts. The risk register consolidates 31 risks previously distributed across the standards. Every business-value outcome is projected rather than measured, and no risk owner has been assigned.
- Governance in `docs/10-governance/`: `devops-governance.md`, `change-management.md`, `production-access-policy.md`, `exception-management.md`, and `audit-evidence.md`. Drafts. The framework is defined; no role has been assigned to any person or team, and no evidence is currently captured. Role assignment is the decision that unblocks the largest number of `TBD` items across the repository.
- Source control standards in `docs/04-source-control/`: `git-standard.md`, `branching-strategy.md`, `pull-request-standard.md`, and `release-and-tagging-standard.md`. Drafts. Three defaults are proposed with reasoning rather than left open — merge strategy per branch pair, one accountable reviewer plus domain review, and coverage thresholds on new code — because leaving them open blocks the CI/CD standards.
- Observability standards in `docs/08-observability/`: `observability-standard.md`, `monitoring-standard.md`, `logging-standard.md`, `alerting-standard.md`, and `dashboard-standard.md`. Drafts. These close four `TBD` items deferred from the container, architecture, and template documents: worker liveness approach, log redaction, alert-path failure detection, and Loki label conventions.
- Security standards in `docs/07-security/`: `security-baseline.md`, `secrets-management.md`, `vulnerability-management.md`, `software-supply-chain-security.md`, `sbom-standard.md`, `container-image-signing.md`, and `access-control.md`. Drafts. No control described in them has been implemented, tested, or independently verified, and the control catalogue records that status per control rather than implying coverage.
- Container standards in `docs/06-container/`: `docker-standard.md`, `dockerfile-standard.md`, `docker-compose-standard.md`, `harbor-standard.md`, `image-versioning.md`, and `image-retention-policy.md`. Drafts; every threshold, retention period, and base image selection is `TBD`.
- Architecture documentation in `docs/01-architecture/`: `enterprise-devops-architecture.md`, `logical-architecture.md`, `environment-architecture.md`, and `service-interaction.md`. All four are drafts describing a target architecture that has not been implemented or operationally validated.
- Shared diagram sources `architecture/diagrams/platform-overview.md` and `architecture/diagrams/environment-promotion.md`. Diagrams used by only one document are kept inline in that document.
- Repository skeleton for `docs/`, `architecture/`, `standards/`, `templates/`, `examples/`, `runbooks/`, `sop/`, and `adr/`, each with an index `README.md` describing purpose, scope, and planned contents.
- Root governance files: `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`.
- Expanded root `README.md` covering repository purpose, audience, architecture overview, technology stack, structure, navigation, adoption path, contribution process, versioning policy, and current maturity.
- Repository hygiene files `.gitignore` and `.gitattributes` to reduce the risk of committing secrets, environment files, and build output.
- ADR template at `adr/adr-template.md` implementing the format required by `AGENTS.md`.

### Decided — deployment mechanism

`adr/0010-portainer-gitops-deployment.md` records the decision that `adr/0009` set out the options for: **deployment is pull-based**, with Portainer Stacks synchronizing from a Git repository. The pipeline publishes to Harbor, commits the new image tag to a deployment repository, and calls a Portainer webhook. Nothing connects to a runtime host.

Two consequences were found while writing it:

- **Portainer Community Edition cannot force an image re-pull** — it is a Business Edition feature. A `latest` tag therefore redeploys the **old** image while reporting success. Immutable tags are not merely good practice on this platform; they are what makes deployment function at all.
- **Deployment is asynchronous**, so health verification and automatic rollback need an explicit convergence feedback path. That work does not yet exist.

### Added — application types

`AGENTS.md` now names the five application types the organization actually builds: Angular, React with TypeScript and Vite, .NET Web API, Go with Fiber, and .NET Worker Service. It previously named three, which did not match reality — and a policy naming stacks nobody uses invites readers to conclude the whole repository is irrelevant to their work.

Templates added for the two uncovered types: `Dockerfile.react-vite` with its nginx configuration and runtime-config script, `Dockerfile.go-fiber` on distroless, matching Jenkinsfiles, SonarQube properties, and ignore rules.

### Decided

The repository structure in `AGENTS.md` contains three pairs of directories that could hold overlapping content. To prevent the duplication that `AGENTS.md` warns against, the following boundaries were reviewed and confirmed. Each is documented in the affected directory's `README.md`.

| Pair | Boundary |
| --- | --- |
| `adr/` and `architecture/decisions/` | `adr/` holds the canonical, numbered decision records. `architecture/decisions/` holds only long-form supporting analysis, prefixed with the ADR number it supports. |
| `runbooks/` and `docs/09-operations/` | Split by what is operated: `docs/09-operations/` holds application delivery runbooks; `runbooks/` holds runbooks for operating the toolchain itself. |
| `standards/` and `docs/` | `standards/` holds only conventions that would otherwise be restated in two or more `docs/` areas. Domain-specific standards stay in their `docs/` area. |

### Added — Phase 2 Enterprise Expansion & Governance
- **Harbor Object Storage Backend Template (`infra/configs/harbor/storage-s3.example.yml`)**: Enterprise S3-compatible configuration template (AWS S3, MinIO, Ceph) enabling zero-disruption migration from local disk volumes to distributed object storage.
- **HashiCorp Vault Integration (`templates/security/vault/`)**: Published architecture blueprint, AppRole machine authentication guide, Jenkins `withVault` declarative pipeline usage, and production Vault Agent configuration (`vault-agent-config.example.hcl`) for zero-downtime secret rotation.
- **Jenkins Declarative Pipeline Linter (`scripts/validate-jenkinsfiles.sh`)**: Static syntax and security validator asserting balanced braces, SonarQube quality gates, Trivy scanning, credential isolation, and immutable tag rules across all Jenkinsfiles.
- **GitHub Branch Protection Enforcer (`scripts/setup-github-branch-protection.sh`)**: Executable automation implementing `branching-strategy.md` and `pull-request-standard.md` for `main` and `develop` branches via GitHub API and `gh` CLI.
- **Automated Credential Rotation Tool (`scripts/rotate-service-credentials.sh`)**: Implements `sop/credential-rotation.md` using the overlap method with cryptographically secure secret generation, `.env` backup, and Docker Compose syntax validation.
- **Enterprise Governance RACI Matrix (`docs/10-governance/raci-matrix.md`)**: Formalizes organizational role assignments (Platform Owner, Service Owner, Security Owner, Release Approver, Operator/SRE) across all platform decision rights, approval gates, and escalation workflows.
- **Enterprise Jenkins Shared Library Starter (`templates/jenkins/shared-library/`)**: Provides modular pipeline steps (`trivyScan`, `gitopsDeploy`) and opinionated declarative wrapper (`standardPipeline.groovy`) to eliminate pipeline drift and enforce organizational quality standards.

### Notes

- Standards are published and established as organizational baseline.
- All 5 reference application stacks (Angular, React, .NET API, Go Fiber, .NET Worker) have verified passing test suites.
- All platform Compose files and Portainer stack templates validate cleanly without syntax errors or variable interpolation warnings.
- Disaster recovery restore drills for Jenkins, Harbor, and SonarQube are automated with measured RTO/RPO evidence.

