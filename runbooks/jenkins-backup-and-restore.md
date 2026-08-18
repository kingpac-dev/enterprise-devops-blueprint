# Runbook — Jenkins Backup and Restore

> **This runbook has never been executed.** It is written from design, not from experience. Its first execution is itself the first restore test, and the corrections that execution produces are the main deliverable — see [restore-test.md](../sop/restore-test.md).

## When to Use

| Situation | Section |
| --- | --- |
| Configuring backups for the first time | 2 |
| Restoring after controller loss | 4 |
| Restore test | 4, into an isolated target |
| Before a Jenkins upgrade | 3 |

## Preconditions

- [ ] Access to backup storage, recorded
- [ ] For a restore: an isolated, **network-isolated** target — see section 5
- [ ] Platform owner informed if this is a real recovery

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Platform owner (`TBD`) | Informed on a real recovery |

---

## 1. What Must Be Captured

| Item | Path (`TBD` — confirm against the installation) | Class |
| --- | --- | --- |
| Controller configuration | `$JENKINS_HOME/*.xml` | Irreplaceable |
| Job definitions | `$JENKINS_HOME/jobs/*/config.xml` | Reproducible if pipelines are in Git |
| **Credential store** | `$JENKINS_HOME/credentials.xml` | **Irreplaceable** |
| **Master key and secrets directory** | `$JENKINS_HOME/secrets/` | **Irreplaceable — see below** |
| Build history | `$JENKINS_HOME/jobs/*/builds/` | Audit evidence |
| Plugin list and versions | `$JENKINS_HOME/plugins/*.jpi` | Reproducible from a recorded list |
| Node configuration | `$JENKINS_HOME/nodes/` | Irreplaceable |

**Not** captured: `workspace/`, `caches/`, and build artifacts beyond retention. They are large and regenerable.

### The credential store and its key

`credentials.xml` is **encrypted with the master key in `secrets/`**.

- Backed up **without** `secrets/`: the restore succeeds and **every credential is unusable**. Nothing reports this — it is discovered when a job first tries to use one.
- Backed up **with** `secrets/`: the backup is a complete set of credentials for every environment. Anyone who can read it can reach production.

There is no configuration that avoids this trade-off, only controls that manage it: encryption at rest, restricted and recorded access, and treating backup storage as a production-equivalent asset.

---

## 2. Backup

`TBD` — schedule and retention.

```text
1. Quiesce or accept a slightly inconsistent copy
   Jenkins writes continuously. TBD — whether the controller is stopped,
   or a filesystem snapshot is used. A live tar of $JENKINS_HOME can
   capture a partially written file
2. Capture $JENKINS_HOME, EXCLUDING workspace/ and caches/
3. Record the plugin list and versions separately, in plain text
4. Write to backup storage: encrypted, off this host
5. Verify the archive is readable
6. Record: what, when, size, duration
```

**Verify:**

- [ ] The archive lists `credentials.xml` **and** `secrets/`
- [ ] The archive opens
- [ ] The plugin list was captured
- [ ] **Backup job failure alerts** — a job that stopped running reports nothing

The last is a separate check from "the backup succeeded". A silently failed backup is worse than no backup, because it removes the awareness that would prompt a manual copy.

---

## 3. Before an Upgrade

```text
1. Take a backup per section 2
2. Verify it is readable
3. Record current Jenkins and plugin versions
4. Upgrade — see sop/scheduled-maintenance.md
5. Verify a job runs and a credential works
6. VERIFY THE BACKUP STILL SUCCEEDS afterwards
```

Step 6 is the one that gets skipped. Backups fail silently after upgrades more often than at any other time: a new version changes a path or a format, and the job keeps succeeding against the old assumption.

---

## 4. Restore

### 4.1 Prepare the target

- [ ] Same Jenkins major version as the backup
- [ ] **No pre-existing `$JENKINS_HOME`**
- [ ] **Network-isolated**, if this is a test — see section 5

### 4.2 Restore

```text
1. Stop Jenkins if running
2. Restore $JENKINS_HOME from the backup
3. Restore the plugin set from the recorded list, at the recorded versions
4. Set ownership and permissions on $JENKINS_HOME
5. Start Jenkins
6. Watch the startup log for plugin and configuration errors
```

Step 3 uses the recorded list rather than the backed-up `plugins/` directory. Restoring plugin binaries across versions is where a restore most often produces a controller that starts and misbehaves.

### 4.3 Verify — functionally

Starting is not verification.

- [ ] The web interface loads
- [ ] Jobs are present
- [ ] Agents connect
- [ ] **A job runs to completion**
- [ ] **A restored credential is used successfully** — see below
- [ ] Build history is present

**The credential check is the one that matters.** It is the only verification that detects a `secrets/` directory missing from the backup. Run a job that uses `harbor-push` or `sonarqube-token`; do not merely confirm the credential is listed in the UI. A credential whose master key is absent still appears in the list.

### 4.4 Record

| Field | Value |
| --- | --- |
| Backup used, and its age | |
| Start and end time, **duration** | |
| Data loss observed | |
| Outcome | |
| **Every point where this runbook was wrong or incomplete** | |

The last field is the deliverable. Correct this document and commit the correction.

---

## 5. Isolation — Not Optional for a Test

**A restored Jenkins holds real credentials for every environment. If it can reach production, it will act on it** — scheduled jobs fire, triggers run, and a safety exercise becomes an incident.

- [ ] Target has no network route to production, UAT, Harbor, or GitHub
- [ ] Verified before starting Jenkins, not after

Where full isolation is impractical, disable scheduled triggers **before** the first start rather than after.

---

## 6. Failure

| Situation | Action |
| --- | --- |
| Archive unreadable | **Escalate. The platform is currently unrecoverable.** Try an older backup; investigate the backup process |
| Starts, credentials fail | The master key was not captured. **Fix the backup scope immediately** — this is the failure this runbook exists to prevent |
| Starts, plugin errors | Restore the plugin set at the recorded versions; consult the startup log |
| Jobs missing | Confirm the `jobs/` directory was in scope |
| Duration far exceeds the assumed RTO | Record the measured duration; revise the RTO to what was measured |

---

## 7. Open Items

| Item |
| --- |
| `TBD` — `$JENKINS_HOME` path, confirmed at installation |
| `TBD` — backup schedule and retention |
| `TBD` — quiesce or snapshot |
| `TBD` — backup storage location and encryption |
| `TBD` — RTO, to be set from a measured restore |
| `TBD` — whether controller configuration as code replaces part of this |

The last would reduce this runbook's scope considerably: configuration as code moves the reproducible parts into Git and leaves credentials as the only irreplaceable item.

---

## Related

- [Restore test](../sop/restore-test.md)
- [Backup standard](../docs/11-disaster-recovery/backup-standard.md)
- [Disaster recovery plan](../docs/11-disaster-recovery/disaster-recovery-plan.md)
- [Scheduled maintenance](../sop/scheduled-maintenance.md)
