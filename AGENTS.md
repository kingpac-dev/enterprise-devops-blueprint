# AGENTS.md

## Purpose

This file defines the primary engineering and AI-governance policy for the `enterprise-devops-blueprint` repository.

All AI assistants, coding agents, automation tools, and human contributors should treat this file as the primary project-level instruction source unless a higher-authority policy applies.

Project-specific instructions may add stricter requirements but must not silently weaken this policy.

---

## 1. Repository Mission

This repository defines the organization-wide Enterprise DevOps Blueprint for secure, traceable, repeatable, reviewable, recoverable, and maintainable software delivery.

The initial platform architecture is based on:

- GitHub for source control and pull requests
- Jenkins for self-hosted CI/CD execution
- SonarQube for code quality and static analysis
- Trivy for vulnerability and configuration scanning
- Harbor for container registry and artifact promotion
- Docker and Docker Compose for the initial runtime platform
- Portainer for controlled operational visibility
- Prometheus for metrics
- Grafana for dashboards
- Loki for centralized logging

The design must allow future evolution toward Kubernetes, GitOps, Argo CD, Vault, policy-as-code, and an internal developer platform without forcing premature adoption.

---

## 2. Mandatory Agent Workflow

Before substantial work, an AI agent must:

1. Read this `AGENTS.md`.
2. Inspect the existing repository structure and conventions.
3. Search for nested `AGENTS.md` files or stricter project-specific instructions.
4. Summarize the sections of this policy that apply to the requested task.
5. Identify conflicts before making affected changes.
6. Prefer minimal, reviewable changes.
7. Avoid unrelated refactoring.

For high-risk changes involving production, credentials, access control, networking, deployment, data loss, or destructive operations, stop and surface missing assumptions or policy conflicts before making the affected decision.

---

## 3. Engineering Principles

Apply these principles proportionately to task risk:

- Correctness
- Maintainability
- Testability
- Security
- Privacy
- Performance
- Accessibility where applicable
- Observability
- Backward compatibility
- Operational recoverability
- Least privilege
- Defense in depth
- Auditability

AI-generated output is an untrusted draft until reviewed and validated.

Do not claim tests passed, compliance was achieved, security was verified, or certification exists unless supported by verifiable evidence.

---

## 4. Scope Control

Keep changes focused on the requested task.

Do not:

- refactor unrelated files
- rename unrelated structures
- change architecture without documenting the reason
- introduce new platforms merely because they are fashionable
- add dependencies without clear need
- make destructive or production changes without explicit authorization

Prefer small, reviewable change sets.

---

## 5. Repository Standards

The repository should follow this baseline structure unless a documented decision justifies a change:

```text
enterprise-devops-blueprint/
├── README.md
├── AGENTS.md
├── AI-BOOTSTRAP-PROMPT.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── docs/
│   ├── 00-executive/
│   ├── 01-architecture/
│   ├── 02-infrastructure/
│   ├── 03-network/
│   ├── 04-source-control/
│   ├── 05-ci-cd/
│   ├── 06-container/
│   ├── 07-security/
│   ├── 08-observability/
│   ├── 09-operations/
│   ├── 10-governance/
│   ├── 11-disaster-recovery/
│   └── 12-onboarding/
├── architecture/
│   ├── diagrams/
│   └── decisions/
├── standards/
├── templates/
│   ├── jenkins/
│   ├── docker/
│   ├── compose/
│   ├── sonar/
│   ├── security/
│   ├── monitoring/
│   └── project-template/
├── examples/
│   ├── angular/
│   ├── dotnet-api/
│   └── dotnet-worker/
├── runbooks/
├── sop/
└── adr/
```

Do not create empty directories unless the repository convention requires placeholders.

---

## 6. Documentation Rules

Documentation must:

