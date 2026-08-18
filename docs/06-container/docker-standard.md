# Docker Standard

## Purpose

Defines the runtime contract every container must satisfy, regardless of application type or the environment it runs in.

## Scope

Container behaviour at run time. Build-time requirements are in [dockerfile-standard.md](dockerfile-standard.md); composition and deployment configuration is in [docker-compose-standard.md](docker-compose-standard.md).

## Audience

Developers building containerized applications, and platform engineers reviewing them.

## Status

**Draft for review.** Requirements below are stated as requirements, but none have been enforced by tooling yet.

## Assumptions

- Containers run on Linux hosts under Docker Engine with Docker Compose.
- Applications are Angular frontends, .NET Web APIs, or .NET Worker Services.

---

## 1. The Container Contract

Every container the organization runs must satisfy the following. Each row is a requirement.

| # | Requirement | Reason |
| --- | --- | --- |
| C1 | One concern per container | A container is the unit of deployment, restart, and scaling. Two concerns in one container cannot be operated independently |
| C2 | Runs as a non-root user where technically practical | Container escape from a root process is a host compromise |
| C3 | Reads configuration from the environment at start | Required by build-once promotion — see [environment-architecture.md](../01-architecture/environment-architecture.md) |
| C4 | Contains no credentials, keys, or connection strings | An image is a distributable artifact; anything inside it is readable by anyone who can pull it |
| C5 | Writes logs to stdout and stderr, not to files inside the container | Container filesystems are ephemeral; log files inside them disappear with the container |
| C6 | Terminates cleanly on `SIGTERM` | An unclean stop is how deployments cause data-integrity incidents |
| C7 | Exposes a health signal where technically appropriate | Deployment verification and rollback both depend on knowing whether the container actually works |
| C8 | Declares explicit resource limits in production | An unbounded container can take down every other container on the host |
| C9 | Fails fast and loudly when required configuration is missing | Starting with a wrong default is worse than not starting |
| C10 | Stores no durable state inside the container filesystem | Anything not in a volume is lost on every deployment |

C9 is the one most often violated by accident. A service that falls back to a built-in default when its configuration is absent will start successfully in the wrong configuration — and the failure surfaces later, as incorrect behaviour rather than a failed deployment.

---

## 2. Process and Signal Handling

The container's main process must receive and handle `SIGTERM`.

### The PID 1 problem

The process started by `ENTRYPOINT`/`CMD` runs as PID 1. Two consequences follow.

If the entrypoint is a shell in *shell form*, the shell becomes PID 1 and typically does not forward signals to the application. Docker then waits for the stop timeout and sends `SIGKILL`. The application never learns it is being stopped.

```dockerfile
# Wrong: shell becomes PID 1, SIGTERM is not forwarded
ENTRYPOINT dotnet MyApi.dll

# Correct: the application is PID 1 and receives SIGTERM
ENTRYPOINT ["dotnet", "MyApi.dll"]
```

PID 1 also does not reap orphaned child processes. Applications that spawn child processes need an init process (`docker run --init`, or `init: true` in Compose).

### Shutdown sequence

On `SIGTERM` a container must, in order:

1. stop accepting new work — stop taking requests, stop consuming from the queue
2. finish or safely abandon in-flight work
3. flush anything buffered, including logs and telemetry
4. release connections and resources
5. exit

This must complete within the stop timeout, or the runtime sends `SIGKILL` and steps 2 to 4 do not happen.

### Timeout ordering

The stop timeout must be longer than the application's own shutdown timeout. If they are equal or inverted, the application is killed while it believes it still has time to finish.

```text
application shutdown timeout  <  container stop timeout
```

`TBD` — the standard stop timeout per application type. Workers processing long-running items need more than an API serving short requests.

---

## 3. Logging

| Requirement | Detail |
| --- | --- |
| Destination | stdout and stderr only |
| Format | Structured where practical, so logs are queryable rather than only greppable |
| Environment awareness | Every log line identifiable by service and environment |
| Correlation | Include a correlation identifier where a request crosses services |
| Content | No credentials, tokens, keys, connection strings, or unnecessary personal data |
| Volume | Proportional to usefulness — see the note below |

Log content deserves more caution than it usually gets. Logs are shipped centrally, retained for months, and readable by more people than the systems that produced them. A token logged once at debug level is then present in centralized storage for the whole retention period, and deleting the source container does not remove it.

Log volume is an operational cost, not just a storage one. Verbose logging in production fills disks, and a full disk on a runtime host takes down every container on it. Rotation is configured at the Compose level — see [docker-compose-standard.md](docker-compose-standard.md).

Field requirements and label conventions are defined in [08-observability/](../08-observability/).

---

## 4. Health Signals

| Signal | Question | Failure means |
| --- | --- | --- |
| Liveness | Is the process healthy enough to keep running? | Restart the container |
| Readiness | Can it accept traffic right now? | Stop routing traffic; do **not** restart |
| Dependency health | Are downstream dependencies reachable? | Diagnostic signal only |

