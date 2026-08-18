# Restore Testing

## Purpose

Defines how restores are tested, how often, what counts as a successful test, and how results are evidenced.

## Scope

Verification that backups can actually rebuild the platform. What is captured is in [backup-standard.md](backup-standard.md); recovery procedures are in [disaster-recovery-plan.md](disaster-recovery-plan.md).

## Audience

Platform engineers and whoever is accountable for recovery capability.

## Status

**Draft for review.** No restore has ever been performed. This is risk R-01 in the register's priority ranking.

---

## 1. Why This Document Exists Separately

Backup and restore are treated as one activity and behave as two. Backups are automated, monitored, and reported. Restores are manual, rare, and performed under pressure by someone who has not done it before.

The gap between them is where recovery capability actually lives, and it is invisible from the backup side. A backup system reporting success for two years proves that a job ran 730 times. It proves nothing about whether the data is complete, consistent, readable, or sufficient.

**Until a restore has been demonstrated, recovery capability is unproven** — and it must be described that way in every status report, risk assessment, and audit response.

---

## 2. Failures Only a Restore Finds

Each of these passes every backup-side check.

| Failure | Why backup monitoring misses it |
| --- | --- |
| Jenkins credential store restored without its master key | The file was written; every credential is unusable |
| Database backup taken from live files | The job succeeded; the copy will not open |
| Harbor database and image storage from different points in time | Both jobs succeeded; references point at layers that do not exist |
| A component silently dropped from scope | Nothing reports the absence of a job nobody configured |
| Backup encrypted with a key nobody has | The backup is intact and unreadable |
| Restore procedure references systems or paths that no longer exist | Documentation is not exercised |
| Restore takes far longer than the RTO assumes | Duration is never measured until it matters |
| Restore requires a credential stored only in the system being restored | Circular dependency, discovered at the worst moment |

The last is the one that turns a recoverable situation into an unrecoverable one, and it is only ever found by attempting a restore into a genuinely clean environment.

---

## 3. Levels of Test

Effort and confidence both increase down this list. Different levels suit different cadences.

| Level | What is done | Confirms | Effort |
| --- | --- | --- | --- |
| **L1 — Readable** | Open the backup; verify integrity | The file is not corrupt | Low |
| **L2 — Component** | Restore one component to an isolated target; verify it starts | That component is recoverable | Medium |
| **L3 — Functional** | Restore, then **use** it — run a build, pull an image, use a restored credential | It works, not merely starts | Medium to High |
| **L4 — Full recovery** | Rebuild the platform from backups into clean infrastructure, timed | Recovery capability, and the real RTO | High |

L3 is the minimum that means anything. A restored Jenkins that starts but whose credentials fail is a restored Jenkins that cannot build. A restored Harbor that starts but cannot serve a pull cannot support a rollback.

L4 is the only level that validates the RTO, because it is the only one that measures the whole sequence including the parts nobody thought about.

`TBD` — required frequency per level.

---

## 4. Test Into a Clean Target

**A restore into the running system is not a restore test.**

Restoring over a working system succeeds for reasons that will not be present during a real recovery: configuration already exists, dependencies are already installed, credentials are already in place, network routes already work. The test confirms that a file can be copied onto a system that already worked.

Tests must restore into a target that has none of that.

| Requirement | Reason |
| --- | --- |
| Isolated from production | A test must not be able to damage what it is protecting |
| No pre-existing configuration | Otherwise the test leans on what is already there |
| Reached only through the documented procedure | Exercises the procedure, not the tester's memory |
| Network-isolated where possible | Prevents a restored system from acting on production |

The last matters more than it appears. A restored Jenkins with production credentials, reachable from the network, will attempt to run scheduled jobs — against production. A restore test that deploys to production is a serious incident caused by a safety exercise.

`TBD` — the isolated test environment, and how it is provisioned.

---

## 5. What Each Test Records

| Field | Why |
| --- | --- |
| Date, and who performed it | Evidence |
| Component and level | Scope of what was proven |
| Backup used, and its age | Whether an old backup still restores |
| Procedure followed, and its version | Which documented steps were exercised |
| **Duration** | The only real input to RTO |
| Outcome: success, partial, or failed | |
| Problems found | The purpose of the test |
| Procedure corrections made | The test's main deliverable |
| Data loss observed | The only real input to RPO |

