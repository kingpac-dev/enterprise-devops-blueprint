# 10 — Governance

## Purpose

Defines who decides, who approves, who has access, and what evidence is retained.

## Scope

DevOps governance model, change management, production access, exception handling, and audit evidence.

## Audience

Engineering management, platform owners, security, and auditors.

## Status

**Draft for review.** All five documents are written. The framework is proposed; **no role has been assigned to any person or team**, and no evidence is currently captured.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [devops-governance.md](devops-governance.md) | Roles, decision rights, separation of duties, standard ownership, the platform/team boundary, escalation, governance metrics | Draft |
| [raci-matrix.md](raci-matrix.md) | Formal RACI role matrix, organizational functional mapping, and escalation workflows | Published |
| [change-management.md](change-management.md) | Three change classes, the reclassification problem, change records, manual changes, post-deployment verification, failed changes | Draft |
| [production-access-policy.md](production-access-policy.md) | Access as five tiers rather than a binary, request and review, emergency access, session recording, data access boundary | Draft |
| [exception-management.md](exception-management.md) | What requires an exception, what it records, approval, expiry enforcement, the register, what cannot be excepted | Draft |
| [audit-evidence.md](audit-evidence.md) | The questions evidence must answer, sources, the deployment record, retention, integrity limits, current gaps | Draft |

## Reading Order

1. [devops-governance.md](devops-governance.md) — who decides
2. [change-management.md](change-management.md) — how production changes
3. [production-access-policy.md](production-access-policy.md) — who can reach production
4. [exception-management.md](exception-management.md) — how a standard is deviated from
5. [audit-evidence.md](audit-evidence.md) — what remains afterwards

---

## Production Approval Chain

```text
Release Candidate
Quality Gate
Security Gate
UAT Verification
Production Approval
Deployment
```

Record for each production deployment: approver, version, deployment time, and change or ticket reference.

---

## Governance Principles

- Change management must be lightweight and auditable. Avoid unnecessary bureaucracy.
- Portainer may be used for visibility, troubleshooting, inspection, and approved operational tasks. It must not become an uncontrolled deployment path that bypasses CI/CD governance.
- Manual production changes must follow change control and be recorded.
- Exceptions are time-bounded and recorded with owner role, justification, compensating control, and expiry. An expired exception is a control failure, not a default extension.
- Roles are named by **role**, never by invented individual names.

---

## Open Items

- `TBD` — production approver role
- `TBD` — emergency change authority
- `TBD` — evidence retention period
- `TBD` — exception approval authority
- `TBD` — ticketing system used for change references

## The Blocking Item

**No role in [devops-governance.md](devops-governance.md#2-roles) has been assigned.** Until they are, every approval defined across this repository has no named authority, and approvals will in practice be given by whoever is available — which is the ungoverned state these documents exist to replace.

This is the single decision that unblocks the most `TBD` items elsewhere: production approver, emergency approver, exception authority, access approver, and risk acceptance all resolve from it.

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **Emergency-change share is the health metric for the whole process.** When it rises, the cause is usually a normal path people are avoiding, not more emergencies. Treat it as a process defect, not misconduct | [change-management.md](change-management.md#3-the-reclassification-problem) |
| A manual change to a running container is silently reverted at the next deployment. The problem returns days later, in an unrelated release, with no reason to suspect the unrecorded manual fix | [change-management.md](change-management.md#5-manual-changes) |
| Container inspection (tier 2) displays environment variables, which is where application secrets currently live. It is closer to credential access than to observation | [production-access-policy.md](production-access-policy.md#1-production-access-is-not-one-thing) |
| An expired exception is a control failure, not a default extension — and expiry only works if something enforces it. A `.trivyignore` entry has no expiry concept, so without external enforcement it is permanent by construction | [exception-management.md](exception-management.md#5-expiry-is-the-mechanism) |
| Evidence held by the systems it describes demonstrates normal operation, not integrity against a platform-level adversary. This is the Jenkins concentration risk seen from the audit side | [audit-evidence.md](audit-evidence.md#5-integrity) |

## Structural Choices Worth Confirming

| Choice | Reasoning |
| --- | --- |
| Production access modelled as **five tiers**, not granted or not | A binary model offers only "all" or "nothing", and incident pressure pushes consistently toward all. Tiers make "grant the lowest that works" a possible instruction |
| Evidence requirements derived from **questions that must be answerable**, not from a list of things to log | The usual order produces high volume that answers no question completely |
| **No approval board.** Weight is placed where controls are absent — manual and emergency changes — not on pipeline-executed releases | A pipeline release has already passed review, quality, and security gates. `AGENTS.md` requires lightweight and auditable, and a process heavy enough to route around will be routed around |
| A short **no-exception list** | Those requirements damage records or boundaries retroactively, so a time-bounded exception does not bound the harm |

---

## Related

- [Documentation index](../README.md)
- [Operations](../09-operations/)
- [Security](../07-security/)
- [Executive risk register](../00-executive/)
- [Architecture Decision Records](../../adr/)
