# DevOps Team Onboarding

## Purpose

Brings an engineer joining the platform team to the point of operating the platform and taking on-call responsibility.

## Scope

Platform internals, operational responsibilities, and on-call readiness. Application developers have a shorter path in [developer-onboarding.md](developer-onboarding.md).

## Audience

Engineers joining the platform team, and whoever onboards them.

## Status

**Draft for review.** The platform does not exist yet, so sections 4 and 6 describe a target state.

---

## 1. What You Are Taking On

The platform team operates the delivery toolchain — Jenkins, Harbor, SonarQube, and the observability stack — and the runtime hosts. Application teams own what runs on them.

Two properties of this architecture shape the job more than anything else, and you should understand them before the first week is out:

**Jenkins holds credentials for every environment and is authorized to publish artifacts and change production.** Its compromise is compromise of the delivery chain, and no downstream control detects it — everything it produces afterwards is legitimate in every observable respect.

**Harbor holds the only copy of every deployable artifact, and both deployment and rollback pull from it.** The recovery path shares its dependency with the failure path. A bad release coinciding with a Harbor outage has no clean way back.

Neither can be removed at this scale. Constraining them is much of what this role is.

---

## 2. Reading Path

Order matters here more than for developers, because the later documents assume the earlier ones.

### Week one — understand the shape

| Read | Why |
| --- | --- |
| [Executive summary](../00-executive/executive-summary.md) | State of things, and what is not built |
| [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md) | The design and its known weaknesses |
| [Logical architecture](../01-architecture/logical-architecture.md) | Planes, boundaries, control points, failure isolation |
| [Environment architecture](../01-architecture/environment-architecture.md) | How DEV, UAT, and PROD differ |
| [Service interaction](../01-architecture/service-interaction.md) | What talks to what, and what happens when it cannot |
| **[Risk register](../00-executive/risk-register.md)** | **The risks you are inheriting** |

Read the risk register early rather than late. It is the most concentrated account of where this platform is weak, and every entry is something that could become your incident.

### Week two — the standards you enforce

| Read |
| --- |
| [Container standards](../06-container/) — all six |
| [Security standards](../07-security/) — baseline, secrets, vulnerability, access control first |
| [Observability standards](../08-observability/) — all five |

### Week three — how it is run

| Read |
| --- |
| [Governance](../10-governance/) — all five |
| [Disaster recovery](../11-disaster-recovery/) — all three |
| [Operations runbooks](../09-operations/) — not yet written |

---

## 3. What Is Not Built

You are joining a documented design, not a running platform. Being precise about this matters, because you will be asked what the organization's posture is.

| Area | State |
| --- | --- |
| Toolchain installed | No |
| Pipelines running | No |
| Backups taken | **No** |
| Restore tested | **No** |
| Deployment records captured | No |
| Monitoring and alerting | No |
| Security controls enforced | **None** — every control's status is "not implemented" or "policy only" |

The security baseline's control catalogue records this per control deliberately, so the distinction between a documented control and an operating one stays visible. Preserving that distinction in what you tell people is part of the job — see risk R-31.

---

## 4. What You Operate

Once built:

| Component | Ongoing responsibility |
| --- | --- |
| Jenkins | Patching, plugin management, agent capacity, credential hygiene, **backup with tested restore** |
| Harbor | Storage capacity, garbage collection, retention, robot accounts, availability |
| SonarQube | Database maintenance, upgrades, quality gate definitions |
| Prometheus, Grafana, Loki | Scrape configuration, rules, dashboards, retention, cardinality |
| Runtime hosts | OS patching, Docker, disk, network |
| Backups | Execution, monitoring, and restore testing |

The recurring items are the ones that lapse: credential rotation, access review, base image updates, restore testing, and standard review. Each has ongoing cost and no immediate consequence for skipping, which is exactly the category of work that quietly stops.

---

## 5. What Fails, and How

The failures worth knowing before you meet them.

| Failure | Property that makes it hard |
| --- | --- |
| Harbor unavailable | Blocks deployment **and** rollback |
| Alert path broken | Produces the same signal as health: silence |
| Label cardinality explosion | Fails suddenly; takes monitoring down at the moment a problem appears |
| Host disk full | Stops **every** container on the host, and often its own recovery |
| Rollback target evicted by retention | Silent until the rollback is attempted |
| Manual change | Reverted at the next deployment; returns days later in an unrelated release |
| Merge-back missed | Defect returns a full release cycle later |
| Stale vulnerability database | Clean report indistinguishable from a genuinely clean scan |

