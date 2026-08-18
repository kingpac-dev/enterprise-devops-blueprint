# Rollback Strategy

## Purpose

Defines how a failed release is recovered, what rollback depends on, and — most importantly — when rollback is **not available**.

## Scope

Recovery from a failed or bad deployment. The deployment flow is in [cd-standard.md](cd-standard.md); the operator procedure is in [09-operations/](../09-operations/).

## Audience

Developers, platform engineers, release approvers, and operators.

## Status

**Draft for review.** **No rollback has ever been executed.** Rollback capability is therefore unproven.

---

## 1. Rollback Is Designed Before the First Production Deployment

Not designed during an incident. The design decisions — what the target is, how it is recorded, what triggers it, when it is unsafe — are made in advance because none of them can be made well under pressure.

**Rollback designed but never executed is an assumption.** Executing one deliberately in UAT costs about an hour and is the difference between having a recovery path and believing you have one.

---

## 2. The Sequence

```text
1. Record the current known-good version        <- BEFORE deploying
2. Deploy the requested immutable image
3. Execute health checks
4. Execute smoke tests where applicable
5. On failure: restore the previous version, WHERE TECHNICALLY SAFE
6. Verify recovery
7. Record failure evidence
8. Notify responsible engineers
```

Step 1 is first for a reason. Determining the rollback target afterwards, from a system that may already be failing, is how rollbacks get stuck.

Step 5's qualifier does real work. See section 5.

---

## 3. What Rollback Depends On

Four things, each of which can be absent without anyone noticing until a rollback is attempted.

| Dependency | Fails when | Detection |
| --- | --- | --- |
| **The previous version is recorded** | Deployment did not record it | The record is checked at deploy time — see [pipeline-stage-standard.md](pipeline-stage-standard.md) |
| **The previous image still exists in Harbor** | Retention evicted it | A periodic check that each production service's predecessor is present |
| **Harbor is reachable** | Registry outage | Availability monitoring |
| **The change is reversible** | Migrations, external side effects | Recorded in the release notes before approval |

The second and third are the ones that produce a rollback that appeared configured and correct until the moment it was needed.

**The third is structural.** Both deployment and rollback pull from Harbor, so the recovery path shares a dependency with the failure path. A bad release coinciding with a Harbor outage has no clean way back. A host-local image cache would decouple them and is the cheapest available mitigation — it is not currently designed. See [high-availability-roadmap.md](../02-infrastructure/high-availability-roadmap.md).

---

## 4. Retention Bounds Rollback Depth

**Retention is a reliability control, not housekeeping.**

If the previous known-good image has been evicted, the rollback fails at the moment it is needed. The failure is silent until then: the policy looks configured, the pipeline looks correct, and the image is gone.

| Requirement |
| --- |
| Retention derived from **required rollback depth**, not from storage cost |
| Any image currently deployed is exempt from every retention rule |
| The previous known-good image per production service is exempt |
| Retention rules **dry-run and reviewed** before enabling |
| A periodic check that each production service's predecessor is still present |

"Previous known-good" is not necessarily the immediately preceding tag. If three releases failed verification in sequence, the last good image may be several versions back. `TBD` — the retained depth **N** per service; a minimum of 5 is a reasonable starting point.

See [image-retention-policy.md](../06-container/image-retention-policy.md).

---

## 5. When Rollback Is Not Available

This is the section that matters most, because the failure it describes is discovered at the worst possible moment.

### Database migrations

Redeploying the previous image does **not** undo a schema change. The old code runs against the new schema and fails.

| Migration type | Rollback |
| --- | --- |
| Additive — new nullable column, new table | Usually safe. Old code ignores what it does not know |
| Expand phase of expand/contract | Safe by design |
| Contract phase — dropping a column the old code reads | **Not reversible** |
| Type change, rename, constraint tightening | **Not reversible** |
| Data transformation | Reversible only if the original is retained |

**Expand/contract** is what keeps rollback available across each step:

```text
Release N     Add the new column. Write to both. Old code unaffected
Release N+1   Read from the new column. Old code still works
Release N+2   Stop writing the old column
Release N+3   Drop the old column   <- only now is the old code broken
```

More releases and more coordination, in exchange for a rollback path at every individual step.

### Irreversible external effects

A rollback restores the code. It does not un-send an email, un-charge a payment, un-publish a message, or un-call a third-party API.

Where a release introduces such effects, its rollback is partial, and that must be stated.

### The requirement

**Every release states its rollback availability in the release notes, before approval.**

| | |
| --- | --- |
| Rollback available | Yes / **No, because `<reason>`** |
| Previous known-good version | |
| Image still retained | |
| Limitations | |

