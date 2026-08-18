# CI Standard

## Purpose

Defines what continuous integration must do for every application, which stages are mandatory, and what happens when one fails.

## Scope

From commit to a published artifact. Deployment is in [cd-standard.md](cd-standard.md); per-stage detail is in [pipeline-stage-standard.md](pipeline-stage-standard.md); the Jenkins platform is in [jenkins-architecture.md](jenkins-architecture.md).

## Audience

Developers and platform engineers.

## Status

**Draft for review.** Not implemented. Every threshold is `TBD`.

---

## 1. What CI Is For Here

CI produces **one thing**: an artifact that has passed every mandatory control, published under an immutable identity.

That framing decides several arguments before they start. A pipeline run that does not produce a publishable artifact has not partially succeeded — it has produced verification. A stage that reports without blocking is not part of CI; it is reporting.

---

## 2. Required Stages

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

| Stage | Mandatory | Blocks | Notes |
| --- | --- | --- | --- |
| Checkout | Yes | Yes | |
| Restore dependencies | Yes | Yes | From a **committed lockfile** |
| Lint | Yes | `TBD` | |
| Build | Yes | Yes | |
| Unit test | Yes | Yes | |
| Coverage | Yes | `TBD` — threshold on **new code** | |
| Static analysis | Yes | Via the gate | For .NET this **wraps** build and test — see below |
| Quality Gate | Yes | **Yes** | Unavailable is not a pass |
| Security scan | Yes | **Yes**, at threshold | Dependencies and secrets, before the image is built |
| Docker build | Yes | Yes | |
| Container scan | Yes | **Yes**, at threshold | **Before publication** |
| Generate SBOM | Yes | `TBD` — recommended yes | |
| Sign image | **Not adopted** | — | Phase 3; see [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) for the verification point |
| Push to Harbor | Protected branches only | — | |

### The .NET ordering exception

For .NET, static analysis **wraps** build and test:

```text
sonarscanner begin -> build -> test -> sonarscanner end
```

The scanner hooks the compiler to collect analysis during compilation. Running it after the build produces an analysis with **no results**, and the Quality Gate then passes on nothing — a gate that appears to work and checks nothing, which is worse than no gate.

`--no-incremental` is required for the same reason: an incremental build skips compilation of unchanged projects, and the scanner sees only what is compiled.

---

## 3. Fail Closed

**A control that cannot be evaluated has not passed.**

| Situation | Required behaviour |
| --- | --- |
| SonarQube unavailable | **Fail.** An unevaluated gate is not a pass |
| Trivy database stale beyond threshold | **Fail.** A stale database produces a clean report indistinguishable from a genuinely clean one |
| Scanner cannot run | **Fail** |
| Harbor unavailable at push | **Fail.** The build work is lost; that is correct |
| A test is flaky | **Fail.** Fix the test; do not re-run until green |

The first is the one argued about, and the argument arrives within hours of the first outage. Treating unavailable as passing converts a tool outage into a silent bypass of a mandatory control.

Where a prolonged outage genuinely requires proceeding, that is a recorded, time-bounded exception with an approver — not a configuration change made quietly. See [exception-management.md](../10-governance/exception-management.md).

The flaky-test row matters more than it looks. A check re-run until it passes is a check nobody trusts afterwards, **including for the failure that was real**.

---

## 4. Branch Behaviour

| Branch | Pipeline | Image published | Tag |
| --- | --- | --- | --- |
| `feature/*` | Full verification | `TBD` — see below | Not promotable |
| `develop` | Full | Yes | `sha-<commit>` |
| `release/*` | Full | Yes | `<version>-<commit>` |
| `main` | Full | Yes | `<version>-<commit>` |
| `hotfix/*` | Full | Yes | `<version>-<commit>` |

**Promotable images are built only from protected branches.** A commit on a feature branch may never exist in that form on `develop` — squash merging guarantees it will not — so an image tagged with it would reference a commit absent from the branch history it claims to come from.

