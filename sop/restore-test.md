# SOP — Restore Test

## Trigger and Frequency

| Trigger | Level |
| --- | --- |
| Scheduled | `TBD` — L2/L3 per component on a rotation; L4 at least annually |
| After a platform component upgrade | L3 for that component |
| After a change to backup configuration or scope | L3 |
| After a change to the recovery procedure | L3 |
| After adding a component to the backup scope | L2 minimum |

Backups fail silently after upgrades more often than at any other time: a new version changes a data format, a path, or a configuration location, and the backup keeps succeeding against the old assumption.

## Roles

| Role | Responsibility |
| --- | --- |
| Restore test owner (`TBD`) | Schedules, performs, evidences |
| Platform owner (`TBD`) | Accountable for recovery capability |

The tester should not always be the person who designed the backup. Someone else exercising the procedure finds the assumptions the designer did not know they were making — which is most of what the procedure needs to survive being used by whoever is on call.

## Why This SOP Exists

**Until a restore has been demonstrated, recovery capability is unproven.** A backup system reporting success for two years proves that a job ran 730 times. It proves nothing about whether the data is complete, consistent, readable, or sufficient.

This is risk R-30, ranked first in the [risk register](../docs/00-executive/risk-register.md#9-highest-priority) by severity against cost to reduce.

---

## Preconditions

- [ ] A backup exists for the component under test
- [ ] An **isolated** target is available — see step 2
- [ ] The written recovery procedure is available
- [ ] The tester has access to backup storage, recorded
- [ ] A maintenance window is not required — this must not touch production

---

## Steps

### 1. Select scope

| Level | What | Confirms |
| --- | --- | --- |
| L1 | Open the backup; verify integrity | The file is not corrupt |
| L2 | Restore one component to an isolated target; verify it starts | That component is recoverable |
| L3 | Restore, then **use** it | It works, not merely starts |
| L4 | Rebuild the platform from backups into clean infrastructure, timed | Recovery capability, and the real RTO |

**L3 is the minimum that means anything.** A restored Jenkins that starts but whose credentials fail is a restored Jenkins that cannot build.

### 2. Provision an isolated target

**A restore into the running system is not a test.** It succeeds for reasons that will not exist during a real recovery: configuration already exists, dependencies are installed, credentials are in place, network routes work.

Requirements:

- [ ] No pre-existing configuration for this component
- [ ] **Network-isolated from production**
- [ ] Reachable only through the documented procedure

Network isolation is a safety control, not tidiness. **A restored Jenkins that can reach production will run its scheduled jobs — against production.** A safety exercise then becomes an incident.

### 3. Record the starting state

| Field | Value |
| --- | --- |
| Date, tester | |
| Component, level | |
| Backup used, and its age | |
| Procedure version followed | |
| **Start time** | |

### 4. Restore, following the written procedure only

Do not improvise. Do not use knowledge that is not in the procedure. **Every point where you had to know something the procedure does not say is a defect in the procedure** — note it rather than working around it.

- [ ] Restore executed
- [ ] Every deviation, gap, or error in the procedure noted

### 5. Verify functionally (L3 and above)

Not "does it start". Does it work.

| Component | Functional verification |
| --- | --- |
| Jenkins | A job runs; **a restored credential is used successfully** |
| Harbor | An image pulls; a previous known-good tag is present |
| SonarQube | An analysis submits; the gate evaluates |
| Prometheus | Targets scrape; a rule evaluates |
| Grafana | A dashboard loads against its data source |
| Application volume | The application starts and reads its data |

The Jenkins row catches the failure only this test finds. The credential store is encrypted with a master key held separately: **backed up without the key, the restore succeeds and every credential is unusable.** Nothing else detects this.

### 6. Record the ending state

| Field | Value |
| --- | --- |
| **End time, and duration** | |
| **Data loss observed** | |
| Outcome: success / partial / failed | |
| Problems found | |

Duration and data loss are the only real inputs to RTO and RPO. An RTO of four hours next to a restore that has never been timed is a number, not a target.

### 7. Correct the procedure

- [ ] Every gap from step 4 corrected in the written procedure
- [ ] Corrections committed through a pull request

**This is the test's main deliverable.** A test that finds problems has done its job.

### 8. Repeat with a different person

- [ ] A second person follows the corrected procedure without help

This is what turns one successful restore into a repeatable capability. A procedure that works for its author is not yet a procedure.

### 9. Destroy the target

- [ ] Isolated target destroyed
- [ ] Any restored credential treated as exposed to the tester and rotated if warranted

---

## Verification

The test itself is the verification, so what is checked here is that the test was a real one.

- [ ] The target had **no** pre-existing configuration for this component
- [ ] The target was **network-isolated** from production
- [ ] Only the written procedure was followed — no improvisation, no unwritten knowledge
- [ ] Functional verification performed, not merely "it started" (L3 and above)
- [ ] A restored **credential** was actually used (Jenkins)
- [ ] Duration measured, not estimated
- [ ] Procedure corrections committed
- [ ] The target was destroyed afterwards

Any unchecked box means the result overstates the recovery capability it demonstrated.

---

## Evidence

`TBD` — where records are held, and their retention.

Each test records: date, tester, component, level, backup age, procedure version, **duration**, **data loss**, outcome, problems found, corrections made.

**A test that finds nothing found nothing this time.** A run of clean results usually means the test is not hard enough — most often because it restores into somewhere too similar to the original.

---

## Failure

| Situation | Action |
| --- | --- |
| Restore fails | This is the finding. Record it; fix the backup or the procedure; retest |
| Restore succeeds, verification fails | Same. The backup is not sufficient |
| Duration far exceeds the assumed RTO | Record the measured duration; revise the RTO to the measured value or improve the process |
| Backup cannot be read at all | **Escalate immediately.** The platform is currently unrecoverable |

`TBD` — whether a failed test blocks anything.

---

## Getting Started

The first test does not need the full programme. Roughly a day of work, and it moves R-30 from Critical toward manageable:

```text
1. Back up one component — Jenkins is a good first choice
2. Provision an isolated, network-restricted target
3. Restore following the written procedure only
4. Note every point where the procedure was wrong or incomplete
5. Verify functionally: run a job; use a restored credential
6. Record the duration
7. Correct the procedure
8. Repeat, with a different person
```

This is the largest reduction in residual risk available anywhere in the blueprint for that effort, and **it does not require the platform to be complete**.

---

## Open Items

| Item |
| --- |
| `TBD` — test frequency per level |
| `TBD` — isolated test environment and how it is provisioned |
| `TBD` — restore test owner |
| `TBD` — where results are recorded and for how long |
| `TBD` — RPO and RTO, to be set from measured results rather than assumed |

---

## Related

- [Restore testing](../docs/11-disaster-recovery/restore-testing.md)
- [Backup standard](../docs/11-disaster-recovery/backup-standard.md)
- [Disaster recovery plan](../docs/11-disaster-recovery/disaster-recovery-plan.md)
- [Risk register](../docs/00-executive/risk-register.md)