The common shape: **the failure and its symptom are separated**, either in time or in causation. That is what makes them expensive, and knowing the list in advance is most of the mitigation.

---

## 6. On-Call Readiness

`TBD` — the rotation and escalation model.

Before taking a page, you should be able to answer yes to all of these:

| Readiness check |
| --- |
| I have the access required to act, and I have used it |
| I know the escalation path without looking up a name |
| I can execute the rollback runbook |
| I have performed a restore test, or watched one |
| I know which failures block rollback, and what to do instead |
| I know the difference between a delivery outage and a service outage |
| I know where deployment records and change records are |
| I have been through at least one release |

The last two are frequently missing and both cost time during an incident: not knowing what was deployed, and not having seen the normal path work.

`TBD` — whether shadowing is required before joining the rotation. Recommended: yes.

---

## 7. First Tasks

Work that is useful, bounded, and teaches the platform. Ordered by value.

| Task | Teaches | Value |
| --- | --- | --- |
| Perform the first restore test | Backups, recovery, and where the procedures are wrong | **Highest — this is risk R-30, ranked first** |
| Automate the `main` versus `develop` merge-back check | The branch model and its principal failure | High; cheap |
| Implement the heartbeat alert and its external watcher | Alerting, and why silence is ambiguous | High; cheap |
| Draft one platform runbook | The component it covers, in depth | High |
| Review the risk register against reality once the platform exists | Everything | High |

The first three are the cheapest risk reductions available in the whole blueprint, none requires the platform to be complete, and each teaches a different part of it. They are good first tasks for that combination of reasons.

---

## 8. Judgement You Are Expected to Apply

The standards cover the general case. These are the recurring judgement calls they cannot make for you.

| Situation | The standing answer |
| --- | --- |
| A gate is unavailable and a release is waiting | Unavailable is not a pass. If proceeding is genuinely necessary, it is a recorded, time-bounded exception — not a quiet configuration change |
| Someone asks for production access to investigate | Grant the lowest tier that works. Most investigation is possible from dashboards and logs |
| A manual fix would resolve an incident faster | Do it, record it, and open the follow-up. An unrecorded manual change is reverted at the next deployment and returns later |
| A team wants an exception | Scope it narrowly, set an expiry, and record a compensating control. Broad and open-ended is how controls stop operating |
| Emergency changes are rising | Investigate the normal path, not the people. They are giving you accurate feedback |
| A standard does not fit a real case | Fix the standard. Standards that do not fit reality get ignored, and then all of them do |

The last is the one to internalize. Every one of these documents is wrong somewhere — they were written before implementation, and implementation always finds the assumptions. Finding one is a contribution, not a complaint.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — on-call rotation and escalation model | Section 6 |
| `TBD` — whether shadowing is required before the rotation | Readiness |
| `TBD` — access provisioning for platform engineers | Day one |
| `TBD` — expected time to on-call readiness | Planning |
| `TBD` — who owns onboarding for the platform team | Accountability |

---

## Security Considerations

Platform engineers hold the platform's most sensitive access: Jenkins administration, Harbor administration, and production hosts. That access is the concentration described in section 1, and it is why access review, credential expiry, and separation of duties apply to this team most of all.

Backup storage deserves specific attention. It contains credentials for every environment, so reading a backup is equivalent to reading the credential store. Treat access to it as production access.

## Operational Considerations

The gap between documented and operating is the thing to hold onto. You will be asked whether the organization is secure, whether it can recover, whether it is compliant. The accurate answers today are no, unproven, and no claim is made — and giving those answers plainly is more valuable than the alternative.

Section 7's first three tasks reduce real risk before the platform exists. Starting there means the first weeks produce something that matters rather than only reading.

---

## Related

- [Developer onboarding](developer-onboarding.md)
- [New project onboarding](new-project-onboarding.md)
- [Risk register](../00-executive/risk-register.md)
- [Architecture](../01-architecture/)
- [Governance](../10-governance/)
- [Disaster recovery](../11-disaster-recovery/)
