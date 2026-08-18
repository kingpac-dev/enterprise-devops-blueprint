# Runbook — Rollback

> **This runbook has never been executed.** Execute it deliberately in UAT before relying on it in production — see [rollback-strategy.md](../05-ci-cd/rollback-strategy.md#9-practising-it).

## When to Use

| Situation | |
| --- | --- |
| Health verification failed after deployment | Automatic, where safe |
| Smoke test failed | Automatic, where safe |
| A problem found during the observation window | Decision |
| A problem found later | A new change; may be rollback or forward fix |

## Roles

| Role | Responsibility |
| --- | --- |
| Operator or platform engineer | Executes |
| Service owner | Consulted on whether rollback is the right action |
| Emergency approver (`TBD`) | For a rollback outside a change window |

---

## Step 0 — Is Rollback Available?

**Ask this first. Thirty seconds here prevents a failed rollback attempt during an outage.**

| Check | If no |
| --- | --- |
| Is the previous known-good version recorded? | Determine what was running from the deployment record. If unavailable, see section 5 |
| Is that image still present in Harbor? | Retention may have evicted it. See section 5 |
| Is Harbor reachable? | See section 5 |
| **Did this release include a migration the previous version cannot run against?** | **Rollback is unavailable.** Forward recovery. This was recorded in the release notes before approval |
| Did this release cause irreversible external effects — payments, emails, published messages? | Rollback is **partial**. Restoring the code does not undo them |

The migration question is the one that matters most. Redeploying the previous image leaves old code against a new schema, which fails — often in a way that looks like a new problem rather than a failed recovery.

---

## Steps

### 1. Decide and announce

- [ ] Decision recorded: rolling back, from version, to version, why
- [ ] Service owner and on-call informed
- [ ] For production outside a window: emergency approver informed

### 2. Execute

```text
MECHANISM: TBD — adr/0009
```

| Option | Execution |
| --- | --- |
| A — Jenkins agent on host | Job step deploying the previous image |
| B — SSH over internal network | Remote command |
| **C — Pull-based agent** | Revert the **desired state**; the host converges. **Asynchronous** — "reverted" and "took effect" are different moments |
| D — Portainer API | API call |

Deploy the **previous image by its recorded identifier**. Do not rebuild it, and do not deploy "the previous tag" without confirming it still resolves to the same digest.

### 3. Verify recovery

Rollback completing is not recovery.

- [ ] Health check passes on the restored version
- [ ] Smoke test passes
- [ ] **Error rate returned to its pre-deployment level**
- [ ] **Latency returned to its pre-deployment level**
- [ ] No new error class in the logs
- [ ] The deployment record reflects the current state

The third and fourth need the pre-deployment values. Deployment markers on the dashboard make that comparison immediate.

If recovery does not verify, the problem was not the release. Treat it as an incident — see [incident-response-runbook.md](incident-response-runbook.md).

### 4. Record

| Field |
| --- |
| From version and digest, to version and digest |
| Why |
| Who decided |
| Start and end time, **duration** |
| Recovery verified: yes or no |
| **Failure evidence** — what the failed release did |

Duration is the only real input to a recovery-time estimate.

A release that failed and was rolled back **is not a release that did not happen**. It consumed a version, it appears in the deployment history, and the reason it failed is the useful part.

### 5. Follow up

- [ ] The defect that caused the rollback is ticketed
- [ ] The next release does not reintroduce it
- [ ] Any correction to this runbook committed

---

## When the Target Is Unavailable

The situations step 0 is checking for.

### The image was evicted by retention

```text
1. Check whether the image is still present locally on the runtime host:
     docker image ls
   Compose will not pull an image that is already present locally
2. If another host has it: docker save | transfer | docker load
3. If neither: rollback is unavailable. Forward fix
4. Afterwards: fix the retention policy. This is a control failure
```

Step 4 is not optional. Retention that evicts rollback targets will do it again.

### Harbor is unreachable

Same sequence — the local image is the only remaining option. This is why the recovery path sharing a dependency with the failure path matters, and why a **host-local image cache** is the cheapest mitigation available. It is not currently designed, which means step 1 succeeds by luck rather than by design.

See [harbor-restore.md](../../runbooks/harbor-restore.md#5-emergency-restore-is-not-fast-enough).

### The change is not reversible

Rollback is unavailable. Options, in order of preference:

```text
1. Forward fix: a new release correcting the defect
2. Feature-flag the affected behaviour off, if one exists
3. Restore from backup — LAST RESORT, and it loses data written since
```

Option 3 is a data-loss decision requiring the authority named in [disaster-recovery-plan.md](../11-disaster-recovery/disaster-recovery-plan.md#5-decision-authority) — `TBD`.

---

## Practising It

`TBD` — frequency. **At minimum: once in UAT before the first production deployment of any service.**

```text
1. Deploy version N to UAT
2. Deploy version N+1
3. Trigger a rollback deliberately
4. TIME it
5. Verify recovery per step 3
6. Record the duration and every point where this runbook was wrong
```

Rollback designed but never executed is an assumption. An hour in UAT is the difference between having a recovery path and believing you have one.

---

## Open Items

| Item |
| --- |
| `TBD` — **deployment mechanism** ([ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)) |
| `TBD` — retained image depth per service |
| `TBD` — host-local image cache |
| `TBD` — who authorizes a restore that loses data |
| `TBD` — rollback exercise frequency |
| `TBD` — automated check that each production service's predecessor is retained |

---

## Related

- [Rollback strategy](../05-ci-cd/rollback-strategy.md)
- [Production deployment runbook](production-deployment-runbook.md)
- [Incident response runbook](incident-response-runbook.md)
- [Image retention policy](../06-container/image-retention-policy.md)
