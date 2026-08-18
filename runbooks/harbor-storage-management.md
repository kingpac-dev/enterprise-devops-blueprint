# Runbook — Harbor Storage Management

> **This runbook has never been executed.** Verify each command against the installed Harbor version before relying on it.

## When to Use

| Situation | Section |
| --- | --- |
| Storage alert fired | 2 |
| Scheduled garbage collection | 4 |
| Storage exhausted — publication failing | 5 |
| Reviewing retention | 3 |

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Change approver (`TBD`) | Approves the maintenance window for garbage collection |

---

## 1. Why This Needs a Runbook

Registry storage grows continuously and does not shrink on its own. Exhaustion stops publication and, depending on configuration, pulls — which blocks deployment **and rollback**.

It is a platform-wide outage originating in a disk that filled slowly and predictably, which makes it entirely preventable and commonly not prevented: garbage collection needs a maintenance window, and a task needing a window gets deferred until the day it cannot be.

---

## 2. Storage Alert

```text
1. Check current usage and the growth rate over the last 30 days
2. Estimate time to exhaustion at the current rate
3. If more than the window needed for garbage collection: schedule it
   If less: treat as urgent — see section 5
4. Check whether growth is normal or anomalous
```

Anomalous growth usually has one of these causes:

| Cause | Check |
| --- | --- |
| Retention rules not running | Last execution time |
| Retention rules matching nothing | Dry-run output |
| Garbage collection never run | Last run time |
| A new project with no retention | Project list against configured rules |
| Feature branches publishing images | Whether that was intended — it is `TBD` in the versioning standard |

---

## 3. Retention Review

**Retention determines how far back a rollback can reach.** It is a reliability control, not housekeeping — see [image-retention-policy.md](../docs/06-container/image-retention-policy.md).

```text
1. List retention rules per project
2. DRY RUN each rule and read the output
3. Confirm the output does NOT include:
     - any image currently deployed in any environment
     - the previous known-good image for any production service
     - any image required for the audit retention period
4. Adjust rules if it does
5. Enable only after the dry run is clean
```

**Step 2 is not optional.** A rule expressed as "keep the most recent 10" does not know which image is currently deployed. The alternative to a dry run is discovering the mistake as a failed rollback.

---

## 4. Garbage Collection

### 4.1 Understand what it does

| Property | Consequence |
| --- | --- |
| Deleting a tag reclaims **nothing** | Only garbage collection removes unreferenced layers |
| Harbor may become **read-only** during collection | Publication blocked, potentially pulls too. A maintenance window, not a background task |
| Duration scales with registry size | The first run after a long gap is the longest and most disruptive |
| Shared layers are reclaimed only when nothing references them | Space recovered is routinely far less than the size of what was deleted |

### 4.2 Execute

```text
1. Confirm no release is in flight
2. Confirm retention rules have been dry-run and reviewed (section 3)
3. Announce the window
4. Record current storage usage
5. Run garbage collection
6. Monitor progress
7. Record storage reclaimed and duration
```

### 4.3 Verify

- [ ] A push succeeds
- [ ] A pull succeeds
- [ ] **The previous known-good image for each production service is still present**
- [ ] Storage reclaimed recorded, for future forecasting

**The third is the one to never skip.** A garbage collection that removed a rollback target leaves a service with no recovery path, and nothing reports it. The failure surfaces at the next rollback attempt, during an incident.

---

## 5. Storage Exhausted

Publication is failing. Deployment is blocked; rollback may be.

```text
1. Establish whether PULLS still work
   If yes: production can still restart and roll back. Less urgent
   If no:  urgent — rollback capability is gone
2. Free space in the least destructive order:
     a. Run garbage collection if it has not run recently — this is
        usually the largest safe win
     b. Remove clearly disposable artifacts: feature-branch images,
        untagged artifacts past their grace period
     c. Extend storage if the platform allows it online
3. DO NOT relax retention rules to free space in an emergency.
   Retention bounds rollback depth; shortening it under pressure
   removes recovery capability at the moment it is most likely needed
4. Once recovered: revisit the forecast, not just the symptom
```

**Step 3 is the decision this runbook exists to pre-empt.** Under pressure, cutting retention is the fastest available action and it trades an availability problem for a recoverability one, silently.

---

## 6. Monitoring That Should Exist

| Metric | Threshold |
| --- | --- |
| Storage used, percentage | `TBD` — with enough lead time to run garbage collection |
| Storage growth rate | Alert on anomalous increase |
| Time since last garbage collection | `TBD` |
| Retention rule last execution | Alert if it stops running |

The second is the one that gives warning rather than notice. A sudden change in growth rate precedes exhaustion by long enough to act.

---

## 7. Open Items

| Item |
| --- |
| `TBD` — garbage collection schedule and window |
| `TBD` — storage alert thresholds |
| `TBD` — storage capacity and growth forecast |
| `TBD` — retention values, derived from required rollback depth |
| `TBD` — whether feature branches publish images at all |
| `TBD` — whether storage can be extended online |

---

## Related

- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Image retention policy](../docs/06-container/image-retention-policy.md)
- [Harbor restore](harbor-restore.md)
- [Scheduled maintenance](../sop/scheduled-maintenance.md)
- [Server sizing guideline](../docs/02-infrastructure/server-sizing-guideline.md)
