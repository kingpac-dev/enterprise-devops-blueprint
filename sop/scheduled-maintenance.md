# SOP — Scheduled Maintenance

## Trigger and Frequency

| Activity | Frequency |
| --- | --- |
| Harbor garbage collection | `TBD` — regular; see below |
| Platform component upgrades | `TBD` |
| Host OS patching | `TBD` |
| Certificate renewal | Before expiry; see the runbook |
| SonarQube database maintenance | `TBD` |

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Plans and executes |
| Change approver (`TBD`) | Approves as a normal change |
| Affected service owners | Notified |

---

## Steps

### 1. Plan

- [ ] What, why, and expected duration
- [ ] What becomes unavailable, and for whom
- [ ] Rollback or abort path
- [ ] Verification plan
- [ ] Window chosen — **not during a release window**

The unavailability question needs a precise answer. Harbor unavailable stops deployment **and rollback**; Jenkins unavailable stops delivery but not production. That distinction determines who needs to know and how urgent an overrun is.

### 2. Approve and announce

- [ ] Approved as a normal change under [change-management.md](../docs/10-governance/change-management.md)
- [ ] Affected teams notified with `TBD` notice
- [ ] Deployment freeze communicated where applicable

### 3. Prepare

- [ ] **Backup taken and verified** for anything with state
- [ ] Current versions recorded, so "what changed" is answerable afterwards
- [ ] Abort criteria agreed before starting

The backup is not optional for an upgrade. Backups fail silently after upgrades more often than at any other time — a new version changes a data format, a path, or a configuration location, and the backup keeps succeeding against the old assumption. Take one **before**, and schedule a [restore test](restore-test.md) **after**.

### 4. Execute

- [ ] Executed in the agreed window
- [ ] Deviations recorded as they happen, not reconstructed afterwards

### 5. Verify

- [ ] Component functional, not merely running
- [ ] Dependent components still work — a Harbor upgrade is verified by a *pull*, not by the UI loading
- [ ] Monitoring shows normal signals

### 6. Close

- [ ] Teams notified
- [ ] Change record completed with outcome
- [ ] **Post-upgrade restore test scheduled**

---

## Harbor Garbage Collection

Called out because deferring it is how registries reach full disks.

| Property | Consequence |
| --- | --- |
| Harbor may become **read-only** during collection | Publication blocked; potentially pulls too. It is a maintenance window, not a background task |
| Duration scales with registry size | The first run after a long gap is the longest and most disruptive |
| Deleting a tag reclaims nothing | Only garbage collection removes unreferenced layers |
| Shared layers are reclaimed only when nothing references them | Space recovered is routinely far less than the size of what was deleted |

```text
1. Confirm no release is in flight
2. Announce the window
3. Verify retention rules have been dry-run and reviewed
4. Run garbage collection
5. Verify: a push succeeds, a pull succeeds
6. Verify: the previous known-good image for each production service
   is STILL PRESENT
7. Record space reclaimed
```

**Step 6 is the one to never skip.** A garbage collection that removed a rollback target leaves a service with no recovery path, and nothing reports it — the failure surfaces at the next rollback attempt.

`TBD` — schedule, and how it is coordinated with release windows.

---

## Host Patching

- [ ] One host at a time
- [ ] For a runtime host: the services on it are unavailable unless moved first, and there is no automatic rescheduling
- [ ] Docker daemon restart restarts every container on the host
- [ ] Verify containers return healthy after reboot, including their restart policy behaviour

`TBD` — patching cadence, and whether production hosts require a service migration first. Under Docker Compose there is no mechanism to move them, so the honest answer is likely a short outage per host.

---

## Verification

- [ ] Component works functionally
- [ ] Dependents work
- [ ] Monitoring normal
- [ ] Backup still succeeds **after** the change
- [ ] Restore test scheduled

The fourth is easy to omit and is precisely where post-upgrade backup failures hide.

---

## Failure

| Situation | Action |
| --- | --- |
| Overruns the window | Assess against the abort criteria agreed in step 3. Decide; do not drift |
| Component does not come back | Execute the recovery runbook. This is now an incident |
| Dependents broken though the component is up | Do not close the window. Diagnose |
| Backup fails after the change | **Treat as urgent.** Recovery capability is currently absent |

---

## Open Items

| Item |
| --- |
| `TBD` — maintenance window policy and notice period |
| `TBD` — Harbor garbage collection schedule |
| `TBD` — host patching cadence |
| `TBD` — platform upgrade cadence |
| `TBD` — whether a deployment freeze is automatic during a window |

---

## Related

- [Change management](../docs/10-governance/change-management.md)
- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Image retention policy](../docs/06-container/image-retention-policy.md)
- [Restore test](restore-test.md)
- [Runbooks](../runbooks/)
