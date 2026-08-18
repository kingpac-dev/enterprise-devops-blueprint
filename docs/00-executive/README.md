# 00 — Executive

## Purpose

Management-facing documentation explaining what the DevOps platform delivers, how progress is measured, and what risk it carries.

## Scope

Business value, adoption roadmap, success metrics, and the organizational risk register. Engineering detail belongs in the technical areas.

## Audience

Engineering management, architects, and platform owners.

## Status

**Draft for review.** All five documents are written. Every outcome is projected rather than measured, and no risk owner has been assigned.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [executive-summary.md](executive-summary.md) | What the blueprint is, what it is **not**, known weaknesses, the two blocking decisions, recommended next steps | Draft |
| [business-value.md](business-value.md) | Expected outcomes with a stated test for each, what cannot be claimed, costs, sequencing, falsification signals | Draft |
| [devops-roadmap.md](devops-roadmap.md) | Six implementation phases, dependencies, what is blocking, a recommended sequence that differs from the standard order | Draft |
| [kpi-and-success-metrics.md](kpi-and-success-metrics.md) | Metrics with the engineering outcome each drives **and how each can be gamed**; metrics deliberately not used | Draft |
| [risk-register.md](risk-register.md) | 31 risks consolidated from across the blueprint, with impact, likelihood, mitigation, detection, owner role, and residual | Draft |

## Reading Order

1. [executive-summary.md](executive-summary.md) — the state of things in five minutes
2. [risk-register.md](risk-register.md) — what could go wrong, ranked
3. [devops-roadmap.md](devops-roadmap.md) — what to do next, and in what order
4. [business-value.md](business-value.md) and [kpi-and-success-metrics.md](kpi-and-success-metrics.md) — what it should deliver, and how that would be verified

---

## Notes and Constraints

- Metrics state the intended engineering outcome and how each can be gamed, not just the number.
- The risk register uses **owner roles**, never invented individual names.
- Business-value statements are honest about what has not yet been implemented or measured. Every outcome is projected.

## What Management Should Take From This

| Point | Where |
| --- | --- |
| **This is documentation. The platform has not been built.** Writing the CI standard is not having CI | [executive-summary.md](executive-summary.md#4-what-this-is-not) |
| Two decisions block a disproportionate amount of work: **governance roles are unassigned**, and **the deployment mechanism is undecided**. The first costs a management decision and no technical work | [executive-summary.md](executive-summary.md#7-the-decisions-blocking-progress) |
| The highest-priority risks are untested backups, Harbor as a single point of failure for deployment *and* rollback, and compromised CI credentials. Three of the top eight are cheap enough to fix before the platform is complete | [risk-register.md](risk-register.md#9-highest-priority) |
| **Baselines can only be captured before implementation.** That window is open now; once the platform exists, every improvement claim becomes an assertion | [business-value.md](business-value.md#7-open-items) |
| Gates make each individual release *slower*. The argument for them is fewer failed releases and faster recovery — not faster delivery | [business-value.md](business-value.md#3-what-cannot-be-claimed) |
| Observability is scheduled too late by the standard phase order and should be pulled forward — rollback cannot be validated without it | [devops-roadmap.md](devops-roadmap.md#2-phases) |
| The blueprint's own principal risk is **false assurance**: a document set this thorough reads as though the work is done | [risk-register.md](risk-register.md#8-the-registers-own-risk) |

---

## Related

- [Documentation index](../README.md)
- [Governance](../10-governance/)
- [Disaster recovery](../11-disaster-recovery/)
