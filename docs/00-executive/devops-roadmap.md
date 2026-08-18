# DevOps Roadmap

## Purpose

Sets out the phased adoption plan, what each phase depends on, and what is currently blocking progress.

## Audience

Engineering management, platform owners, and architects.

## Status

**Draft for review.** Dates and effort estimates are undecided.

---

## 1. Two Tracks, Frequently Confused

Progress is happening on one track and not the other, and conflating them produces a misleading picture of where things stand.

| Track | What it produces | State |
| --- | --- | --- |
| **Documentation** | Standards defining what will be built | Around half complete |
| **Implementation** | A working platform | Not started |

Writing the CI standard is not having CI. The documentation track is prerequisite work — it makes the design reviewable before effort is spent, and it is cheap to change. The implementation track is where every benefit in [business-value.md](business-value.md) actually arrives.

The phases below are **implementation** phases.

---

## 2. Phases

### Phase 1 — Foundation

Repository standards, Jenkins, Harbor, SonarQube, Trivy, and a DEV pipeline for one service.

| Item | Prerequisite |
| --- | --- |
| Branch protection on application repositories | Source control standards — **done** |
| Jenkins installed, with agents | Infrastructure decisions — `TBD` |
| Harbor installed, projects and robot accounts configured | Container standards — **done** |
| SonarQube installed, Quality Gate defined | Gate conditions — `TBD` |
| Trivy integrated, thresholds set | Severity thresholds — `TBD` |
| One service building and deploying to DEV | All of the above |

Exit criterion: one service goes from commit to running in DEV through the pipeline, with gates enforced, and no manual step.

### Phase 2 — Controlled delivery

UAT, production approval, immutable releases, rollback, audit trail.

| Item | Prerequisite |
| --- | --- |
| UAT environment | Infrastructure |
| Deployment mechanism to runtime hosts | **Blocked** — see section 3 |
| Production approval gate | Governance roles — **blocked**, see section 3 |
| Deployment records | Evidence design — done; implementation pending |
| Rollback, tested | Deployment mechanism |

Exit criterion: one service reaches production through approval, and a deliberate rollback is executed successfully in a non-production environment.

### Phase 3 — Security

SBOM, image signing, secret scanning, stronger credential controls.

| Item | Prerequisite |
| --- | --- |
| Secret scanning | None — could start earlier |
| SBOM generation and retention | Storage decision |
| Credential scoping and rotation | Governance roles |
| Image signing, with verification enforced | Phases 1 and 2 real; deployment mechanism decided |

Signing is last within this phase for a documented reason: it attests that an artifact came from the expected pipeline, and says nothing about whether that pipeline's inputs were controlled. Signing an image built from unpinned dependencies on a credential-rich persistent agent produces a cryptographic guarantee about an uncontrolled process.

### Phase 4 — Observability

Prometheus, Grafana, Loki, alerts, dashboards.

| Item | Prerequisite |
| --- | --- |
| Metric collection | Services instrumented |
| Log aggregation | Structured logging in services |
| Alerting, including the heartbeat | Routing destination and on-call model — `TBD` |
| Dashboards as code | Provisioning mechanism — `TBD` |

**This phase is placed too late by the standard sequence, and should be pulled forward.** Deployment verification and automatic rollback both depend on a service reporting whether it works. Phase 2's rollback cannot be validated without at least health checks and basic metrics, so a subset of Phase 4 is a Phase 2 dependency in practice.

### Phase 5 — Platform engineering

Jenkins shared library, project templates, self-service bootstrap.

Prerequisite: several services through Phases 1 and 2, so the shared library encodes patterns that have actually been used rather than patterns that were predicted.

Building the shared library first is a common and expensive mistake — it produces abstractions over a workflow nobody has run.

### Phase 6 — Runtime evolution

Evaluate Kubernetes, GitOps, Argo CD, Vault, policy-as-code.

Not scheduled. Each is adopted only when a specific pain justifies it:

| Candidate | Justified when |
| --- | --- |
| Kubernetes | Single-host failure becomes unacceptable, or workload count makes manual placement impractical |
| GitOps / Argo CD | Push-based deployment becomes a bottleneck, or drift detection becomes a real need |
| Vault | Secret count, rotation frequency, or audit requirements exceed what Jenkins Credentials serves |
| Policy-as-code | Standards are stable but manual enforcement no longer scales |

---

## 3. What Is Blocking

### Governance roles are unassigned

No role has been assigned to a team or job function. This blocks the production approval gate in Phase 2, the exception process, access approval, and risk acceptance.

Cost to resolve: a management decision. No technical work.

### The deployment mechanism is undecided

Policy requires that production must not depend on publicly exposed SSH solely for CI/CD, which rules out the most common approach. This blocks the CD standard, rollback strategy, firewall and port matrix, production deployment runbook, image signing verification point, and Compose delivery — and therefore blocks Phase 2 entirely.

Cost to resolve: an infrastructure and network decision, recorded as an ADR. Options and trade-offs are documented.

### Infrastructure is unspecified

Hosts, addresses, network placement, and sizing are all `TBD`. This blocks Phase 1 installation.

---

## 4. Recommended Sequence

Different from the standard phase order, for the reasons above.

| Order | Action | Why here |
| --- | --- | --- |
| 1 | Assign governance roles | Cheapest unblock; a management decision |
| 2 | Decide the deployment mechanism; write the ADR | Unblocks six documents and all of Phase 2 |
| 3 | Complete the remaining standards | Full review becomes possible |
| 4 | Record the eight baseline ADRs | Decision traceability before implementation |
| 5 | Phase 1, for **one** service | Validates the standards against reality |
| 6 | Health checks and basic metrics | Phase 4 subset; a Phase 2 dependency |
| 7 | Phase 2, for that one service, including a tested rollback | Where production risk actually drops |
| 8 | Onboard a second service | Reveals what was specific to the first |
| 9 | Phases 3 and 4 in full | |
| 10 | Phase 5 | Once patterns are proven |

Step 5 is the highest-value step in this list. Standards written without implementation always contain assumptions that do not survive a real deployment, and finding them on one service is far cheaper than finding them across every team.

Step 8 matters for a subtler reason: the first implementation encodes accidental properties of the first service. The second is what separates the general from the particular.

---

## 5. What Would Change This Plan

| Signal | Response |
| --- | --- |
| The first service's implementation contradicts a standard | Fix the standard; it was wrong |
| Deployment mechanism options all prove unworkable | Revisit the no-public-SSH constraint with security, as an explicit risk decision |
| Delivery frequency rises sharply | Manual approval and single-instance Jenkins become bottlenecks earlier than planned |
| A production incident exposes a gap | Reprioritize toward it; incidents are the most reliable evidence available |

---

## 6. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — governance role assignment | Phase 2, and every approval |
| `TBD` — deployment mechanism | Phase 2 entirely |
| `TBD` — infrastructure specification and sizing | Phase 1 |
| `TBD` — which service goes first | Step 5 |
| `TBD` — effort estimates and target dates per phase | Planning |
| `TBD` — who owns delivery of each phase | Accountability |

---

## Related

- [Executive summary](executive-summary.md)
- [Business value](business-value.md)
- [Risk register](risk-register.md)
- [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md)
- [Architecture Decision Records](../../adr/)
