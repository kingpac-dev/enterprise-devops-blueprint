# 08 — Observability

## Purpose

Defines what services must expose, what the platform collects, and what triggers an alert.

## Scope

Metrics, logs, alerts, dashboards, and health-check expectations across Prometheus, Grafana, and Loki.

## Audience

Developers, SRE, and operations.

## Status

**Draft for review.** All five documents are written. Nothing is implemented; thresholds, retention periods, and the alert destination are undecided.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [observability-standard.md](observability-standard.md) | The service contract: health signals, required signals, correlation, deployment markers, per-application-type instrumentation | Draft |
| [monitoring-standard.md](monitoring-standard.md) | Prometheus scrape model, naming, metric types, labels and cardinality, retention | Draft |
| [logging-standard.md](logging-standard.md) | Structured format, required fields, levels, Loki labels versus fields, redaction, retention | Draft |
| [alerting-standard.md](alerting-standard.md) | What an alert is, symptom-based alerting, categories, severity, heartbeat, routing, silencing, review | Draft |
| [dashboard-standard.md](dashboard-standard.md) | Required dashboards, layout, panel selection, colour rules, dashboards as code | Draft |

## Reading Order

1. [observability-standard.md](observability-standard.md) — what a service must expose
2. [monitoring-standard.md](monitoring-standard.md) and [logging-standard.md](logging-standard.md) — how signals are collected
3. [alerting-standard.md](alerting-standard.md) — what wakes someone
4. [dashboard-standard.md](dashboard-standard.md) — what they look at once awake

---

## Required Signals

Metrics:

```text
request rate
error rate
response latency
CPU
memory
restart count
service availability
```

Logs must be structured where practical, searchable, environment-aware, correlated with service identity, and free of credentials and unnecessary personal data.

Alert categories:

```text
service unavailable
elevated error rate
high latency
resource exhaustion
repeated container restart
disk usage
certificate expiry
deployment failure
```

Alerts must cover meaningful, actionable conditions rather than noise.

---

## Health Checks

Production services should expose health endpoints where technically appropriate, for example `/health`.

For .NET services, distinguish liveness, readiness, and dependency health where useful.

Do not expose sensitive infrastructure details through public health endpoints.

---

## Open Items

- `TBD` — metric retention period
- `TBD` — log retention period per environment
- `TBD` — alert routing destination and on-call model
- `TBD` — latency and error-rate thresholds per service class

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| A broken alerting path produces the same signal as a healthy platform: silence. A heartbeat watched from outside the system is the only thing that detects it | [alerting-standard.md](alerting-standard.md#6-monitoring-the-monitoring) |
| Label cardinality is how Prometheus and Loki are destroyed by a well-intentioned change. Any label whose values come from user input is unbounded by definition | [monitoring-standard.md](monitoring-standard.md#5-labels-and-cardinality) |
| A generic "log the whole exception" handler will log connection strings on the occasions a database connection fails — the occasions most likely to be investigated | [logging-standard.md](logging-standard.md#5-what-must-never-be-logged) |
| Grafana assigns series colours by position, so filtering repaints the survivors. Colours must be pinned per entity | [dashboard-standard.md](dashboard-standard.md#6-colour) |

## Answers Provided to Earlier Standards

These documents close `TBD` items that earlier standards deferred here:

| Deferred from | Resolved as |
| --- | --- |
| Worker liveness approach, from [docker-standard.md](../06-container/docker-standard.md) | Heartbeat metric recommended; options and trade-offs in [observability-standard.md](observability-standard.md#3-health-signals) |
| Log redaction requirements, from [service-interaction.md](../01-architecture/service-interaction.md) | Never-log list and redaction placement in [logging-standard.md](logging-standard.md#5-what-must-never-be-logged) |
| Alert path failure (interaction I-11) | Heartbeat with an external watcher, in [alerting-standard.md](alerting-standard.md#6-monitoring-the-monitoring) |
| Loki labels and cardinality, from [templates/monitoring/](../../templates/monitoring/) | Label-versus-field split in [logging-standard.md](logging-standard.md#4-loki-labels-versus-fields) |

---

## Related

- [Documentation index](../README.md)
- [Operations runbooks](../09-operations/)
- [Monitoring templates](../../templates/monitoring/)
- [Architecture](../01-architecture/)
