# ADR-0009 — Deployment Mechanism to Runtime Hosts

| Field | Value |
| --- | --- |
| Status | **Proposed — decision required** |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner, with security and network input |
| Supersedes | None |
| Superseded by | None |

> **This ADR does not record a decision. It records the options, their trade-offs, and the questions that must be answered to choose.** It exists so a pending decision is a reviewable artifact rather than a note repeated across several documents.

---

## Context

The pipeline must reach DEV, UAT, and PROD runtime hosts to deploy, verify health, and roll back.

Two policy constraints apply:

- Production **must not depend on publicly exposed SSH solely for CI/CD**.
- Production administrative interfaces **must not be publicly exposed** without explicit justification and compensating controls.

The first rules out the most common approach in its usual form and leaves the mechanism open.

The property that distinguishes the options is **which side opens the connection**, because that determines the firewall design and therefore the exposure of the runtime hosts.

### What this blocks

| Document | Cannot be completed |
| --- | --- |
| `docs/05-ci-cd/cd-standard.md` | The deployment flow depends on the mechanism |
| `docs/05-ci-cd/rollback-strategy.md` | Rollback executes through the same path |
| `docs/05-ci-cd/environment-promotion.md` | Promotion mechanics |
| `docs/03-network/firewall-and-port-matrix.md` | Direction and ports are unknown |
| `docs/09-operations/production-deployment-runbook.md` | The runbook is the procedure for this mechanism |
| `docs/07-security/container-image-signing.md` | Where verification can occur depends on how images are started |

It also blocks Phase 2 of the roadmap in its entirety.

---

## Decision

**Not yet made.** One of the options below must be selected, and this ADR updated with the choice and its rationale.

---

## Alternatives Considered

All five remain open. None has been rejected, except as noted for option D.

### A — Jenkins agent on each runtime host

The host runs a Jenkins agent that connects **outbound** to the controller. Deployment is a job step executed locally on the host.

| | |
| --- | --- |
| Connection | Host → controller, outbound |
| Inbound to host | **None** |
| Requires | An agent process, a JVM, and controller credentials on every host including production |
| Rollback | Same path; no additional mechanism |
| Notes | Satisfies the constraint fully. The cost is an agent with controller connectivity running on production, which widens what a production host compromise reaches |

### B — SSH over a controlled internal network only

Jenkins connects **inbound** to the host over SSH, with the host reachable only from within the controlled network.

| | |
| --- | --- |
| Connection | Controller → host, inbound |
| Inbound to host | SSH, from the Jenkins network segment only |
| Requires | Trustworthy network segmentation; SSH key management |
| Rollback | Same path |
| Notes | Satisfies the constraint **literally** — the exposure is internal, not public. Whether that satisfies its intent is the question this option raises, and it is a judgement about how much the internal network is trusted |

### C — Pull-based deployment agent

An agent on each host polls a source of truth for the desired version and reconciles.

| | |
| --- | --- |
| Connection | Host → source, outbound |
| Inbound to host | **None** |
| Requires | An agent, a desired-state source, and a status feedback path |
| Rollback | Change the desired state; the host converges |
| Notes | No orchestration credentials on the controller at all — the strongest security posture. Deployment becomes eventually consistent, so "deploy now" and "did it work?" both need explicit design. This is the GitOps shape without adopting a GitOps platform |

### D — Portainer API driven by Jenkins

Jenkins calls the Portainer API to update the running stack.

| | |
| --- | --- |
| Connection | Controller → Portainer, inbound |
| Inbound to host | Portainer API |
| Requires | Portainer API credentials in Jenkins |
| Rollback | Same path |
| Notes | **Reuses an existing component and creates a governance problem.** Portainer is designated as an inspection and troubleshooting tool that must not become a deployment path; routing the pipeline through its API makes that boundary unenforceable, because the same interface then serves both the governed and ungoverned paths |

### E — Container orchestrator API

Deferred with Kubernetes — see [ADR-0005](0005-use-docker-compose-for-initial-runtime.md). Not available under the current runtime decision.

---

## Assessment Against the Constraints

| | A — Agent | B — Internal SSH | C — Pull agent | D — Portainer API |
| --- | --- | --- | --- | --- |
| Satisfies the no-public-SSH constraint | Yes | Literally | Yes | Yes |
| Inbound access to production hosts | None | SSH, internal | None | API |
| Credentials on production hosts | Controller connection | SSH keys accepted | Source access | None |
| Orchestration credentials on the controller | Yes | Yes | **No** | Yes |
| Deployment is synchronous | Yes | Yes | **No** | Yes |
| Additional software on hosts | Agent + JVM | None | Agent | Portainer (already present) |
| Preserves the Portainer governance boundary | Yes | Yes | Yes | **No** |
| Path toward GitOps later | Neutral | Neutral | **Direct** | Neutral |
| Operational complexity | Medium | Low | Medium to High | Low |

