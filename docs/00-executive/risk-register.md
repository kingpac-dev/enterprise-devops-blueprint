# Risk Register

## Purpose

Consolidates the risks identified across the blueprint into one register, so the total exposure is visible rather than distributed across 31 documents.

## Audience

Engineering management, platform owners, security, and whoever accepts residual risk.

## Status

**Draft for review.** Ratings are engineering judgement, not measurement. **No owner role has been assigned to any person or team**, and no mitigation has been implemented — so every residual rating below reflects the current, unmitigated state.

---

## 1. How to Read This

| Field | Meaning |
| --- | --- |
| Impact | Consequence if it occurs |
| Likelihood | Judgement, on the current design, before mitigation |
| Mitigation | What reduces it, and whether that exists |
| Detection | How the organization would know |
| Owner role | Role accountable — never an individual |
| Residual | What remains **after** the stated mitigation, given its current state |

Ratings are Low, Medium, High, Critical. They are relative judgements about this platform at this scale, not absolute measures.

Two properties of the current state apply to every entry: **no mitigation has been implemented**, and **no owner has been assigned**. Residual ratings therefore describe today, not the designed end state.

---

## 2. Platform Availability

### R-01 — Jenkins unavailable

| | |
| --- | --- |
| Impact | **High.** No builds, no deployments, no orchestrated rollback. Delivery stops entirely |
| Likelihood | Medium. Single instance, no redundancy |
| Mitigation | Controller configuration backup with tested restore; documented recovery runbook. **Neither exists** |
| Detection | Availability monitoring and alerting. Not implemented |
| Owner role | `TBD` — platform owner |
| Residual | **High.** Recovery time is currently unbounded because no restore has been demonstrated |

### R-02 — Harbor unavailable

| | |
| --- | --- |
| Impact | **Critical.** Deployment **and rollback** both stop. The recovery path shares its dependency with the failure path, so a bad release during a Harbor outage has no clean recovery |
| Likelihood | Medium. Single instance |
| Mitigation | Availability monitoring; a host-local image cache would reduce but not remove it. **Neither exists**; the cache is not currently designed |
| Detection | Availability monitoring. Not implemented |
| Owner role | `TBD` — platform owner |
| Residual | **Critical.** This is the single most consequential availability risk in the architecture |

### R-03 — Harbor storage exhaustion

| | |
| --- | --- |
| Impact | High. Publication fails; depending on configuration, pulls fail. A platform-wide outage originating in a disk that filled predictably |
| Likelihood | **High** without monitoring. Registry storage grows continuously and does not shrink on its own |
| Mitigation | Retention policy, scheduled garbage collection, capacity monitoring with margin. Defined, **not implemented** |
| Detection | Storage monitoring with an alert threshold well before exhaustion |
| Owner role | `TBD` — platform owner |
| Residual | High until monitoring and garbage collection are operating |

### R-04 — Runtime host loss

| | |
| --- | --- |
| Impact | High. The environment is down; there is no automatic rescheduling |
| Likelihood | Low to Medium |
| Mitigation | Accepted at this scale. Removing it requires orchestration, deliberately deferred |
| Detection | Host and service monitoring. Not implemented |
| Owner role | `TBD` — platform owner |
| Residual | **High, and knowingly accepted.** Revisit if single-host failure becomes unacceptable — see [devops-roadmap.md](devops-roadmap.md) |

### R-05 — Host disk exhaustion from unrotated logs

| | |
| --- | --- |
| Impact | High. A full disk stops **every** container on the host, not only the noisy one, and frequently the host's own recovery ability |
| Likelihood | **High** without configuration. The default Docker log driver has no size limit |
| Mitigation | Log rotation limits in every production Compose file; disk monitoring. Defined, **not implemented** |
| Detection | Disk usage alerting |
| Owner role | `TBD` — platform owner |
| Residual | High. Cheap to mitigate; commonly omitted |

---

## 3. Supply Chain and Artifact Integrity

### R-06 — Artifact substituted in the registry