- use Markdown unless another format is explicitly required
- use clear professional English for repository artifacts
- keep code, identifiers, commands, variables, comments, and configuration in English
- state purpose and scope
- state assumptions where relevant
- distinguish requirements from recommendations
- identify security and operational considerations when applicable
- use relative links for internal repository references
- avoid duplicating the same policy across multiple documents
- mark unknown organization-specific values as `TBD`

Use Mermaid for diagrams where practical.

Do not claim formal compliance unless independently verified.

Use precise language such as:

- `aligned with`
- `recommended by`
- `required by organization`

Do not use `compliant with` unless formal evidence exists.

---

## 7. Source Control Policy

GitHub is the source control and collaboration platform.

Baseline branch model:

```text
feature/* -> develop -> DEV
release/* -> UAT
main      -> PROD
```

Use pull requests before protected-branch merges.

Document and enforce where applicable:

- branch protection
- required reviewers
- CI checks
- merge strategy
- release tags
- hotfix process
- production release process

Avoid unnecessary branching complexity.

---

## 8. CI/CD Policy

Jenkins is the primary self-hosted CI/CD execution platform.

The standard CI flow should include, where applicable:

```text
Checkout
Restore Dependencies
Lint
Build
Unit Test
Coverage
Static Analysis
SonarQube Quality Gate
Security Scan
Docker Build
Container Scan
Generate SBOM
Sign Image
Push to Harbor
```

Mandatory quality or security failures must stop promotion.

Production deployment must use a traceable, immutable release artifact.

Do not use `latest` as the sole production deployment identifier.

Recommended image identifiers include:

```text
app:1.4.2
app:1.4.2-a82f912
app:sha-a82f912
```

---

## 9. Deployment Policy

Environments:

- DEV
- UAT
- PROD

Promote the same built artifact across environments where technically possible.

Preferred pattern:

```text
Build once
Promote the same image
Use environment-specific configuration
```

Production deployment requires:

- explicit release version
- approval gate
- health verification
- smoke testing where applicable
- rollback capability
- deployment audit trail

Production must not depend on publicly exposed SSH solely for CI/CD.

Do not rebuild production binaries separately from the artifact validated in lower environments unless there is a documented technical requirement.

---

## 10. Rollback Policy

Rollback must be designed before production deployment.

A deployment process should:

1. record the current known-good version
2. deploy the requested immutable image
3. execute health checks
4. execute smoke tests where applicable
5. restore the previous version on failure when technically safe
6. verify recovery
7. record failure evidence

Database migrations may make rollback unsafe or impossible.

For database changes, document:

- migration ownership
- backup requirements
- backward compatibility
- expand/contract strategy
- rollback limitations

Never promise automatic rollback for irreversible database changes.

---

## 11. Security Policy

Never commit real secrets.

Examples:

- passwords
- tokens
- API keys
- JWT signing keys
- private certificates
- private SSH keys
- registry credentials
- production connection strings

Use placeholders in templates and examples.

Initial approved secret mechanisms may include:

- Jenkins Credentials
- environment-specific protected `.env` files
- host-managed secrets

Future adoption of Vault or equivalent may be recommended based on scale and risk.

Apply:

- least privilege
- restricted administrative interfaces
- TLS for sensitive traffic
- dependency pinning where practical
- trusted base images
- CI credential isolation
- vulnerability scanning
- secret scanning
- SBOM generation
- image-signing roadmap
- auditable deployment

Never bypass security controls for convenience.

---

## 12. Container Policy

Use secure Docker practices:

- multi-stage builds where appropriate
- minimal runtime images
- non-root execution where practical
- `.dockerignore`
- no embedded credentials
- controlled or pinned base-image strategy
- explicit runtime configuration
- correct signal handling
- health checks where technically appropriate

Harbor is the centralized container registry.

Production artifacts should be immutable or otherwise protected against accidental replacement.

---

## 13. Portainer Policy

Portainer may be used for:

- operational visibility
- controlled troubleshooting
- container inspection
- approved operational tasks

