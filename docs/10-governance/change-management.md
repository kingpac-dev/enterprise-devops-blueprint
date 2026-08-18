# Change Management

## Purpose

Defines how changes to production are classified, approved, executed, verified, and recorded.

## Scope

Changes affecting production: application releases, configuration changes, infrastructure changes, and manual interventions. Decision rights are in [devops-governance.md](devops-governance.md); the evidence produced is in [audit-evidence.md](audit-evidence.md).

## Audience

Service owners, release approvers, operators, and platform engineers.

## Status

**Draft for review.** Approver roles and the change record location are undecided.

---

## 1. Design Constraint

`AGENTS.md` requires a lightweight, auditable process and explicitly warns against unnecessary bureaucracy.

Those pull in opposite directions, and the resolution is to put the weight where the risk is. A routine release through a pipeline that already enforces review, quality gates, and security scanning does not need a separate approval meeting — the controls have already run. A manual change to a production host has none of those controls and needs the weight.

The test applied throughout: **does this step change a decision, or does it only record one?** Steps that only record belong in automation.

---

## 2. Change Classes

| Class | Definition | Approval | Record |
| --- | --- | --- | --- |
| **Standard** | Pre-approved, repeatable, low risk, executed through automation | Pre-approved as a class | Automatic |
| **Normal** | Planned change to production | Release or change approver | Before execution |
| **Emergency** | Required now to restore or protect service | Emergency approver | May be after execution |

### Standard change

Pre-approved because the *class* was assessed, not because each instance is trivial.

Candidates: deployment to DEV; deployment to UAT; a routine dependency update that passes all gates; a documented, reversible configuration change through the pipeline.

Requirements for a class to be pre-approved: executed through the pipeline, all gates enforced, automatically recorded, and reversible by a documented path.

`TBD` — the list of pre-approved standard changes.

### Normal change

The default for production. Requires approval before execution, with the approver informed by:

- what changes, and why
- the release notes, including breaking changes and migrations
- rollback availability and any limitation
- verification plan