---

## Questions That Decide This

The blueprint cannot answer these; they are properties of the organization's infrastructure and risk appetite.

| # | Question | Determines |
| --- | --- | --- |
| 1 | Is the internal network segmented and trusted enough that internal SSH to production is acceptable? | Whether B is viable |
| 2 | Is running an agent with controller connectivity on production hosts acceptable? | Whether A and C are viable |
| 3 | Must deployment be synchronous, with an immediate success or failure result? | Whether C is viable without additional work |
| 4 | Is GitOps a likely direction within a foreseeable horizon? | Whether C's extra cost buys a later benefit |
| 5 | Who operates the runtime hosts, and can they maintain an additional agent? | Operational feasibility of A and C |
| 6 | Does security accept that "not publicly exposed" satisfies the intent of the constraint? | Whether B is acceptable in principle |

Question 6 should be answered by the security owner explicitly and recorded, whichever option is chosen. It is the constraint's meaning, and leaving it to interpretation means it will be interpreted differently by different people later.

---

## Assessment

Stated as conditional analysis, not as a decision.

**If question 2 is yes and question 3 is yes** — an agent on production is acceptable and deployment must be synchronous — **option A** is the most direct fit. It satisfies the constraint fully, requires no inbound access, needs no new platform, and keeps rollback on the same path as deployment.

**If question 2 is no but question 1 is yes** — no agents on production, and the internal network is trusted — **option B** is the pragmatic choice, provided question 6 is answered affirmatively and recorded. It is the simplest to operate and the easiest to reason about.

**If question 4 is yes** — GitOps is a likely direction — **option C** is worth its additional cost now, because it establishes the pull-based shape before there is an installed base to migrate.

**Option D is not recommended** at any setting of these questions. It is the cheapest to implement and it dissolves a governance boundary that the rest of the blueprint depends on. If it is chosen for expediency, the Portainer boundary in [change-management.md](../docs/10-governance/change-management.md) and [access-control.md](../docs/07-security/access-control.md) should be removed rather than left as a rule nothing enforces.

---

## Consequences

### Of the decision itself

Recorded in the successor ADR once the choice is made. Each option's consequences are set out in the Alternatives Considered section above.

### Of not deciding

Six documents and all of Phase 2 remain blocked. The standards written so far assume a mechanism exists without specifying it, which is coherent but incomplete.

The cost of deciding late is not only delay. Several downstream decisions — the firewall matrix, the signing verification point, the rollback procedure — will be designed around whatever is chosen, so a late change means revisiting them rather than writing them once.

---

## Security Considerations

The security posture differs materially between options and does not track their convenience.

Option C is strongest: no inbound access to hosts, and no orchestration credentials on the controller — which means a Jenkins compromise cannot directly change production, only change what the desired state says. Given that Jenkins credential concentration is the architecture's principal security risk, that is a meaningful reduction.

Options A and B place production-changing credentials on the controller, consistent with the existing concentration.

Option D additionally routes the governed path through a tool designated as ungoverned, which makes the distinction unenforceable.

Whichever is chosen, the deployment credential must be **per environment**. One credential that can deploy anywhere makes the approval boundary decorative.

## Operational Considerations

Options A and C add software to every runtime host, which must be patched, monitored, and recovered with the host. Option B adds nothing but depends on network configuration remaining correct — a dependency that is invisible until it changes.

Option C's asynchrony has a specific operational consequence worth planning for: the pipeline no longer knows whether a deployment succeeded, so health verification and the rollback decision need an explicit feedback path. Without one, automatic rollback on failed verification does not work.

---

## Review Trigger

This ADR is superseded when the decision is made. The successor records the choice, its rationale, and the answer to question 6.

If the chosen option later proves unworkable — for example if network segmentation cannot be relied upon under option B — this analysis remains the starting point for the replacement.

---

## References

- [Service interaction](../docs/01-architecture/service-interaction.md) — interaction I-06
- [Enterprise DevOps architecture](../docs/01-architecture/enterprise-devops-architecture.md)
- [Change management](../docs/10-governance/change-management.md) — the Portainer boundary
- [Container image signing](../docs/07-security/container-image-signing.md) — verification point
- [DevOps roadmap](../docs/00-executive/devops-roadmap.md)