Portainer must not become an uncontrolled deployment path that bypasses CI/CD governance.

Manual production changes must follow change-control requirements and be recorded.

---

## 14. Observability Policy

Baseline observability stack:

- Prometheus
- Grafana
- Loki

Applications should expose useful operational signals where applicable.

Metrics should include:

- request rate
- error rate
- latency
- CPU
- memory
- restart count
- availability

Logs should be:

- structured where practical
- searchable
- environment-aware
- correlated with service identity
- free of credentials and unnecessary personal data

Alerts should cover meaningful actionable conditions rather than noise.

---

## 15. Health Check Policy

Production services should expose health endpoints where technically appropriate.

For .NET services, distinguish where useful:

- liveness
- readiness
- dependency health

Do not expose sensitive infrastructure details through public health endpoints.

---

## 16. Infrastructure and Network Policy

Initial runtime targets may use Linux VMs or servers with Docker, Docker Compose, and Portainer.

Document network flows between:

- Developer -> GitHub
- GitHub -> Jenkins webhook
- Jenkins -> GitHub
- Jenkins -> SonarQube
- Jenkins -> Harbor
- Jenkins -> deployment targets
- Runtime -> Harbor
- Runtime -> monitoring
- Monitoring -> runtime

Apply:

- least privilege
- network segmentation
- firewall allow-listing
- TLS
- restricted inbound access
- controlled outbound access
- no unnecessary public exposure

Production administrative interfaces should not be publicly exposed without explicit justification and compensating controls.

---

## 17. Backup and Disaster Recovery Policy

Document backup and restore requirements for:

- Jenkins configuration
- Jenkins credentials where securely supported
- SonarQube database
- Harbor metadata
- Harbor image storage
- monitoring configuration
- dashboards
- deployment configuration
- repository documentation

Define or mark as `TBD`:

- RPO
- RTO
- backup frequency
- retention
- restore-test frequency

A backup is not considered operationally reliable until restore testing is demonstrated.

---

## 18. Architecture Decision Records

Record significant architecture decisions using ADRs.

ADR format:

```text
Title
Status
Context
Decision
Consequences
Alternatives Considered
Security Considerations
Operational Considerations
```

Initial expected ADRs include decisions for:

- Jenkins
- Harbor
- SonarQube
- Trivy
- Docker Compose
- Prometheus/Grafana/Loki
- immutable container versioning
- production manual approval

Do not fabricate historical discussions.

State that initial ADRs represent blueprint decisions.

---

## 19. Validation Policy

Before declaring work complete, verify what can actually be verified.

Check for:

- broken Markdown links
- duplicate guidance
- inconsistent terminology
- inconsistent environment naming
- inconsistent tagging rules
- secret-looking values
- insecure examples
- contradictory standards
- missing rollback paths
- unsupported claims
- placeholder content accidentally presented as final

Where tools are available, validate:

- YAML syntax
- Docker Compose syntax
- Dockerfile behavior where practical
- Jenkins pipeline syntax where practical
- Mermaid syntax where practical

Never state validation passed if it was not actually run.

---

## 20. Change Reporting

After a logical implementation phase, summarize:

- files created or changed
- important design decisions
- validation performed
- remaining `TBD` items
- risks
- items requiring human review

Keep summaries concise and evidence-based.

---

## 21. Future Evolution

The initial blueprint should be compatible with future evaluation of:

- Kubernetes
- GitOps
- Argo CD
- Vault
- policy-as-code
- OPA or equivalent
- internal developer platform

Do not introduce these platforms before requirements justify their operational complexity.

---

## 22. Definition of Good Work

Changes should be:

- minimal
- reviewable
- secure by default
- traceable
- reproducible
- operationally recoverable
- consistent with existing architecture
- clearly documented
- honest about unknowns and limitations

When uncertain, prefer explicit `TBD`, documented assumptions, and reversible decisions over fabricated certainty.
