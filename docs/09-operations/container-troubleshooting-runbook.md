# Runbook — Container Troubleshooting

> **This runbook has never been used.** Commands are written against Docker and Compose v2; verify against the installed versions.

## When to Use

A container is not running, not healthy, or not behaving. Reached from [incident-response-runbook.md](incident-response-runbook.md) or from an alert.

## Access Required

Diagnosis to the end of section 4 needs **tier 0–1** — dashboards and logs. Tier 2 and above are needed only from section 5.

**Start at the lowest tier that answers the question.** If the answer is not available at tier 0 or 1, that is usually a gap in observability rather than a reason to escalate access — record it as such.

See [production-access-policy.md](../10-governance/production-access-policy.md).

---

## 1. Establish the Symptom

| Symptom | Go to |
| --- | --- |
| Container not running at all | 2 |
| Restarting repeatedly | 3 |
| Running but unhealthy | 4 |
| Running and healthy but wrong | 5 |
| Every container on the host affected | **6 — check the host first** |

**Check symptom 6 first if more than one service is affected.** A host-level problem presents as several unrelated services failing simultaneously, and diagnosing them individually wastes the first several minutes.

---

## 2. Not Running

```bash
docker compose ps                     # what state is it in?
docker compose logs --tail=200 <svc>  # why did it stop?
```

| Exit code | Usually means |
| --- | --- |
| 0 | Exited cleanly — a worker that finished, or a misconfigured long-running service |
| 1 | Application error. The logs will say |
| **137** | **SIGKILL — almost always the memory limit.** See section 6 |
| 139 | Segmentation fault |
| 143 | SIGTERM — a clean stop was requested |

**137 is the one to recognize.** The application typically logs nothing, because it was terminated without warning. The record is on the **host**, not in the container:

```bash
dmesg | grep -i -E 'oom|killed process'
```

Common causes of not starting at all:

| Cause | Check |
| --- | --- |
| Missing required configuration | The logs; the value should be named. This is fail-fast working |
| Image not present and cannot be pulled | Harbor reachable? Credential valid? |
| Port already in use | `docker compose ps` on the host |
| Volume permission denied | The container runs non-root; the volume must be writable by that uid |

---

## 3. Restarting Repeatedly

A crash loop. **It looks running on a coarse dashboard while serving almost nothing** — which is why restart count is a required metric.

```bash
docker compose ps                       # restart count
docker compose logs --tail=500 <svc>    # the same failure, repeated
```

| Pattern | Cause |
| --- | --- |
| Fails immediately, same error each time | Configuration or a missing dependency at startup |
| Runs briefly, then exit 137 | Memory limit; see section 6 |
| Healthy, then fails the health check | See section 4 — the health check may be wrong |
| Fails only after a deployment | **Roll back.** [rollback-runbook.md](rollback-runbook.md) |

### The health-check restart storm

If a **liveness** check queries a dependency, a slow dependency fails every instance's liveness probe — so every container restarts, repeatedly, adding connection churn to a dependency already under strain, and fixing nothing.

If restarts began when a dependency slowed rather than when anything was deployed, **suspect the health check itself.** Liveness answers a question about *this process only*.

---

## 4. Running but Unhealthy

```bash
docker inspect --format '{{json .State.Health}}' <container>
```

| Check | Meaning |
| --- | --- |
| Liveness fails | The process is stuck. Restart is appropriate |
| Readiness fails | It cannot serve traffic — usually a dependency. **Restarting will not help** |
| Health check times out | The check may be too expensive, or the service is saturated |

Distinguishing these matters. Restarting a container whose *readiness* fails because a database is unavailable achieves nothing and adds churn.

For a **worker**, there is no readiness endpoint. Check instead:

- Is the liveness file being touched? If not, processing has stopped even though the process runs
- Is the backlog growing?
- Time since last successful cycle

A worker that starts, fails to connect to its queue, and retries silently is running and processing nothing.

---

## 5. Running and Healthy but Wrong

The container works and the behaviour is wrong. **Tier 2 access** — and note that container inspection displays environment variables, which is where application secrets live.

```bash
docker inspect --format '{{json .Config.Env}}' <container>   # tier 2
docker inspect --format '{{index .RepoDigests 0}}' <container>
docker inspect --format '{{json .Config.Labels}}' <container>
```

| Question | Check |
| --- | --- |
| Is this the version you think? | Digest, and the OCI labels |
| Is the configuration what you think? | Environment; compare against the intended values |
| **Did someone change something by hand?** | Change records — and ask |
| Is it talking to the right environment? | Endpoint configuration. A wrong default points somewhere real |

The manual-change question is worth asking out loud. A manual change is reverted at the next deployment and returns days later in an unrelated release, with nothing connecting the two.

The last row is the failure mode that unsafe defaults produce: a service that started successfully against the wrong environment.

---

## 6. Every Container on the Host

Check the host before the services.

```bash
df -h                    # disk — check /var/lib/docker specifically
free -m                  # memory
docker system df         # what is consuming Docker's disk
systemctl status docker  # is the daemon healthy?
dmesg | tail -50         # OOM kills, filesystem errors
```

| Cause | Symptom |
| --- | --- |
| **Disk full** | Everything fails in varied, confusing ways. Containers cannot write; the daemon may be unable to operate |
| Memory pressure | Containers killed with 137, not necessarily the one at fault |
| Docker daemon unhealthy | Nothing responds to `docker` commands |
| Host down | Nothing at all |

### Disk full is the most common and the most confusing

A full disk on a runtime host stops **every** container, and the symptoms differ per service, so it presents as several unrelated failures.

Usual causes:

```bash
docker system df                    # images, containers, volumes, build cache
du -sh /var/lib/docker/containers/* # unrotated container logs
```

| Cause | Fix | Prevention |
| --- | --- | --- |
| Unrotated container logs | Truncate the offending log | **Log rotation limits** in Compose and in the daemon |
| Accumulated images | `docker image prune` | Scheduled pruning |
| Build cache on an agent | `docker builder prune` | Workspace cleanup |

**Do not `docker system prune -a` on a runtime host.** It removes images not currently in use — including **the previous known-good image**, which is the rollback target. That is a one-command destruction of rollback capability, executed while trying to fix an outage.

---

## 7. Restarting Safely

```bash
docker compose restart <service>       # preserves the container
docker compose up -d --force-recreate <service>   # recreates it
```

Before restarting:

- [ ] Will in-flight work be lost? A worker mid-transaction can leave partial writes or unacknowledged messages
- [ ] Is the stop grace period long enough for a clean shutdown?
- [ ] Is this a **manual change**? In production, yes — record it

Prefer `restart` over `up -d --force-recreate` unless the container's configuration has changed. Recreating pulls the image, and if the registry is unreachable the container will not come back.

---

## 8. Escalate

| Situation | Escalate |
| --- | --- |
| The symptom began at a deployment | [rollback-runbook.md](rollback-runbook.md) |
| A platform component is involved | [runbooks/](../../runbooks/) |
| Host-level, not container-level | Platform owner |
| Data may be affected | **Immediately.** Do not experiment |
| The answer needs tier 3–4 access | Request it; record the reason |

---

## 9. Open Items

| Item |
| --- |
| `TBD` — which access tier developers hold for their own services |
| `TBD` — stop grace period per application type |
| `TBD` — scheduled image pruning on runtime hosts |
| `TBD` — worker liveness file path convention, confirmed |

---

## Related

- [Incident response runbook](incident-response-runbook.md)
- [Rollback runbook](rollback-runbook.md)
- [Docker standard](../06-container/docker-standard.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
- [Production access policy](../10-governance/production-access-policy.md)
