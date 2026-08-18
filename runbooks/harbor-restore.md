# Runbook — Harbor Restore

> **This runbook has never been executed.** Its first execution is itself a restore test — see [restore-test.md](../sop/restore-test.md).

## When to Use

Harbor is unavailable, corrupt, or has lost data. **This is the platform's most consequential failure: deployment and rollback both stop**, because both pull from Harbor.

## Preconditions

- [ ] Access to backup storage, recorded
- [ ] For a test: an isolated target
- [ ] For a real recovery: **deployments frozen**, and platform owner informed

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Platform owner (`TBD`) | Informed; authorizes a restore that loses data |

---

## 1. Assess First

Before restoring, establish urgency.

| Question | If yes |
| --- | --- |
| Is any production service currently degraded? | **Urgent.** Rollback is unavailable while Harbor is down |
| Is a release in flight? | Freeze it; determine its state |
| Is this metadata loss, storage loss, or both? | Determines scope — see section 3 |
| Can images still be pulled? | If yes, production can still restart; recovery is less urgent |

The first question changes everything. A Harbor outage during normal operation is a delivery outage. A Harbor outage while a service is failing means the recovery path is gone at the moment it is needed.

---

## 2. Two Components, Restored Together

| Component | Contains | If lost |
| --- | --- | --- |
| **Database** | Projects, users, robot accounts, tags, retention rules, scan results | Configuration and metadata gone; layers may exist but be unreferenced |
| **Storage backend** | Image layers | Every artifact gone, including every rollback target |

**They must be restored to a consistent point in time.** A database restored to a different point than storage produces references to layers that do not exist, or layers with no references — and Harbor will start, appear healthy, and fail on specific pulls.

---

## 3. Restore

### 3.1 Prepare

- [ ] Same Harbor version as the backup
- [ ] Storage capacity available for the full restore
- [ ] TLS certificate available
- [ ] **Network-isolated**, if this is a test

### 3.2 Restore

```text
1. Stop Harbor
2. Restore the database from the backup
3. Restore the storage backend from the SAME point in time
4. Confirm the two backups' timestamps correspond
5. Start Harbor
6. Watch the startup log
```

Step 4 is the one to be deliberate about. If the two backups are not from the same point, decide explicitly which inconsistency is acceptable and record it — an older database with newer storage leaves unreferenced layers, which is recoverable; a newer database with older storage leaves broken references, which is not.

### 3.3 Verify — functionally

The web interface loading is not verification.

- [ ] Projects are present
- [ ] Robot accounts are present
- [ ] **A pull succeeds**
- [ ] **A push succeeds with the Jenkins credential**
- [ ] **A push FAILS with a runtime host credential** — pull-only is intact
- [ ] Tag immutability still rejects an overwrite
- [ ] Retention rules are present and were not reset to defaults
- [ ] **The previous known-good image for each production service is present**

The last is the one that determines whether rollback capability came back. A restore that recovers the registry but not the specific images production depends on has restored the service and not the capability.

### 3.4 Record

| Field | Value |
| --- | --- |
| Backup used, and its age | |
| Duration | |
| **Images lost, if any** | |
| Outcome | |
| Corrections to this runbook | |

---

## 4. If Image Storage Is Unrecoverable

The situation to have thought about in advance.

Images are reproducible from source **in principle** — but a rebuild produces a *different* artifact, which **cannot serve as a rollback target for a byte-identical known-good version**. Reproducibility is not a substitute for retention.

```text
1. Establish what is currently DEPLOYED in each environment.
   Those images are running; the containers hold them locally
2. Preserve them before anything restarts:
     docker save <image> -o <file>
   A container restart pulls from a registry that no longer has the image
3. Rebuild what is needed from source, accepting the new identity
4. Record which deployment records now reference images that no longer exist
5. Treat step 4 as an audit gap, and record it as such
```

**Step 2 is time-critical and easy to miss.** The running containers may hold the only remaining copy. A host reboot or a container restart after storage loss removes it.

---

## 5. Emergency: Restore Is Not Fast Enough

A production service is failing, rollback is needed, and Harbor is not back.

```text
1. Check whether the previous image is present on the runtime host:
     docker image ls
   If it is, redeploy from the local copy — Compose will not pull
   an image that is already present locally
2. If not, and another host has it, transfer it:
     docker save | ssh ... | docker load
3. If neither, rollback is unavailable. Forward fix or accept the outage
```

Step 1 is why a **host-local image cache** is the cheapest meaningful mitigation available for this SPOF — see [high-availability-roadmap.md](../docs/02-infrastructure/high-availability-roadmap.md). It is not currently designed, which means step 1 succeeds by luck rather than by design.

---

## 6. Failure

| Situation | Action |
| --- | --- |
| Database restores, storage does not | Metadata without artifacts. See section 4 |
| Storage restores, database does not | Layers with no references. Harbor cannot serve them; a rebuild of metadata is `TBD` |
| Both restore, pulls fail | Point-in-time mismatch. Check step 4 of 3.2 |
| Robot accounts missing | Recreate per [new-project-provisioning.md](../sop/new-project-provisioning.md), then **rotate**: the previous credentials' status is unknown |
| Retention rules reset to defaults | **Check immediately** before any garbage collection runs, or rollback targets may be evicted |

The last two are easy to miss because Harbor works without them. The second of them can destroy rollback capability shortly after a successful-looking recovery.

---

## 7. Open Items

| Item |
| --- |
| `TBD` — backup method producing a consistent database and storage pair |
| `TBD` — whether image storage is backed up in full, or the rebuild risk is accepted |
| `TBD` — RTO, which should be the tightest of the platform components |
| `TBD` — host-local image cache, which would decouple rollback from this |
| `TBD` — procedure for rebuilding metadata from storage, if it is possible at all |

---

## Related

- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Harbor storage management](harbor-storage-management.md)
- [Restore test](../sop/restore-test.md)
- [Disaster recovery plan](../docs/11-disaster-recovery/disaster-recovery-plan.md)
- [High availability roadmap](../docs/02-infrastructure/high-availability-roadmap.md)
