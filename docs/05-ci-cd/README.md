# 05 — CI/CD

## Purpose

Defines the required continuous integration and continuous delivery behaviour for all application teams.

## Scope

Pipeline stages, quality and security gates, Jenkins platform architecture, environment promotion, and rollback strategy. Executable pipeline templates live in [templates/jenkins/](../../templates/jenkins/).

## Audience

Developers, platform engineers, and release approvers.

## Status

**Draft for review.** All six documents are written. The **deployment mechanism remains undecided** — the parts that depend on it are written as explicit per-option sections rather than left blank.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [ci-standard.md](ci-standard.md) | Required stages, fail-closed behaviour, branch behaviour, reproducibility | Draft |
| [pipeline-stage-standard.md](pipeline-stage-standard.md) | Per-stage contract: inputs, outputs, failure conditions, and **what a failure means** | Draft |
| [jenkins-architecture.md](jenkins-architecture.md) | Controller and agents, ephemeral versus persistent, credential isolation, shared library, plugins | Draft |
| [cd-standard.md](cd-standard.md) | Deployment flow, approval, health verification, smoke test, evidence | Draft |
| [environment-promotion.md](environment-promotion.md) | What must be identical, what may differ, the secret boundary, parity | Draft |
| [rollback-strategy.md](rollback-strategy.md) | What rollback depends on, and **when it is not available** | Draft |

## Reading Order

1. [ci-standard.md](ci-standard.md) — what produces an artifact
2. [pipeline-stage-standard.md](pipeline-stage-standard.md) — reference while diagnosing a failed stage
3. [cd-standard.md](cd-standard.md) — how it reaches production
4. [environment-promotion.md](environment-promotion.md) — what changes between environments
5. [rollback-strategy.md](rollback-strategy.md) — what happens when it goes wrong
6. [jenkins-architecture.md](jenkins-architecture.md) — how the platform itself is built

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **For .NET, static analysis must wrap build and test.** The scanner hooks the compiler; run afterwards it collects nothing, and the Quality Gate then passes on **nothing** — a gate that appears to work and checks nothing | [ci-standard.md](ci-standard.md#the-net-ordering-exception) |
| **A flaky test is a defect, not an inconvenience.** Re-running until green trains people to re-run, and the habit applies to the failure that was real | [pipeline-stage-standard.md](pipeline-stage-standard.md#unit-test) |
| **Container-running is not verification for a worker.** A worker that starts, fails to connect to its queue, and retries silently is running and processing nothing — every "is it up?" check reports success | [cd-standard.md](cd-standard.md#5-health-verification) |
| **Copy-based Harbor promotion gives identical content a new identifier**, so "what UAT verified" and "what production runs" become two references needing a mapping | [environment-promotion.md](environment-promotion.md#7-the-harbor-promotion-model) |
| **Retention bounds rollback depth.** An evicted predecessor means the rollback fails when needed, having looked configured and correct until then | [rollback-strategy.md](rollback-strategy.md#4-retention-bounds-rollback-depth) |
| **Builds must never run on the Jenkins controller** — a build there has access to the credential store and every other job's workspace | [jenkins-architecture.md](jenkins-architecture.md#2-controller-and-agents) |

## How the Undecided Mechanism Is Handled

[ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) is still open. Rather than leaving gaps, the mechanism-dependent parts are written per option:

| Document | Section |
| --- | --- |
| [cd-standard.md](cd-standard.md) | §8 — and **option C changes this standard**, because pull-based deployment is asynchronous: health verification must wait for convergence, and automatic rollback needs an explicit feedback path |
| [rollback-strategy.md](rollback-strategy.md) | §10 — under option C, "rollback completed" and "rollback took effect" are different moments |
| [jenkins-architecture.md](jenkins-architecture.md) | §4 — option A places a persistent agent on every runtime host including production, which conflicts with an ephemeral-agent model |

The **policy** in all three documents is independent of the decision. Only execution depends on it.

---

## Standard CI Flow

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

Fail fast. A failed mandatory quality or security stage must stop promotion.

## Standard CD Flow

```text
Select immutable image
Deploy DEV
Health Check
Deploy UAT
Health Check
Approval
Deploy PROD
Health Check
Smoke Test
Rollback on failure where technically safe
```

---

## Non-Negotiables

- Production deployment uses an explicitly identified, immutable release artifact.
- `latest` must never be the sole production deployment identifier.
- Do not rebuild production binaries separately from the artifact validated in lower environments, unless a documented technical requirement exists.
- Every production deployment must be traceable to Git commit, pipeline execution, container image, approver, timestamp, and environment.
- Rollback is designed **before** the first production deployment.
- Never promise automatic rollback for irreversible database changes.
- Prefer Jenkins Shared Libraries or reusable templates over duplicated pipeline logic.

---

## Open Items

- `TBD` — coverage thresholds per application type
- `TBD` — Quality Gate definition and blocking conditions
- `TBD` — Trivy severity thresholds and exception process
- `TBD` — production approver role
- `TBD` — image-signing tooling and rollout timing
- `TBD` — deployment mechanism to runtime hosts, given the no-public-SSH constraint

---

## Related

- [Documentation index](../README.md)
- [Architecture](../01-architecture/)
- [Container standards](../06-container/)
- [Security](../07-security/)
- [Operations runbooks](../09-operations/)
- [Jenkins templates](../../templates/jenkins/)
