# 12 — Onboarding

## Purpose

Gets people and projects productive on the platform quickly and consistently.

## Scope

Onboarding paths for individual developers, for new application projects, and for engineers joining the DevOps team.

## Audience

New developers, project leads, and DevOps team members.

## Status

**Draft for review.** All three documents are written. They describe onboarding to a platform that has not been built; the standards themselves are real today.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [developer-onboarding.md](developer-onboarding.md) | The five standards a developer actually needs, ten non-obvious constraints, access, first change, what is expected | Draft |
| [new-project-onboarding.md](new-project-onboarding.md) | A 47-step ordered checklist from repository creation to first production deployment, each linked to the standard defining it | Draft |
| [devops-team-onboarding.md](devops-team-onboarding.md) | Reading path by week, what is not built, what you operate, how it fails, on-call readiness, first tasks, judgement calls | Draft |

## Reading Order

Pick the one that applies to you. They are alternatives, not a sequence.

---

## New Project Checklist

The full 47-step sequence is in [new-project-onboarding.md](new-project-onboarding.md), each step linked to the standard that defines it.

Steps 1–32 and 35–39 can be completed today. Deployment configuration and the production approver are blocked — see [new-project-onboarding.md](new-project-onboarding.md#11-currently-blocked).

## Design Choices Worth Reviewing

| Choice | Reasoning |
| --- | --- |
| A developer reads **five** standards, not 39 | A 39-document onboarding path is not read. The rest is reference material — a standard read before it was needed is not remembered when it is |
| "Ten things that will catch you out" precedes any standard | Those ten account for most onboarding friction, and none is obvious from the code |
| The platform team reads the **risk register in week one** | They are inheriting those risks; it is the most concentrated account of where the platform is weak |
| On-call readiness is a **checklist of things you can do**, not time served | Including having performed or watched a restore test, and having been through one release |
| The new-project checklist marks what is **currently blocked** rather than presenting an unachievable sequence | A checklist with silently impossible steps stops being followed |

## Ordering Constraints in the Project Checklist

Three orderings are deliberate and worth preserving:

| Before | After | Why |
| --- | --- | --- |
| Observability | Pipeline | Deployment verification and automatic rollback depend on the service reporting whether it works |
| Retention configuration | First production deployment | Retention bounds how far back a rollback can reach |
| **A rollback executed in UAT** | First production deployment | Rollback designed but never executed is an assumption. One hour in UAT is the difference between having a recovery path and believing you have one |

---

## Open Items

- `TBD` — access request process and approving role
- `TBD` — required local tooling versions
- `TBD` — expected time-to-first-deployment for a new project
- `TBD` — who owns onboarding for each application team

---

## Related

- [Documentation index](../README.md)
- [Repository overview](../../README.md)
- [Source control](../04-source-control/)
- [CI/CD](../05-ci-cd/)
- [Project template](../../templates/project-template/)
