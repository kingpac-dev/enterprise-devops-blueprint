# High Availability Roadmap

## Purpose

States where single points of failure exist, what would remove each, what that costs, and what would justify paying it.

## Scope

Availability of the delivery platform and application runtimes.

## Audience

Platform owners, architects, and whoever accepts the residual risk of not doing this yet.

## Status

**Draft for review.** Nothing here is implemented. **Every single point of failure below currently exists and is knowingly accepted.**

---

## 1. The Honest Position

This architecture has several single points of failure. They are consequences of deliberate simplicity, not oversights, and each is documented in the [risk register](../00-executive/risk-register.md).

Removing them costs permanent operational complexity. This document exists so that the decision to defer is made knowingly and revisited on evidence rather than on preference.

Before reading further, one distinction determines urgency: **losing the delivery platform is not losing production.** Running containers keep serving when Jenkins or Harbor stops — what is lost is the ability to *change* them. See [disaster-recovery-plan.md](../11-disaster-recovery/disaster-recovery-plan.md#1-the-distinction-that-changes-everything).

---

## 2. Current Single Points of Failure

| # | Component | Loses | Type |
| --- | --- | --- | --- |
| SPOF-1 | **Harbor** | Deployment **and rollback** | Critical |
| SPOF-2 | Jenkins | All delivery | Delivery outage |
| SPOF-3 | Runtime host | Every service on it | **Service outage** |
| SPOF-4 | Prometheus | **Detection** — silently | Delivery and service both look fine |
| SPOF-5 | SonarQube | Delivery, because the gate fails closed | Delivery outage |
| SPOF-6 | Backup storage | Recovery capability | No symptom until needed |

SPOF-1 and SPOF-3 are the two that hurt.

**Harbor** because the recovery path shares its dependency with the failure path: a bad release coinciding with a Harbor outage has no clean way back.

**A runtime host** because it is the only one that takes production down, and there is no automatic rescheduling.

**Prometheus** deserves attention despite being neither: its failure produces silence, which is indistinguishable from health.

---

## 3. What Would Remove Each

### SPOF-1 — Harbor

| Option | Removes | Cost | Note |
| --- | --- | --- | --- |
| **Host-local image cache** | The rollback dependency, mostly | Low | **Cheapest meaningful mitigation available.** Does not remove the SPOF; removes its worst consequence |
| Harbor replication to a second instance | Availability of pulls | Medium | Two registries to operate and keep consistent |
| Harbor in HA configuration | The SPOF | High | Clustered database and shared storage |

The image cache is worth doing regardless of the rest. If the previous known-good image is present on the host, a rollback survives a registry outage — which converts the platform's worst case from "no recovery" into "no new deployments".

`TBD` — whether an image cache or an export of currently deployed images is adopted. It is not currently designed.

### SPOF-2 — Jenkins

| Option | Removes | Cost |
| --- | --- | --- |
| Tested backup and a documented restore | Not the SPOF — the **unbounded recovery time** | Low |
| Controller configuration as code | Rebuild time | Medium |
| Active/passive controller | Most of the SPOF | High |
| Managed CI | The SPOF, at the price of the constraint that ruled it out | High, and a policy change |

The first is the highest-value item and is not high availability. It converts "unknown recovery time" into "measured recovery time", which is most of the practical benefit at a fraction of the cost.

### SPOF-3 — Runtime host

| Option | Removes | Cost |
| --- | --- | --- |
| Host configuration as code | Rebuild time | Medium |
| A standby host per environment | Most of the outage, manually | Medium — idle hardware |
| Container orchestration | The SPOF | **High, and permanent** |

Orchestration is the real answer and is deliberately deferred — see [ADR-0005](../../adr/0005-use-docker-compose-for-initial-runtime.md). Adopting it before the pain exists adds a control plane to install, secure, upgrade, back up, and recover.

Host configuration as code is the interim step that matters, because with no rescheduling, recovery *is* rebuilding, and rebuild speed is entirely determined by whether the configuration exists anywhere other than on the lost host.

### SPOF-4 — Prometheus

| Option | Removes | Cost |
| --- | --- | --- |
| **Heartbeat with an external watcher** | The silence — makes the failure detectable | **Very low** |
| A second Prometheus scraping the same targets | The SPOF for alerting | Medium |
| Federated or HA Prometheus | The SPOF | Medium to high |

The heartbeat is cheap and is the only one of these that must exist. Without it, a Prometheus that stopped and a platform that is healthy produce the same observable signal. See [alerting-standard.md](../08-observability/alerting-standard.md#6-monitoring-the-monitoring).

### SPOF-5 — SonarQube

Fails closed by design, which is correct: an unevaluated gate is not a pass. Its unavailability stops delivery and does not affect production.

| Option | Cost |
| --- | --- |
| Tested backup and restore | Low |
| A documented, time-bounded exception path for a prolonged outage | Low — a governance artifact, not infrastructure |

High availability is not justified here. The exception path is, because the pressure to make the gate advisory arrives within hours of the first outage, and the alternative to a documented path is an undocumented one.

### SPOF-6 — Backup storage

| Option | Cost |
| --- | --- |
| A second copy, off the primary infrastructure | Low to medium |
| **Restore testing** | Low — and it is what makes any of it real |

Restore testing does not remove the SPOF. It is listed here because without it the other backup work is unverified, and unverified recovery capability is indistinguishable from none.

---

## 4. Order, by Value per Cost

| Order | Action | Removes | Cost |
| --- | --- | --- | --- |
| 1 | **Restore testing** | Unproven recovery — risk R-30, ranked first | Very low |
| 2 | **Heartbeat with an external watcher** | Silent detection failure | Very low |
| 3 | Backups for every component, with failure alerting | Unbounded recovery time | Low |
| 4 | **Host-local image cache** | The rollback-depends-on-Harbor coupling | Low |
| 5 | Host configuration as code | Rebuild time for every host | Medium |
| 6 | Standby host for production | Most of the production outage window | Medium |
| 7 | Harbor replication | Pull availability | Medium |
| 8 | Container orchestration | SPOF-3 entirely | High, permanent |

**Items 1 to 4 are cheap, and none requires the platform to be complete.** Together they address the two worst consequences — unproven recovery and a rollback path coupled to the registry — without adding a single component.

Items 5 to 8 are infrastructure investment and should follow evidence.

---

## 5. What Would Justify the Expensive Items

| Signal | Justifies |
| --- | --- |
| Production host failure causes an unacceptable outage | Orchestration, or a standby host |
| Delivery frequency makes Jenkins downtime materially expensive | Jenkins HA, or a different platform |
| Harbor outage blocks a needed rollback, in reality | Replication, and the image cache immediately |
| Service count makes manual placement impractical | Orchestration |
| Detection gaps are found during incident reviews | Observability redundancy |

None is currently true, because nothing is running. Revisit once there is operational data — which is the first thing this platform will produce that the blueprint could not.

---

## 6. What Is Being Accepted Meanwhile

Stated plainly, so the acceptance is deliberate:

- A production host failure is a **service outage** with no automatic recovery, recovered by rebuilding or restoring the host.
- A Harbor outage blocks deployment **and rollback**.
- A Jenkins outage stops delivery entirely, with recovery time currently **unbounded** because no restore has been demonstrated.
- A Prometheus outage is **undetectable** until the heartbeat exists.

`TBD` — the role that accepts this residual risk. Until one is named, it is accepted by default, by whoever declines to block the work.

---

## 7. Open Items

| Item |
| --- |
| `TBD` — who accepts the residual risk in section 6 |
| `TBD` — whether a host-local image cache or an export of deployed images is adopted |
| `TBD` — whether a standby production host is justified |
| `TBD` — host configuration as code |
| `TBD` — RTO per component, measured rather than assumed |
| `TBD` — review point for revisiting this document |

---

## Security Considerations

Availability work and security work overlap here. Backup storage holds credentials for every environment, so a second copy is a second place those credentials exist — it needs the same encryption, access restriction, and access recording as the first.

A host-local image cache means images sit on runtime hosts outside the registry's access control and immutability guarantees. Its contents should be treated as read-only and its integrity considered, not assumed.

## Operational Considerations

The four cheap items in section 4 are cheap because they add no components. Everything above item 4 adds something permanent to operate, and operating it competes with the work the platform exists to support.

The most likely failure of this roadmap is not choosing wrongly between the expensive options. It is never doing items 1 to 4, because each is small enough to defer indefinitely and none has a deadline.

---

## Related

- [Infrastructure standard](infrastructure-standard.md)
- [Risk register](../00-executive/risk-register.md)
- [Disaster recovery plan](../11-disaster-recovery/disaster-recovery-plan.md)
- [Restore test](../../sop/restore-test.md)
- [ADR-0005 — Docker Compose as the initial runtime](../../adr/0005-use-docker-compose-for-initial-runtime.md)
