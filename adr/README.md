# Architecture Decision Records

## Purpose

The canonical, numbered record of significant architecture decisions for the Enterprise DevOps Blueprint.

## Scope

Decisions that adopt, replace, or remove a platform component, or that change the environment model, artifact identity, promotion path, production approval, access model, or rollback behaviour.

## Status

**Nine ADRs written. All are `Proposed`.**

None is `Accepted`, because no deciding role has been assigned and no review has taken place. Marking them accepted would claim an approval that has not happened — see [devops-governance.md](../docs/10-governance/devops-governance.md#2-roles).

---

## Decision Records

| File | Decision | Status |
| --- | --- | --- |
| [0001-use-jenkins-for-ci-cd.md](0001-use-jenkins-for-ci-cd.md) | Self-hosted Jenkins as the CI/CD execution platform | Proposed |
| [0002-use-harbor-as-container-registry.md](0002-use-harbor-as-container-registry.md) | Harbor as the centralized container registry | Proposed |
| [0003-use-sonarqube-for-code-quality.md](0003-use-sonarqube-for-code-quality.md) | SonarQube for static analysis and Quality Gate enforcement | Proposed |
| [0004-use-trivy-for-container-security.md](0004-use-trivy-for-container-security.md) | Trivy for vulnerability and misconfiguration scanning | Proposed |
| [0005-use-docker-compose-for-initial-runtime.md](0005-use-docker-compose-for-initial-runtime.md) | Docker Compose as the initial runtime, deferring Kubernetes | Proposed |
| [0006-use-prometheus-grafana-loki.md](0006-use-prometheus-grafana-loki.md) | Prometheus, Grafana, and Loki as the observability stack | Proposed |
| [0007-use-immutable-container-versioning.md](0007-use-immutable-container-versioning.md) | Immutable, traceable image identifiers; `latest` never used for production | Proposed |
| [0008-production-manual-approval.md](0008-production-manual-approval.md) | Manual approval gate before production deployment | Proposed |
| [0009-deployment-mechanism-to-runtime-hosts.md](0009-deployment-mechanism-to-runtime-hosts.md) | **Decision required** — how the pipeline reaches runtime hosts | **Proposed — open** |

ADRs 0001 to 0008 represent **blueprint decisions** made when this repository was established. They record what was decided and why; they do not record historical debates that did not take place. Alternatives were assessed analytically against stated constraints, not through proofs of concept or benchmarking, and each ADR says so.

## ADR-0009 Is Different

It records **no decision**. It sets out five options, assesses them against the constraints, and lists the six questions the organization must answer to choose.

It exists because the decision blocks six documents and all of Phase 2, and a pending decision is more useful as a reviewable artifact than as a note repeated across the standards it blocks.

## What Reviewers Should Look For

Each ADR's **Negative Consequences** and **Alternatives Considered** sections carry the value. Specific points worth checking:

| ADR | Point |
| --- | --- |
| 0001 | GitHub Actions with **self-hosted** runners satisfies the literal constraint and was rejected on control-plane location, not on capability. It is the alternative most worth revisiting |
| 0002 | Harbor is a single point of failure for deployment **and rollback** — the recovery path shares a dependency with the failure path |
| 0003 | The SonarQube **edition** is undecided, and the Community edition lacks branch and pull-request analysis. That changes what the gate actually evaluates |
| 0004 | A stale vulnerability database produces a clean report indistinguishable from a genuinely clean scan |
| 0005 | Compose has **no rolling update primitive**. Zero-downtime deployment needs additional design — the most underestimated limitation of this choice |
| 0006 | A single Prometheus is a single point of failure for **detection**, and its failure is silent |
| 0007 | Retention becomes a reliability control: an evicted image means rollback fails when needed |
| 0008 | Approval fatigue produces rubber-stamping, which is invisible from the record — a rubber-stamped approval looks identical to a considered one |
| 0009 | Option D (Portainer API) is cheapest and dissolves a governance boundary the rest of the blueprint depends on |

---

## Format

Use [adr-template.md](adr-template.md). Every ADR contains:

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

## Numbering

Sequential and zero-padded to four digits, never reused:

```text
adr/0001-use-jenkins-for-ci-cd.md
adr/0002-use-harbor-as-container-registry.md
```

## Lifecycle

| Status | Meaning |
| --- | --- |
| `Proposed` | Under review in a pull request |
| `Accepted` | Approved and in force |
| `Superseded by ADR-NNNN` | Replaced by a later decision |
| `Deprecated` | No longer applies, with no direct replacement |

An accepted ADR is not edited to reverse its decision. Write a new ADR that supersedes it, and link both directions. The record of what was decided, and why, must survive the change.

---

## Honesty Requirements

- Do not fabricate discussions, meetings, participants, or dates that did not occur.
- Record alternatives that were genuinely considered. An empty or invented alternatives section makes the record useless.
- Record consequences honestly, including the negative ones. An ADR listing only benefits is marketing, not a decision record.
- Where a decision was made without deep evaluation, say so. That is useful information for whoever revisits it.

---

## Related

- [Architecture documentation](../docs/01-architecture/)
- [Decision support material](../architecture/decisions/)
- [Contribution process](../CONTRIBUTING.md)
- [Engineering and AI-governance policy](../AGENTS.md)