**Never promise automatic rollback for an irreversible change.** Where rollback is unavailable, the recovery plan is forward fix, and the approver must know that when approving rather than when it fails.

---

## 6. Triggers

| Trigger | Automatic | Notes |
| --- | --- | --- |
| Health check fails | Yes | Where technically safe |
| Smoke test fails | Yes | Where technically safe |
| Error rate spike after deployment | `TBD` | Requires an observation window and a threshold |
| Manual decision | No | Operator judgement; a change under change control |
| Failure found after the observation window | No | A new change: rollback or forward fix |

`TBD` — the post-deployment observation window. Some failures appear immediately; others appear under load, at a scheduled job, or at the next hourly batch. A deployment marked successful at two minutes has been verified against a narrow slice of its behaviour.

---

## 7. Rollback Is a Change

A rollback is a production change and produces a change record: what was rolled back, from and to which versions, why, who decided, and the outcome.

A release that failed and was rolled back is **not** a release that did not happen. It consumed a version number, it appears in the deployment history, and the reason it failed is the useful part.

---

## 8. Verifying Recovery

Rollback completing is not recovery.

- [ ] Health check passes on the restored version
- [ ] Smoke test passes
- [ ] Error rate returned to its pre-deployment level
- [ ] Latency returned to its pre-deployment level
- [ ] No new error class in the logs
- [ ] The deployment record reflects the current state

The third and fourth need the pre-deployment values, which is why deployment markers on dashboards matter — see [dashboard-standard.md](../08-observability/dashboard-standard.md#9-deployment-annotations).

---

## 9. Practising It

`TBD` — frequency. At minimum: **once in UAT before the first production deployment of any service.**

```text
1. Deploy version N to UAT
2. Deploy version N+1
3. Deliberately trigger a rollback
4. TIME it
5. Verify recovery per section 8
6. Record the duration and every point where the procedure was wrong
```

Step 4 is the only real input to a recovery-time estimate. Step 6 is the deliverable — a procedure that has never been executed is an untested assumption, which is the same standard this repository applies to backups.

---

## 10. Blocked: Execution Depends on the Mechanism

The **policy** above is independent of how the pipeline reaches runtime hosts. The **execution** is not.

| Option | Rollback executes as |
| --- | --- |
| A — Jenkins agent on host | A job step on the target agent; synchronous |
| B — SSH over internal network | A remote command; synchronous |
| **C — Pull-based agent** | Revert the **desired state**; the host converges. **Asynchronous** — verification must wait for convergence, and automatic rollback needs a feedback path |
| D — Portainer API | An API call; synchronous. Not recommended |

Under option C, "rollback completed" and "rollback took effect" are different moments. See [cd-standard.md](cd-standard.md#8-blocked-the-deployment-mechanism) and [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md).

---

## 11. Open Items

| Item |
| --- |
| `TBD` — deployment mechanism, which determines execution |
| `TBD` — retained depth **N** per service |
| `TBD` — post-deployment observation window |
| `TBD` — whether error-rate spike triggers automatic rollback |
| `TBD` — rollback exercise frequency |
| `TBD` — automated check that each production service's predecessor is retained |
| `TBD` — host-local image cache, to decouple rollback from Harbor |
| `TBD` — migration tooling and ownership |

---

## Security Considerations

Rollback interacts with vulnerability policy in a way that must be decided in advance. If Harbor pull-blocking on severity is enabled, it will block redeploying a previously good image that has since acquired a finding — **at the moment the rollback is needed**. If pull-blocking is adopted, a documented, authorized, audited, time-limited emergency path must exist. See [vulnerability-management.md](../07-security/vulnerability-management.md#6-deployment-time-policy).

Rolling back to an older image reintroduces whatever vulnerabilities it contained. That is usually the right trade during an outage, and it is a trade rather than a free action.

## Operational Considerations

The three things that make rollback work — recording the previous version before deploying, retaining it, and having verified the procedure once — are all cheap and all easy to omit. None has a visible benefit until the day all three matter simultaneously.

Section 5 is the one to read before designing a release with migrations. The rollback path is removed by the migration, not by the deployment, and the moment to discover that is at design time.

---

## Related

- [CD standard](cd-standard.md)
- [Environment promotion](environment-promotion.md)
- [Image retention policy](../06-container/image-retention-policy.md)
- [Release and tagging standard](../04-source-control/release-and-tagging-standard.md)
- [Disaster recovery plan](../11-disaster-recovery/disaster-recovery-plan.md)
- [Operations runbooks](../09-operations/)