| | |
| --- | --- |
| Impact | **Critical.** Arbitrary code enters production through an entirely legitimate deployment, passing health checks and producing an accurate audit record naming a real approver. No downstream control detects it |
| Likelihood | Low, but the consequence is unbounded |
| Mitigation | Registry access control, pull-only credentials on runtime hosts, enforced tag immutability, and eventually image signing verified at the runtime host. **None implemented** |
| Detection | Registry audit log; signature verification once it exists |
| Owner role | `TBD` — security owner |
| Residual | **Critical** until access control and immutability are enforced |

### R-07 — Compromised CI credentials

| | |
| --- | --- |
| Impact | **Critical.** Jenkins holds credentials for every environment and is authorized to publish artifacts and change production. Its compromise is compromise of the delivery chain, and it is undetectable downstream |
| Likelihood | Low to Medium |
| Mitigation | Credential scoping per job and environment, restricted controller access, ephemeral agents, rotation, audit logging. **None implemented** |
| Detection | Controller audit logs; anomalous publication or deployment |
| Owner role | `TBD` — security owner |
| Residual | **Critical.** This is the architecture's principal security concentration and cannot be removed at this scale, only constrained |

### R-08 — Unpatched base images

| | |
| --- | --- |
| Impact | Medium to High. Known vulnerabilities present in every image built on the affected base |
| Likelihood | **High.** Pinning without an update process makes the accumulation invisible while appearing to be the secure state |
| Mitigation | Approved base image list, pinning, a defined update cadence, and image re-scanning. Defined, **not implemented** |
| Detection | Registry re-scan of stored images against the current vulnerability database |
| Owner role | `TBD` — security owner |
| Residual | High until the update process exists, not merely the pinning |

### R-09 — Compromised or substituted dependency

| | |
| --- | --- |
| Impact | High. Malicious code enters the artifact through a trusted input; scanning does not detect deliberate backdoors |
| Likelihood | Low to Medium |
| Mitigation | Lockfiles, dependency pinning, trusted feeds, dependency-confusion protection if a proxy is adopted. **Not implemented** |
| Detection | Limited. Dependency scanning finds known vulnerabilities, not novel malicious code |
| Owner role | `TBD` — security owner |
| Residual | **Medium to High.** Detection is weak by nature; prevention through trusted inputs is the primary control |

### R-10 — Stale vulnerability database produces false assurance

| | |
| --- | --- |
| Impact | Medium to High. A clean report indistinguishable from a genuinely clean scan. Worse than no scan, because false assurance is acted upon |
| Likelihood | Medium. Controlled outbound access makes the update path fragile |
| Mitigation | Permitted egress or an internal mirror; a staleness threshold that blocks. Defined, **not implemented** |
| Detection | Database age check before the scan is trusted |
| Owner role | `TBD` — security owner |
| Residual | Medium |

---

## 4. Secrets and Access

### R-11 — Secret committed to Git

| | |
| --- | --- |
| Impact | High. History is permanent for practical purposes; every clone, fork, mirror, and CI cache retains it. Remediation is rotation, not deletion |
| Likelihood | **Medium to High** without automated scanning. It is a routine human error |
| Mitigation | `.gitignore`, `.dockerignore`, secret scanning on push and in the pipeline, review. Policy exists; **scanning not implemented** |
| Detection | Secret scanning. Not implemented |
| Owner role | `TBD` — security owner |
| Residual | High until scanning is enforced |

### R-12 — Credentials shared across environments

| | |
| --- | --- |
| Impact | **High.** Converts a low-value DEV compromise into a production compromise, silently. DEV has the widest access and weakest controls, making it the natural pivot |
| Likelihood | **High** without enforcement. Sharing happens for convenience, not by decision |
| Mitigation | Distinct credentials per environment, enforced at issuance. Required by standard; **not implemented** |
| Detection | Credential inventory and review |
| Owner role | `TBD` — security owner |
| Residual | High |

### R-13 — Credential exposure through container inspection