Duration and data loss are what make RPO and RTO evidence-based rather than aspirational. An RTO of four hours next to a restore that has never been timed is a number, not a target.

**A test that finds nothing found nothing this time.** A test that finds problems has done its job. The instinct to record a clean result is worth resisting: the value is in the corrections, and a run of clean results usually means the test is not hard enough — most often because it is restoring into somewhere too similar to the original.

---

## 6. Frequency

`TBD` — the schedule. The framework for deciding:

| Level | Suggested trigger |
| --- | --- |
| L1 | Automated, frequently |
| L2 | Per component, on a rotation |
| L3 | Per critical component, periodically |
| L4 | Annually at minimum, and after any significant platform change |

Also test after:

- a platform component upgrade
- a change to the backup configuration or scope
- a change to the recovery procedure
- adding a component to the backup scope

Backups fail silently after upgrades more often than at any other time — a new version changes a data format, a path, or a configuration location, and the backup keeps succeeding against the old assumption.

---

## 7. Roles

| Role | Responsibility |
| --- | --- |
| Backup owner | Backups run; failures alert |
| Restore test owner | Tests are scheduled, performed, and evidenced |
| Platform owner | Accountable for recovery capability overall |

`TBD` — assignment.

The tester should not always be the person who designed the backup. Someone else exercising the procedure finds the assumptions the designer did not know they were making — which is most of what the procedure needs to survive being used by whoever is on call.

---

## 8. Current State

| Item | State |
| --- | --- |
| Backups taken | **No** |
| L1 performed | No |
| L2 performed | No |
| L3 performed | No |
| L4 performed | No |
| RTO measured | **No** |
| RPO measured | **No** |

**Recovery capability is unproven.** Any recovery time or data loss figure quoted before a test is an estimate with no evidence behind it, and should be labelled as such wherever it appears.

---

## 9. Getting Started

The first test does not require the full programme. Recommended first step, once backups exist:

```text
1. Take a backup of one component — Jenkins is a good first choice
2. Provision an isolated, network-restricted target
3. Restore following the written procedure only, without improvising
4. Note every point where the procedure was wrong or incomplete
5. Verify functionally: run a job; use a restored credential
6. Record the duration
7. Correct the procedure
8. Repeat, with a different person following the corrected procedure
```

Step 8 is what turns one successful restore into a repeatable capability. A procedure that works for its author is not yet a procedure.

Steps 1 to 7 are a day of work and move risk R-30 from Critical toward manageable — the largest reduction in residual risk available anywhere in this blueprint for that effort.

---

## 10. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — test frequency per level | Whether testing happens |
| `TBD` — isolated test environment and its provisioning | Whether tests are meaningful |
| `TBD` — restore test owner | Accountability |
| `TBD` — where results are recorded and retained | Evidence |
| `TBD` — whether a failed test blocks anything | Consequence |
| `TBD` — RPO and RTO, to be set from measured results | Evidence-based targets |

---

## Security Considerations

A restored system holds real credentials. The test environment must be isolated and access-restricted like production, and restored credentials should be treated as exposed to whoever performed the test.

Network isolation is a safety control, not tidiness. A restored Jenkins that can reach production will act on it — running scheduled jobs, triggering deployments — and the resulting incident is caused by an exercise intended to reduce risk.

Restore test records describe exactly where recovery is weak. That is useful to an attacker and should be access-controlled accordingly.

## Operational Considerations

Restore testing is the highest-value, lowest-cost risk reduction available in this blueprint, and it is also the easiest to defer indefinitely. It has recurring cost, no immediate benefit, and no consequence for skipping — until the day it has all of them at once.

The single most useful practice is section 4: test into a genuinely clean target. Everything else is subordinate to it, because a restore into a system that already works confirms almost nothing.

---

## Related

- [Backup standard](backup-standard.md)
- [Disaster recovery plan](disaster-recovery-plan.md)
- [Risk register](../00-executive/risk-register.md)
- [Standard operating procedures](../../sop/)
- [Runbooks](../../runbooks/)