`TBD` — whether feature branches publish an image at all. Publishing gives developers something to test with; not publishing avoids filling the registry with images that will never be promoted.

---

## 5. What CI Must Produce

Every successful run on a protected branch produces:

| Output | Purpose |
| --- | --- |
| The image, published under an immutable identity | The deployable artifact |
| Image digest | Recorded in the deployment record; independent of tag mutability |
| OCI labels: version, commit, build time, source | Makes a running container self-describing |
| Test results | Evidence |
| Coverage report | Evidence, and gate input |
| Gate verdicts | Evidence |
| Scan results | Vulnerability posture at build time |
| SBOM | Component inventory, retained **independently of the image** |

The SBOM's independent retention matters: image retention is bounded by rollback depth and storage, while the supply-chain question can be asked long after an image is gone.

---

## 6. Speed

`TBD` — a target. Beyond roughly ten minutes, developers context-switch away and return later, which costs more than the pipeline time itself.

| Lever | Effect |
| --- | --- |
| Dependency restore layer ordering | Large. A source change should not re-run restore |
| Parallel stages where independent | Moderate |
| Agent capacity | Removes queueing, which is often most of the wall-clock time |
| Container build cache | Large for image builds |

**Not a lever:** removing tests or scans. It is the most immediately effective way to improve the number and the most damaging. Read pipeline duration alongside change failure rate — see [kpi-and-success-metrics.md](../00-executive/kpi-and-success-metrics.md).

---

## 7. Reproducibility

The same commit must produce a functionally identical artifact on any agent, at any time.

| Requirement | Without it |
| --- | --- |
| Committed lockfile, restored in locked mode | The same commit resolves different dependency versions on different days |
| Pinned base images | Content changes between builds without notice |
| No network-dependent build steps beyond the package feeds | Builds fail or differ based on external state |
| Clean workspace between builds | Artifacts leak between builds |

This is why the traceability chain works at all: a deployment record naming a commit means something only if that commit produces a known artifact.

---

## 8. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — coverage threshold, on new code | Coverage stage |
| `TBD` — Quality Gate conditions | Gate stage |
| `TBD` — Trivy severity thresholds, and whether unfixable findings block | Security stages |
| `TBD` — database staleness threshold | Scanner trustworthiness |
| `TBD` — whether lint blocks or warns | Lint stage |
| `TBD` — whether SBOM generation failure blocks publication | Inventory completeness |
| `TBD` — whether feature branches publish images | Registry volume |
| `TBD` — pipeline duration target | Feedback speed |

Every threshold should be set from a **measured baseline**. A threshold the existing codebase cannot meet blocks everything on day one and is removed within a week; one nothing triggers is decoration.

---

## Security Considerations

Three stages are security controls rather than quality ones: dependency and secret scanning, container scanning, and the Quality Gate's security conditions. All three block **before publication** rather than before deployment — because once an image exists in the registry it is deployable, and only a configuration change stands between it and production.

A detected secret is not a finding to triage against a severity threshold. It is a credential to treat as compromised, and the first action is rotation.

Fail-closed behaviour is the property that makes any of this real. A pipeline that continues when a control cannot be evaluated has the appearance of the control and none of its effect.

## Operational Considerations

The two failures that erode CI are flaky tests and slow pipelines, and they compound: a slow pipeline makes re-running expensive, and flaky tests make re-running necessary. The result is a pipeline people work around.

Reproducibility is the quiet requirement. It has no visible benefit until something needs to be rebuilt or explained, and by then the discipline either existed or did not.

---

## Related

- [Pipeline stage standard](pipeline-stage-standard.md)
- [CD standard](cd-standard.md)
- [Jenkins architecture](jenkins-architecture.md)
- [Jenkins templates](../../templates/jenkins/)
- [Vulnerability management](../07-security/vulnerability-management.md)
- [Image versioning](../06-container/image-versioning.md)
