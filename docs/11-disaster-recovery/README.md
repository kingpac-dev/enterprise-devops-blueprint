# 11 — Disaster Recovery

## Purpose

Defines what must be backed up, how recovery is performed, and how recovery capability is proven.

## Scope

Backup requirements, disaster-recovery planning, and restore testing for the delivery platform and its configuration.

## Audience

Platform engineers, operations, and management accountable for recovery objectives.

## Status

**Draft for review.** All three documents are written. **No backup is taken and no restore has ever been performed**, so recovery capability is unproven.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [backup-standard.md](backup-standard.md) | Reproducible versus irreplaceable, backup scope, the Jenkins credential problem, consistency, storage isolation, RPO/RTO framework | Draft |
| [disaster-recovery-plan.md](disaster-recovery-plan.md) | Delivery outage versus service outage, eight failure scenarios, recovery ordering, compound failure, decision authority | Draft |
| [restore-testing.md](restore-testing.md) | Failures only a restore finds, four test levels, testing into a clean target, what each test records, how to start | Draft |

## Reading Order

1. [backup-standard.md](backup-standard.md) — what must be captured
2. [restore-testing.md](restore-testing.md) — how to prove any of it works
3. [disaster-recovery-plan.md](disaster-recovery-plan.md) — what to do when something fails

---

## Backup Scope

```text
Jenkins configuration
Jenkins credentials where securely supported
SonarQube database
Harbor metadata
Harbor image storage
Monitoring configuration
Dashboards
Deployment configuration
Repository documentation
```

## Failure Modes to Document

```text
GitHub unavailable
Jenkins unavailable
Harbor unavailable
SonarQube unavailable
Monitoring unavailable
DEV unavailable
UAT unavailable
PROD host unavailable
```

For each: impact, detection, immediate response, recovery, and long-term mitigation.

---

## Core Principle

A backup is **not** considered operationally reliable until a restore has been demonstrated. Until restore testing exists and its results are recorded, recovery capability is unproven and must be described that way.

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **Losing the delivery platform is not losing production.** Running containers keep serving when Jenkins or Harbor stops — the loss is the ability to *change* them. The dangerous case is a delivery outage that later becomes a service outage | [disaster-recovery-plan.md](disaster-recovery-plan.md#1-the-distinction-that-changes-everything) |
| Recovery order is counterintuitive: **Harbor and the hosts before Jenkins.** Users are affected by services being down, not by the inability to build | [disaster-recovery-plan.md](disaster-recovery-plan.md#3-recovery-ordering) |
| Backing up the Jenkins credential store **without its master key** produces a file that restores successfully and whose every credential is unusable. Backing up both makes the backup a complete set of production credentials. There is no configuration that avoids this trade-off | [backup-standard.md](backup-standard.md#4-jenkins-credentials-need-care) |
| A restore into the running system is **not a test** — it succeeds for reasons that will not exist during a real recovery. Tests must restore into a genuinely clean, network-isolated target | [restore-testing.md](restore-testing.md#4-test-into-a-clean-target) |
| A restored Jenkins holding production credentials, if reachable, will run its scheduled jobs against production. A safety exercise becomes an incident | [restore-testing.md](restore-testing.md#4-test-into-a-clean-target) |
| Harbor image storage is **reproducible-but-different**: a rebuild yields a different artifact, which cannot serve as a rollback target for a byte-identical known-good version | [backup-standard.md](backup-standard.md#2-reproducible-versus-irreplaceable) |

## The Cheapest Risk Reduction Available

Risk R-30 — untested backups — is ranked first in the [risk register](../00-executive/risk-register.md#9-highest-priority) by residual severity against cost to reduce.

The first restore test is roughly a day of work: back up one component, restore it into an isolated target following only the written procedure, use a restored credential, record the duration, and correct the procedure. See [restore-testing.md](restore-testing.md#9-getting-started).

That single exercise produces the largest reduction in residual risk available anywhere in this blueprint for the effort, and it does not require the platform to be complete.

---

## Open Items

- `TBD` — RPO
- `TBD` — RTO
- `TBD` — backup frequency per component
- `TBD` — retention period
- `TBD` — restore-test frequency
- `TBD` — backup storage location and its own protection
- `TBD` — whether Harbor image storage is backed up or reproducible from source

---

## Related

- [Documentation index](../README.md)
- [Infrastructure](../02-infrastructure/)
- [Operations](../09-operations/)
- [Governance](../10-governance/)
