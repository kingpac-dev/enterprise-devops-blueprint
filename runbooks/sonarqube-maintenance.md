# Runbook — SonarQube Maintenance

> **This runbook has never been executed.** Verify against the installed SonarQube version and database before relying on it.

## When to Use

| Situation | Section |
| --- | --- |
| Scheduled database maintenance | 2 |
| Backup | 3 |
| Upgrade | 4 |
| SonarQube unavailable and delivery is blocked | 5 |
| Restore | 6 |

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Change approver (`TBD`) | Approves the window |

---

## 1. What Is at Stake

SonarQube unavailable **stops delivery**, because the Quality Gate fails closed and an unevaluated gate is not a pass.

It does **not** affect production. Running services are unaffected; only the ability to publish new artifacts is lost.

That distinction sets the urgency, and it also sets the temptation: within hours of an outage, someone will propose making the gate advisory. Section 5 exists for that moment.

---

## 2. Database Maintenance

The database is where SonarQube's growth lives: analyses, issues, and history.

```text
1. Check database size and growth rate
2. Check analysis history depth against the configured retention
3. Run the housekeeping the version provides
4. Confirm the maintenance window if the operation locks tables
```

`TBD` — schedule, and the specific commands for the installed database.

Growth drivers: number of projects × analyses per project × history retention. A project analysed on every commit accumulates history quickly, and history is the part that is cheap to shorten and easy to forget to configure.

---

## 3. Backup

| Item | Class |
| --- | --- |
| Database | **Irreplaceable in practice** — historical trend cannot be reconstructed |
| Configuration: quality gates, profiles, permissions | Irreplaceable unless captured as code |
| Analysis reports | Regenerable by re-analysing |

```text
1. Take a consistent database backup — a live file copy of a running
   database usually produces a copy that will not open
2. Capture the SonarQube configuration directory
3. Write to backup storage, encrypted, off this host
4. Verify the backup is readable
```

**Verify:**

- [ ] The database dump restores into a scratch database
- [ ] **Backup job failure alerts**

`TBD` — schedule, retention, and the consistent-backup method for the chosen database.

---

## 4. Upgrade

An upgrade is a **normal change**. SonarQube upgrades commonly include a database migration, which is what makes the backup a precondition rather than a precaution.

```text
1. Take a backup; verify it is readable
2. Record current versions: SonarQube, plugins, database
3. Read the upgrade notes — check for required intermediate versions.
   Some upgrades cannot be performed in a single step
4. Stop SonarQube
5. Upgrade
6. Start; run the database migration when prompted
7. Watch the log until the migration completes
```

**Verify:**

- [ ] Web interface loads
- [ ] Projects and history are present
- [ ] Quality gates and profiles are unchanged
- [ ] **An analysis submits and the gate evaluates**
- [ ] A pipeline reaches and passes the Quality Gate step
- [ ] **The backup still succeeds afterwards**

Step 3 catches the failure that turns a window into an outage: attempting a multi-version jump that the migration does not support leaves a database part-migrated, and the recovery is a restore.

---

## 5. SonarQube Unavailable — Delivery Blocked

The gate fails closed. Builds fail. Releases wait.

```text
1. Restore service — that is the fix
2. Do NOT disable the gate or make it advisory
```

An unavailable gate has not been evaluated. Treating it as a pass converts a tool outage into a silent bypass of a mandatory control — and a configuration change made quietly under pressure is rarely reversed once the pressure ends.

If a prolonged outage genuinely requires proceeding:

```text
1. Request an EXCEPTION: recorded, scoped to specific releases,
   with an approver and an EXPIRY
2. Record what was released without gate evaluation
3. Re-analyse those releases once service returns
4. Close the exception
```

`TBD` — whether this exception path is pre-authorized. Pre-authorizing it means the decision is made calmly in advance rather than argued during an outage.

---

## 6. Restore

```text
1. Prepare a target with the same SonarQube version as the backup
2. Restore the database
3. Restore the configuration directory
4. Start; watch the log
```

**Verify — functionally:**

- [ ] Projects and history present
- [ ] Quality gates and profiles present
- [ ] **An analysis submits and the gate evaluates**
- [ ] The analysis token still works, or is reissued

The last matters. If tokens were not part of the restore, pipelines will fail at the analysis step with an authentication error that looks like a network problem.

---

## 7. Open Items

| Item |
| --- |
| `TBD` — database type, and its consistent-backup method |
| `TBD` — backup schedule and retention |
| `TBD` — analysis history retention |
| `TBD` — upgrade cadence, and whether intermediate versions are required |
| `TBD` — whether the outage exception path is pre-authorized |
| `TBD` — whether quality gates and profiles are captured as code |

The last would move the configuration from irreplaceable to reproducible, leaving only history in the irreplaceable class.

---

## Related

- [ADR-0003 — SonarQube](../adr/0003-use-sonarqube-for-code-quality.md)
- [Quality gate baseline](../templates/sonar/quality-gate-baseline.md)
- [Backup standard](../docs/11-disaster-recovery/backup-standard.md)
- [Exception management](../docs/10-governance/exception-management.md)
- [Scheduled maintenance](../sop/scheduled-maintenance.md)
