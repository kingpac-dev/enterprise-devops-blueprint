# Observability Standard

## Purpose

Defines what every service must expose so that the platform can tell whether it is working, and diagnose it when it is not.

## Scope

The observability contract for applications: health endpoints, signal types, service identity, and correlation. Collection and storage detail is in [monitoring-standard.md](monitoring-standard.md) and [logging-standard.md](logging-standard.md).

## Audience

Developers building services, and platform engineers operating them.

## Status

**Draft for review.** Nothing is implemented. Thresholds and retention periods are undecided.

---

## 1. What Observability Is For Here

Three questions drive every requirement in this area:

| Question | Asked when | Answered by |
| --- | --- | --- |
| Is the deployment working? | During a release | Health checks, then smoke tests |
| Is something wrong right now? | Continuously | Alerts on metrics |
| Why is it wrong? | During an incident | Logs, correlated with metrics |

The first question makes observability a prerequisite for the delivery model, not an addition to it. Deployment verification and automatic rollback both depend on a service being able to report whether it works — see the production release sequence in [service-interaction.md](../01-architecture/service-interaction.md#3-key-sequences). A service with no health signal cannot be safely deployed by a pipeline, because the pipeline has no way to distinguish success from failure.

---

## 2. The Service Contract

Every service must provide the following. Each row is a requirement.

| # | Requirement | Applies to |
| --- | --- | --- |
| O1 | A liveness signal | All |
| O2 | A readiness signal | Services that receive traffic |
| O3 | Metrics covering the required signals in section 4 | All |
| O4 | Structured logs on stdout, with service identity | All |
| O5 | A correlation identifier propagated across service boundaries | Services that call other services |
| O6 | No credentials or unnecessary personal data in any signal | All |
| O7 | Identity in every signal: service name, version, environment | All |

O7 is the one that determines whether the rest is usable. A metric or log line that does not identify which service, which version, and which environment produced it cannot be attributed during an incident, and an incident is when attribution matters.

The version label additionally makes a class of question answerable: whether the error rate rose at the same moment a new version was deployed.

---

## 3. Health Signals

### The three kinds, and why they are separate

| Signal | Question | On failure |
| --- | --- | --- |
| Liveness | Is this process healthy enough to keep running? | Restart the container |
| Readiness | Can it accept traffic right now? | Stop routing traffic; do **not** restart |
| Dependency health | Are downstream dependencies reachable? | Diagnostic only |

Conflating liveness with dependency health produces a specific and damaging failure. If liveness checks the database, a slow database fails every instance's liveness probe, so every container restarts — repeatedly, adding connection churn to a dependency already under strain, and resolving nothing. The outage is amplified by the mechanism intended to protect against it.

Liveness answers a question about *this process only*. If the process is running and not deadlocked, it is live, even when everything it depends on is broken.

### Endpoints

`TBD` — the standard paths. Proposal:

```text
/health/live     liveness  — process is running and not deadlocked
/health/ready    readiness — dependencies checked; can serve traffic
/health          summary   — human-oriented, restricted
```

Requirements:

- Cheap. A health endpoint polled every few seconds must not query the database on every call, or the check becomes load.
- Fast. It must return within the probe timeout even when the system is degraded.
- Unauthenticated liveness and readiness are acceptable **only** because they return no detail — see below.

### What health responses must not contain

Health endpoints are frequently the least protected route in a service and are commonly reachable from more places than intended.

They must not expose connection strings, internal hostnames or addresses, component or dependency versions, configuration values, or stack traces. Liveness and readiness return status and nothing else.

Any detailed health view is a separate, restricted endpoint. `TBD` — whether one exists and how it is protected.

### Services with no HTTP surface

A .NET Worker Service should not gain an HTTP listener purely to answer a health check. Adding a network listener to a process that otherwise has none introduces attack surface to satisfy a convention.

`TBD` — the chosen approach. Options, with the trade-off in each:

| Option | How | Trade-off |
| --- | --- | --- |
| Heartbeat metric | The worker updates a "last successful cycle" timestamp; monitoring alerts when it goes stale | No new surface; detects stalled work, not just a stopped process. Requires the metric path to work |
| Liveness file | The worker touches a file each cycle; a command-based container health check reads its age | No network surface; works with container health checks. Only local |
| Process liveness only | The container is live if the process runs | Simplest; does not detect a process that is running but stuck |

The heartbeat metric is recommended. It detects the failure that matters for a worker — processing has stopped — which process liveness alone does not, because a deadlocked worker is still a running process.

---

## 4. Required Signals

Every service exposes at least:

| Signal | Type | Why |
| --- | --- | --- |
| Request rate | Metric | Traffic; the denominator for error rate |
| Error rate | Metric | The primary symptom users experience |
| Latency distribution | Metric | Degradation before outage |
| CPU utilization | Metric | Saturation |
| Memory utilization | Metric | Saturation, and leak detection |
| Restart count | Metric | Crash loops that a coarse dashboard hides |
| Availability | Metric | Whether the service is up |

Workers replace request rate, error rate, and latency with:

| Signal | Why |
| --- | --- |
| Items processed per interval | Throughput |
| Processing failures | The error equivalent |
| Backlog depth or age | The leading indicator that a worker is falling behind |
| Time since last successful cycle | Detects a stalled worker |

Restart count deserves its place in both lists. A container in a restart loop can appear healthy in a coarse dashboard — it is running, after all — while serving almost nothing. Restart count is what makes that visible.

`TBD` — metric names and labels, in [monitoring-standard.md](monitoring-standard.md).

---

## 5. Correlation

A request that crosses services must carry an identifier that appears in every log line it produces.

Without it, diagnosing a cross-service failure means correlating by timestamp, which fails under any meaningful concurrency — the log lines from the failing request are indistinguishable from the hundreds of successful ones alongside them.

Requirements:

- Generated at the entry point if not already present
- Propagated on every outbound call
- Included in every log line
- Never used as a metric label — see the cardinality warning in [monitoring-standard.md](monitoring-standard.md)

`TBD` — the header name and format. Adopting the W3C Trace Context `traceparent` header is the interoperable choice and keeps a later move to distributed tracing open.

Distributed tracing is not adopted at this stage. Correlation identifiers give most of the diagnostic benefit at a fraction of the operational cost, and they are a prerequisite for tracing if it is adopted later.

---

## 6. Deployment Markers

The pipeline should record a deployment marker in the observability stack: service, version, environment, timestamp.

This makes the most frequently asked incident question answerable directly: *did this start when we deployed?* Without markers, that correlation is done by someone remembering the release time and eyeballing a graph, under pressure.

`TBD` — the mechanism, and whether markers are metrics, log events, or Grafana annotations.

---

## 7. Environment Expectations

Observability requirements scale with the environment, consistent with [environment-architecture.md](../01-architecture/environment-architecture.md).

| Capability | DEV | UAT | PROD |
| --- | --- | --- | --- |
| Health endpoints | Yes | Yes | Yes |
| Metrics collected | Yes | Yes | Yes |
| Logs aggregated | Yes | Yes | Yes |
| Dashboards | Optional | Yes | Yes |
| Alerting | None or low severity | Low severity | Actionable, routed to on-call |
| Retention | Short | Medium | Longest |

DEV alerting is deliberately near-zero. Alerts from an environment nobody acts on train people to ignore alerts, and that habit carries into production. See [alerting-standard.md](alerting-standard.md).

---

## 8. Instrumentation by Application Type

| Type | Requirements |
| --- | --- |
| .NET Web API | Liveness and readiness endpoints; request rate, error rate, latency by route class; runtime metrics; correlation propagation |
| .NET Worker | Heartbeat or liveness file; items processed, failures, backlog depth, time since last success; correlation where it consumes messages carrying one |
| Angular | Served by a web server exposing request metrics; browser-side signals `TBD` |

`TBD` — the metrics library and exposition approach for .NET, and whether browser-side monitoring is in scope at all. Browser monitoring answers different questions from server monitoring and brings its own privacy considerations; it should be a separate decision rather than assumed.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — health endpoint paths and response format | Every service; probe configuration |
| `TBD` — worker liveness approach | Worker deployment verification |
| `TBD` — correlation header name and format | Cross-service diagnosis |
| `TBD` — deployment marker mechanism | Incident correlation |
| `TBD` — metrics library and exposition for .NET | Instrumentation |
| `TBD` — whether browser-side monitoring is in scope | Frontend observability |
| `TBD` — whether a restricted detailed health view exists | Diagnosis versus exposure |

---

## Security Considerations

Health endpoints and metrics endpoints are both commonly unauthenticated and both routinely expose more than intended. A metrics endpoint reveals internal structure — route names, dependency names, queue names — which is reconnaissance value at no cost to an attacker. Access to it should be restricted by network position at minimum.

O6 is the requirement most easily violated by accident. A log line added during debugging, or an error object serialized wholesale, can place a token or personal data into centralized storage for the entire retention period. Deleting the source does not remove it. See [logging-standard.md](logging-standard.md).

## Operational Considerations

The observability plane fails silently. When it is unavailable, nothing stops working: deployments succeed, services run, and the platform appears healthy — while nobody can see whether it is. This is the failure most likely to be discovered during an unrelated incident, when the tooling is reached for and found to have been broken for some time.

Monitoring the monitoring is therefore a requirement, not a refinement. See the heartbeat discussion in [alerting-standard.md](alerting-standard.md).

---

## Related

- [Monitoring standard](monitoring-standard.md)
- [Logging standard](logging-standard.md)
- [Alerting standard](alerting-standard.md)
- [Dashboard standard](dashboard-standard.md)
- [Docker standard](../06-container/docker-standard.md)
- [Service interaction](../01-architecture/service-interaction.md)
