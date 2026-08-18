# Runbook — Production Deployment

> **This runbook has never been executed.** Written from design, not experience. Correct it from the first real execution.

## When to Use

Deploying a release to production. This is a **normal change** under [change-management.md](../10-governance/change-management.md).

Not for: emergency changes (see the emergency path), or manual intervention (see [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md)).

## Roles

| Role | Responsibility |
| --- | --- |
| Release approver (`TBD`) | Approves; **not the change author** |
| Platform engineer or operator | Executes |
| Service owner | Available during the window |

---

## Preconditions

Do not start until every box is ticked.

- [ ] Release notes complete, including **breaking changes, migrations, and configuration changes**
- [ ] **Rollback availability stated** in the release notes — yes, or no with the reason
- [ ] UAT verification complete
- [ ] Quality Gate and security gates passed
- [ ] The image to deploy is the **same image UAT verified** — verify the digest
- [ ] Approval recorded: approver role, version, timestamp, change reference
- [ ] Any new configuration value **already set** in the production environment file
- [ ] Previous known-good version identified, **and confirmed still present in Harbor**

Two of these are the ones that go wrong.

**Configuration values.** A release requiring a new value deploys successfully and then fails at run time, in production, on the values nobody set. Set them before, not during.

**The retained predecessor.** If retention evicted it, rollback is unavailable — and that is discovered during the failure rather than before it.

---

## Steps

### 1. Verify the artifact

```text
1. Confirm the image digest matches what UAT verified
2. Confirm the tag has not been repointed
3. Confirm the commit matches the Git tag
```

If the digests differ, **stop**. Something was rebuilt, and UAT verification no longer describes what is about to be deployed.

### 2. Record the rollback target

```text
1. Record the currently deployed version and its digest
2. Confirm that image is present in Harbor
3. Record it where the deployment record will reference it
```

**Before deploying, not after.** Determining the target afterwards, from a system that may already be failing, is how rollbacks get stuck.

### 3. Announce

- [ ] Service owner and on-call informed
- [ ] Deployment window started

### 4. Deploy

```text
MECHANISM: TBD — adr/0009
```

| Option | Execution |
| --- | --- |
| A — Jenkins agent on host | Pipeline job step on the target agent |
| B — SSH over internal network | Remote command from the controller |
| C — Pull-based agent | Update the desired state; **wait for convergence** |
| D — Portainer API | API call. Not recommended |

Whichever applies: the **published image** is deployed. Nothing is rebuilt.

Under option C, deployment is asynchronous — "the pipeline finished" and "the host converged" are different moments, and step 5 must wait for the second.

### 5. Health verification

- [ ] **Readiness** endpoint healthy within the timeout
- [ ] For a worker: the liveness file has been touched **since the deployment started**, and the backlog is not growing

Readiness, not liveness. And for a worker, container-running is not verification — a worker that starts, fails to connect to its queue, and retries silently is running and processing nothing.

**If health verification fails: go to [rollback-runbook.md](rollback-runbook.md).** Do not investigate first; restore service, then investigate.

### 6. Smoke test

- [ ] Core functional path exercised end to end

**If the smoke test fails: go to [rollback-runbook.md](rollback-runbook.md).** Healthy and not working is still not working.

### 7. Observe

Watch for the agreed observation window — `TBD`.

| Signal | Compare against |
| --- | --- |
| Error rate | Pre-deployment level |
| Latency percentiles | Pre-deployment level |
| Restart count | Zero |
| New error classes in logs | None expected |

The deployment marker on the dashboard makes this comparison a single glance.

`TBD` — the window. Some failures appear immediately; others appear under load, at a scheduled job, or at the next hourly batch. A deployment marked successful at two minutes has been verified against a narrow slice of its behaviour.

### 8. Close

- [ ] Deployment record complete: version, digest, commit, approver, timestamps, previous version, outcome
- [ ] Change record closed with the outcome
- [ ] Service owner and on-call informed
- [ ] Any correction to this runbook committed

---

## If Something Goes Wrong

| Situation | Action |
| --- | --- |
| Health check fails | [rollback-runbook.md](rollback-runbook.md) |
| Smoke test fails | [rollback-runbook.md](rollback-runbook.md) |
| Problem found during the observation window | Rollback, or forward fix — a decision, recorded |
| Problem found after the window | A new change |
| **Release contained an irreversible migration** | Rollback is unavailable. Forward recovery. This was known at approval |
| Harbor unreachable mid-deployment | Some hosts may have deployed and others not. Establish actual state before acting |
| Deployment state unknown | **Do not re-run.** Determine what is actually running first |

The last two share a principle: re-running a deployment whose state is unknown can make a partial failure worse. Establish the runtime state, then decide.

---

## What Not to Do

| Do not | Because |
| --- | --- |
| Rebuild the image for production | It is no longer the artifact UAT verified |
| Deploy `latest` | No deterministic answer to what is running |
| Skip health verification to save time | The deployment then has an unknown outcome, recorded as success |
| Fix forward by editing files on the host | A manual change, reverted at the next deployment, returning days later |
| Deploy without an approval record | The audit trail stops describing reality |

---

## Open Items

| Item |
| --- |
| `TBD` — **deployment mechanism** ([ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)) |
| `TBD` — production approver role |
| `TBD` — health verification timeout per application type |
| `TBD` — smoke test definition per application type |
| `TBD` — observation window |
| `TBD` — deployment record location |

---

## Related

- [Rollback runbook](rollback-runbook.md)
- [CD standard](../05-ci-cd/cd-standard.md)
- [Change management](../10-governance/change-management.md)
- [Audit evidence](../10-governance/audit-evidence.md)