The distinction is operationally important. If liveness includes a database check, a slow database causes every container to fail its liveness probe and restart — repeatedly, adding connection churn to an already struggling dependency, and fixing nothing. Liveness answers a question about *this process*.

Health responses must not expose connection strings, internal hostnames, component versions, or stack traces. A health endpoint is frequently the least protected route in a service.

### When a health check is not appropriate

A worker service with no HTTP surface should not gain an HTTP server purely to answer a health check. Adding a network listener to a process that otherwise has none introduces attack surface to satisfy a convention.

Alternatives for non-HTTP services, to be decided in [08-observability/](../08-observability/):

- a heartbeat metric consumed by monitoring
- a liveness file touched on each successful processing cycle, checked by a command-based health check
- process liveness alone, with correctness inferred from throughput metrics

`TBD` — the chosen approach for .NET Worker Services.

---

## 5. Resource Limits

Production containers must declare CPU and memory limits.

Without a memory limit, a container with a leak consumes host memory until the kernel OOM killer intervenes — and the process it kills is not necessarily the one at fault. The failure appears in an unrelated service, which makes diagnosis considerably harder.

A limit converts an unbounded, host-wide failure into a bounded, attributable one: the offending container is killed and restarted, and its restart count is visible in monitoring.

.NET applications need particular care. A runtime unaware of its container limit may size its heap against total host memory and be killed at a threshold it never anticipated. Configure the runtime to respect the container limit.

`TBD` — default limits per application type, and whether limits are enforced in UAT as well as PROD.

---

## 6. Filesystem

| Rule | Reason |
| --- | --- |
| Durable state goes in a named volume | Container filesystems are discarded on every deployment |
| Prefer a read-only root filesystem where the application allows it | Removes a large class of runtime tampering |
| Use `tmpfs` for scratch space | Keeps temporary data out of the image layer and off disk |
| Do not write logs to files | See section 3 |

A read-only root filesystem is achievable for most .NET APIs and for static-content frontends. Where it is not, the reason should be recorded rather than the setting silently omitted.

---

## 7. Time and Locale

Containers run in UTC. Log timestamps are UTC with an explicit offset.

Local-time containers produce logs that cannot be correlated across services during an incident, and the ambiguity is worst exactly when clarity matters most — around daylight-saving transitions.

Display-time localization is an application concern, not a container one.

---

## 8. Never Inside an Image

- credentials, tokens, API keys, private keys, certificates with private material
- connection strings for any environment
- `.git` directories and repository history
- build tooling, compilers, and package managers in the runtime stage
- shells and debugging utilities beyond what operations genuinely requires
- production or personal data
- `.env` files

Image layers are additive. Deleting a file in a later layer does not remove it from the image — the content remains retrievable from the earlier layer. A secret committed to a layer is in the image permanently, regardless of what subsequent instructions do.

---

## 9. Verification

Checks that can be run against a built image:

| Check | Command or method |
| --- | --- |
| Runs as non-root | `docker inspect --format '{{.Config.User}}' <image>` — must not be empty or `root` |
| Handles SIGTERM | Start the container, `docker stop`, confirm it exits before the timeout rather than at it |
| No secrets in layers | Scan with Trivy secret detection; inspect the image history |
| Logs to stdout | `docker logs` shows output |
| Health endpoint behaves | Query it while a dependency is deliberately unavailable |
| Resource limits applied | `docker inspect` shows the configured limits |

`TBD` — which of these run automatically in the pipeline, and which block promotion.

---

## 10. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — stop timeout per application type | Deployment safety for workers |
| `TBD` — default resource limits per application type | Production stability |
| `TBD` — liveness approach for .NET Worker Services | Observability, deployment verification |
| `TBD` — whether resource limits are required in UAT | Environment parity |
| `TBD` — which contract items are automatically verified in the pipeline | Whether this standard is enforced or advisory |

---

## Security Considerations

C2 and C4 carry most of the security weight here. Non-root execution limits what a compromised process can do to its host; the absence of embedded credentials limits what an attacker gains from obtaining the image itself.

The layer-additivity point in section 8 is the one that surprises people. A `Dockerfile` that copies a configuration file, uses it, and deletes it still ships that file inside the image.

Health endpoints deserve deliberate design. They are commonly unauthenticated and frequently return more detail than intended.

## Operational Considerations

C5, C6, and C8 determine whether the platform is operable. Logs on stdout make them collectable; clean shutdown makes deployments safe; resource limits make failures attributable.

C10 determines whether a deployment is a routine action or a data-loss risk. If durable state lives inside a container filesystem, every deployment destroys it — and that fact is usually discovered during, not before, a release.

---

## Related

- [Dockerfile standard](dockerfile-standard.md)
- [Docker Compose standard](docker-compose-standard.md)
- [Image versioning](image-versioning.md)
- [Environment architecture](../01-architecture/environment-architecture.md)
- [Observability standards](../08-observability/)
- [Security standards](../07-security/)