| | |
| --- | --- |
| Impact | Medium to High. Application secrets currently live in environment variables, which are visible to anyone with container inspection access and inherited by every child process |
| Likelihood | Medium |
| Mitigation | Restrict inspection access (tier 2); adopt file-based secrets. **Neither implemented**; file-based secrets are `TBD` |
| Detection | Access records. Not implemented |
| Owner role | `TBD` — security owner |
| Residual | Medium to High. Read-only inspection is intuitively harmless and is closer to credential access |

### R-14 — Excessive standing privilege

| | |
| --- | --- |
| Impact | Medium to High. An ordinary compromise reaches much further than it should |
| Likelihood | **High** over time. Accumulates through copied grants, role changes that add rather than replace, and automation accounts outliving their purpose |
| Mitigation | Role-based grants, credential expiry, tiered production access, periodic review. Defined, **not implemented** |
| Detection | Access review |
| Owner role | `TBD` — security owner |
| Residual | High. This is drift rather than an event, so it has no moment at which anyone notices |

### R-15 — Credentials written into centralized logs

| | |
| --- | --- |
| Impact | Medium to High. Centralized storage retains them for the full retention period, in backups, and readable by a wider group than the systems they belong to |
| Likelihood | Medium. Typically introduced by a generic exception handler rather than a careless line — some exception types carry connection strings, so the leak occurs specifically when a database connection fails |
| Mitigation | Never-log list, source-level redaction, review. Defined, **not implemented** |
| Detection | Secret scanning over logs. Not planned |
| Owner role | `TBD` — security owner |
| Residual | Medium to High |

---

## 5. Delivery and Recovery

### R-16 — Insufficient rollback capability

| | |
| --- | --- |
| Impact | **High.** An extended outage that a working rollback would have ended in minutes |
| Likelihood | Medium to High. Rollback is currently designed but never executed |
| Mitigation | Rollback designed before first production deployment, previous version recorded before deploying, and a **tested** rollback exercise. **Not implemented** |
| Detection | Rollback exercises; rollback count over time |
| Owner role | `TBD` — platform owner |
| Residual | **High. Recovery capability is unproven until a rollback has been demonstrated** |

### R-17 — Rollback target evicted by retention

| | |
| --- | --- |
| Impact | High. The rollback fails at the moment it is needed, having appeared configured and correct until then |
| Likelihood | Medium. Occurs when retention is tuned for storage cost rather than derived from required rollback depth |
| Mitigation | Retention derived from rollback depth; exemption for currently deployed images and their predecessors; periodic verification that each production service's previous image still exists. Defined, **not implemented** |
| Detection | Automated check that the previous known-good image is present |
| Owner role | `TBD` — platform owner |
| Residual | Medium to High. Silent until it matters |

### R-18 — Vulnerability pull-blocking prevents an emergency rollback

| | |
| --- | --- |
| Impact | High. The security control and the recovery mechanism collide precisely when both matter — a previously good image that has since acquired a finding cannot be redeployed |
| Likelihood | Medium, if pull-blocking is enabled without an emergency path |
| Mitigation | A documented, authorized, audited, time-limited emergency bypass. **Not decided** |
| Detection | Failed rollback |
| Owner role | `TBD` — security owner |
| Residual | Medium. Fully avoidable by deciding the emergency path before enabling the control |

### R-19 — Irreversible database migration

| | |
| --- | --- |
| Impact | **High.** Redeploying the previous image does not undo a schema change; the old code fails against the new schema. Rollback is unavailable exactly when needed |
| Likelihood | Medium. Migrations are routine |
| Mitigation | Expand/contract migrations, backward compatibility, backup before destructive changes, and the limitation stated in the release notes **before approval**. Defined, **not implemented** |
| Detection | Review at pull request and at approval |
| Owner role | `TBD` — service owner |
| Residual | Medium. Never promise automatic rollback for irreversible changes |

### R-20 — Fix reaches `main` but not `develop`