Production release approval is a normal change — see [release-and-tagging-standard.md](../04-source-control/release-and-tagging-standard.md#5-release-process).

`TBD` — lead time, if any. A required lead time is a common addition that produces one predictable effect: changes that miss the window get reclassified as emergencies.

### Emergency change

For restoring or protecting service now. Approval may follow execution; **recording and review never may.**

| Requirement | Timing |
| --- | --- |
| Emergency approver informed | Before, or immediately after |
| Change recorded | Within `TBD` of execution |
| Retrospective review | Within `TBD` |
| Normal-path follow-up where the fix was partial | Next release |

`TBD` — what qualifies. Without a definition, "emergency" means "I do not want to wait", and the emergency path becomes the fast path.

---

## 3. The Reclassification Problem

**Emergency-change share is the health metric for this whole process.**

When it rises, the usual cause is not more emergencies. It is a normal path that has become painful enough to route around — a lead time that does not fit how work arrives, an approver who is hard to reach, or a form that takes longer than the change.

Treat a rising share as a defect in the process, not as misconduct. The people reclassifying are usually trying to deliver, and they are giving accurate feedback about where the process does not fit.

Monitor it. See [devops-governance.md](devops-governance.md#9-metrics).

---

## 4. The Change Record

Every production change produces a record, whatever its class.

| Field | Content |
| --- | --- |
| Identifier | Change or ticket reference |
| Class | Standard, normal, or emergency |
| Description | What changes |
| Reason | Why |
| Service and environment | |
| Version | Release version and image identifier |
| Requested by | Role |
| Approved by | Role, and when |
| Executed by | Role or automation, and when |
| Verification | What was checked, and the result |
| Outcome | Success, rolled back, or partial |
| Rollback limitation | Where one applies |

Records for pipeline-executed changes are generated automatically. A record a human types is a record that is sometimes not typed.

`TBD` — where records are held, and their retention. See [audit-evidence.md](audit-evidence.md).

---

## 5. Manual Changes

A manual change is anything altering production outside the pipeline: restarting a container by hand, editing a configuration file on a host, changing a setting through Portainer.

They are permitted where necessary, and they are always recorded.

| Requirement | Reason |
| --- | --- |
| Change record, including emergencies | Otherwise the runtime diverges from the record with no trace |
| The reason automation was not used | The answer is often a gap worth fixing |
| Follow-up to bring the change into the pipeline | A manual change repeated is an automation candidate |
| Reconciliation with the deployed artifact | The next deployment overwrites it — see below |

### Manual changes are silently reverted

A manual change to a running container is lost at the next deployment, because the deployment replaces the container from the image.

This creates a specific and confusing failure: a fix is applied manually, the problem goes away, and it returns days later at the next unrelated release. The reappearance is separated from its cause, and the person investigating has no reason to suspect a manual change nobody recorded.

This is the same shape as the merge-back failure in [branching-strategy.md](../04-source-control/branching-strategy.md#5-merging-back-is-where-this-model-fails), and it is why manual changes need a follow-up path into the pipeline rather than only a record.

### Portainer

Portainer is for visibility, troubleshooting, and approved operational tasks. It must not become a deployment path that bypasses CI/CD governance.

That boundary is enforced by permissions rather than intent — see [access-control.md](../07-security/access-control.md#3-proposed-permission-matrix). A modification made through Portainer is a manual change and carries every requirement above.

---

## 6. Post-Deployment Verification

Verification is part of the change, not an optional follow-up. A change is not complete when it is deployed; it is complete when it is verified.

| Step | Requirement |
| --- | --- |
| Health check | Automated, part of the deployment |
| Smoke test | Automated where possible; `TBD` per application type |
| Metric check | Error rate and latency compared against pre-deployment |
| Log check | No new error class |
| Outcome recorded | Success, rolled back, or partial |

`TBD` — the observation window before a change is considered complete. Some failures appear immediately; others appear under load, at a scheduled job, or at the next hourly batch. A change marked successful at deployment plus two minutes has been verified against a narrow slice of its behaviour.

Deployment markers on dashboards make the metric comparison a single glance — see [dashboard-standard.md](../08-observability/dashboard-standard.md#9-deployment-annotations).

---

## 7. Failed Changes

| Outcome | Action |
| --- | --- |
| Health check fails | Automatic rollback where technically safe |
| Smoke test fails | Automatic rollback where technically safe |
| Failure found after the window | Rollback as a new change, or forward fix |
| Rollback unsafe — migration applied | Forward recovery; the limitation was recorded before approval |

The last row is the case that must have been anticipated. If a release contains an irreversible migration, that was stated in the release notes and known at approval — see [release-and-tagging-standard.md](../04-source-control/release-and-tagging-standard.md#6-database-migrations-and-version-meaning). Discovering it during a failed deployment is a process failure that occurred earlier, at approval.

Every failed change is recorded with its evidence. A change that failed and was rolled back is not a change that did not happen.

---

## 8. What Does Not Need This Process

| Change | Why |
| --- | --- |
| Anything in DEV | Non-production |
| Pull requests | Governed by review, not change management |
| Documentation | No production effect |
| Dashboard changes | Governed by pull request |
| Alert rule changes | `TBD` — arguably production-affecting; see below |

Alert rules are worth deciding explicitly. A change to an alert rule does not change the service, but it changes whether a failure is detected — which is a production-affecting change in the only sense that matters during an incident. A rule silently loosened is an undetected outage waiting.

`TBD` — whether alert rule changes require a change record, or pull-request review alone.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — change approver and emergency approver roles | Every production change |
| `TBD` — what qualifies as an emergency | Whether the emergency path is the fast path |
| `TBD` — pre-approved standard change list | How much passes without individual approval |
| `TBD` — change record location, format, and retention | Auditability |
| `TBD` — lead time for normal changes, if any | Reclassification pressure |
| `TBD` — post-deployment observation window | When a change is complete |
| `TBD` — smoke test definition per application type | Verification quality |
| `TBD` — whether alert rule changes are governed here | Detection integrity |
| `TBD` — emergency recording and review deadlines | Emergency accountability |

---

## Security Considerations

The change record is what makes production auditable. Where changes happen without one — manually, or through an ungoverned path — the audit trail stops describing reality, and it does so without any indication that it has.

Emergency change is the weakest point by design: it permits action before approval. Its integrity depends entirely on recording and retrospective review, which are the two steps most easily deferred once the incident is over.

## Operational Considerations

Two failures in this document are the same shape and both are worth designing against: a manual change reverted by the next deployment, and a fix that reaches `main` without reaching `develop`. Both reintroduce a resolved problem later, with the cause separated from the symptom, and in both cases the person who fixed it believes it is fixed.

Verification is where change management earns its cost. A deployed change that was never verified is a change whose outcome nobody knows, recorded as a success.

---

## Related

- [DevOps governance](devops-governance.md)
- [Production access policy](production-access-policy.md)
- [Audit evidence](audit-evidence.md)
- [Release and tagging standard](../04-source-control/release-and-tagging-standard.md)
- [Operations runbooks](../09-operations/)
- [Environment architecture](../01-architecture/environment-architecture.md)