| | |
| --- | --- |
| Impact | Medium to High. The defect returns in a later release, its author believes it is fixed, and the reappearance is separated from its cause by a full release cycle |
| Likelihood | **High** without automation. Merge-back depends on discipline immediately after a release, when attention has moved on |
| Mitigation | An automated comparison of `main` against `develop`. Defined, **not implemented** |
| Detection | The automated check. Nothing else detects it before the defect returns |
| Owner role | `TBD` — platform owner |
| Residual | High. Cheap to automate; the single highest-value automation in the source control standards |

---

## 6. Operational Drift

### R-21 — Manual production change

| | |
| --- | --- |
| Impact | Medium to High. The runtime diverges from the audit record. The change is additionally **reverted silently at the next deployment**, so the problem returns days later in an unrelated release |
| Likelihood | **High** without controls. Manual intervention is the fastest path during an incident |
| Mitigation | Change records for every manual change including emergencies, a follow-up path into the pipeline, restricted modification permissions. Defined, **not implemented** |
| Detection | Change record reconciliation; configuration drift detection. Not planned |
| Owner role | `TBD` — operations owner |
| Residual | High |

### R-22 — Portainer used as a deployment path

| | |
| --- | --- |
| Impact | Medium to High. An ungoverned deployment path that bypasses every gate, review, and record |
| Likelihood | Medium. It is convenient, and convenience wins under pressure |
| Mitigation | Modification permissions restricted; the boundary enforced by permissions rather than intent. **Not implemented** |
| Detection | Access records; change record reconciliation |
| Owner role | `TBD` — platform owner |
| Residual | Medium to High. Note that routing pipeline deployments through the Portainer API would make this boundary unenforceable |

### R-23 — Exception accumulation

| | |
| --- | --- |
| Impact | Medium to High. Individually reasonable exceptions sum to a control set that no longer operates. The aggregate is invisible without a single register |
| Likelihood | **High** over time. Accumulation happens through good-faith grants and deprioritized remediation, not abuse |
| Mitigation | Single register, mandatory expiry with automatic enforcement, escalation on repeated renewal. Defined, **not implemented** |
| Detection | Register review; the count of expired-but-still-in-effect exceptions |
| Owner role | `TBD` — security owner |
| Residual | High. Drift rather than an event |

### R-24 — Emergency change becomes the fast path

| | |
| --- | --- |
| Impact | Medium. Changes bypass approval and verification routinely rather than exceptionally |
| Likelihood | Medium to High, if the normal path is painful |
| Mitigation | A usable normal path; a defined emergency qualification; mandatory recording and retrospective review. Defined, **not implemented** |
| Detection | Emergency-change share as a proportion of all changes |
| Owner role | `TBD` — change approver |
| Residual | Medium. Treat a rising share as a process defect rather than misconduct |

---

## 7. Detection and Evidence

### R-25 — Alerting path fails silently

| | |
| --- | --- |
| Impact | **High.** A broken alert path produces exactly the same signal as a healthy platform: silence. Outages go undetected until a user reports them |
| Likelihood | Medium. Multiple failure points: Prometheus, rule loading, routing, destination |
| Mitigation | A heartbeat alert watched by something **outside** the system it watches. Defined, **not implemented** |
| Detection | Only the heartbeat. Nothing else distinguishes a broken alert path from health |
| Owner role | `TBD` — platform owner |
| Residual | **High.** Undetectable by construction until the heartbeat exists |

### R-26 — Monitoring lost to label cardinality

| | |
| --- | --- |
| Impact | High. Prometheus or Loki becomes unusable; detection is lost at the moment a problem is acquired |
| Likelihood | Medium. A single well-intentioned change adding a user identifier or request path as a label is sufficient |
| Mitigation | Label conventions, review of new metrics, a series-count limit that alerts before it is reached. Defined, **not implemented** |
| Detection | Series count monitoring |
| Owner role | `TBD` — platform owner |
| Residual | Medium to High. Fails suddenly rather than gradually |

### R-27 — Monitoring gaps

| | |
| --- | --- |
| Impact | Medium to High. Problems are discovered by users rather than by the platform |
| Likelihood | Medium |
| Mitigation | Required signals per service, alert coverage review, incidents without an alert treated as a coverage defect. Defined, **not implemented** |
| Detection | Incident review — specifically, incidents detected by user report |
| Owner role | `TBD` — service owner |
| Residual | Medium |

### R-28 — No deployment records

| | |
| --- | --- |
| Impact | **High.** No end-to-end question is answerable: what is running, from which commit, approved by whom. Every other evidence source is an unconnected fragment |
| Likelihood | **Certain today.** Nothing is captured |
| Mitigation | Automatic deployment record generation by the pipeline. Designed, **not implemented** |
| Detection | Not applicable — the absence is the condition |
| Owner role | `TBD` — platform owner |
| Residual | **High.** The evidence gap to close before the others |

### R-29 — Evidence integrity limited to platform-native records

| | |
| --- | --- |
| Impact | Medium. Records held by the systems that perform the actions demonstrate normal operation, not integrity against an adversary with administrative platform access |
| Likelihood | Low, and the same event as R-07 seen from the audit side |
| Mitigation | An append-only store outside the platform. **Not proposed at this scale** |
| Detection | Limited by definition |
| Owner role | `TBD` — security owner |
| Residual | **Medium, and knowingly accepted.** Stated so the acceptance is deliberate rather than unexamined |

### R-30 — Missing or untested backups

| | |
| --- | --- |
| Impact | **Critical.** Unrecoverable loss of Jenkins configuration, Harbor metadata, image storage, or SonarQube data |
| Likelihood | Medium for missing; **High** for untested |
| Mitigation | Backup standard covering all platform components, plus **restore testing**. Defined, **not implemented** |
| Detection | Restore test results |
| Owner role | `TBD` — platform owner |
| Residual | **Critical. A backup is not operationally reliable until a restore has been demonstrated.** No restore has been performed |

---

## 8. The Register's Own Risk

### R-31 — False assurance from the documentation itself

| | |
| --- | --- |
| Impact | **High.** A document set this thorough reads as though the capability exists. Decisions get made on a security posture that is documented rather than implemented |
| Likelihood | Medium to High. It is the most likely way this work causes harm |
| Mitigation | Explicit status per control, "not implemented" recorded rather than implied, and this entry |
| Detection | Any statement about the organization's posture that cites a standard rather than an implementation |
| Owner role | `TBD` — platform owner |
| Residual | Medium, and dependent entirely on how the blueprint is communicated |

---

## 9. Highest Priority

By residual rating and by how cheaply each can be reduced:

| Rank | Risk | Why here |
| --- | --- | --- |
| 1 | R-30 Untested backups | Critical, unrecoverable, and the test is cheap |
| 2 | R-02 Harbor unavailable | Critical; blocks deployment **and** rollback |
| 3 | R-07 Compromised CI credentials | Critical; undetectable downstream |
| 4 | R-06 Artifact substitution | Critical; access control and immutability are inexpensive |
| 5 | R-28 No deployment records | Blocks every audit and incident question |
| 6 | R-16 Rollback unproven | The control most relied upon and least demonstrated |
| 7 | R-25 Silent alert path failure | Undetectable by construction; the heartbeat is cheap |
| 8 | R-20 Merge-back failure | High likelihood; the automation is trivial |

Items 1, 7, and 8 are the cheapest to reduce and should not wait for the platform to be complete.

---

## 10. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — owner role assignment for every entry | Whether any risk is owned |
| `TBD` — who accepts residual risk | R-04, R-29, and any risk not mitigated |
| `TBD` — review frequency for this register | Whether it stays accurate |
| `TBD` — whether an image cache decouples rollback from Harbor | R-02, R-17 |
| `TBD` — likelihood ratings revisited once the platform exists and produces data | Rating credibility |

Risks R-04 and R-29 are **knowingly accepted** design consequences and need a named accepting role rather than a mitigation. Until that role exists, they are accepted by default — by whoever declines to block the work.

---

## Related

- [Executive summary](executive-summary.md)
- [DevOps roadmap](devops-roadmap.md)
- [KPIs and success metrics](kpi-and-success-metrics.md)
- [Security baseline](../07-security/security-baseline.md)
- [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md)
- [Governance](../10-governance/)
