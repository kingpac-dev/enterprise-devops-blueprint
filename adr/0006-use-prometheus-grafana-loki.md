# ADR-0006 — Use Prometheus, Grafana, and Loki for Observability

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established. Alternatives were assessed analytically, not through trials.

---

## Context

Observability is not an addition to the delivery model — it is a prerequisite for it. Deployment verification and automatic rollback both depend on a service reporting whether it works. A service with no health signal cannot be safely deployed by a pipeline, because the pipeline cannot distinguish success from failure.

Requirements:

- Metrics with alerting, self-hosted
- Centralized, searchable logs
- Dashboards over both
- Container and host visibility
- Deployment markers, so behaviour can be correlated with releases

---

## Decision

Prometheus for metrics and alert evaluation, Loki for logs, Grafana for dashboards over both.

In practice:

- Prometheus **scrapes** services; services do not push.
- Services log structured records to stdout; logs are collected into Loki.
- Grafana queries both, and dashboards are provisioned as code rather than hand-edited.
- Alert rules live alongside the metric definitions they use.

---

## Consequences

### Positive

- Metrics and logs share one query interface in Grafana, and one label vocabulary — a service labelled consistently is findable in both.
- Loki indexes labels rather than full log content, so its storage and operational cost are considerably lower than a full-text search cluster.
- Self-hosted; no telemetry leaves the network.
- Pull-based collection means an unreachable service is itself a detectable signal.
- Alert rules and dashboards are text, so they are version-controllable and reviewable.
- Prometheus exposition is a de facto standard, with client libraries for .NET and exporters for containers and hosts.

### Negative

- **Cardinality is a hard failure mode.** Every distinct label-value combination creates a time series. A single change labelling a metric with a user or request identifier can exhaust memory and take monitoring down — which means detection is lost at the moment a problem appears. See risk R-26.
- **A single Prometheus is a single point of failure for detection**, and its failure is silent: no alerts fire, which is indistinguishable from health.
- **No built-in long-term metric storage.** Retention is bounded by local storage; year-over-year comparison would need additional components.
- **Loki's query model is not full-text search.** Teams expecting arbitrary text search across all logs will find it constrains them toward querying by label first.
- Three components to install, configure, secure, back up, and upgrade.

### Neutral

- Distributed tracing is not adopted. Correlation identifiers propagated across services give most of the diagnostic benefit at a fraction of the operational cost, and are a prerequisite if tracing is added later.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Elasticsearch, Logstash, Kibana** | Stronger full-text log search and mature dashboards. Rejected on operational cost: cluster management, index lifecycle, and memory demands are substantially higher, and it does not natively cover metrics and alerting — Prometheus or an equivalent would still be needed alongside it |
| Commercial APM and observability SaaS | Better out-of-box experience and less to operate. Rejected: telemetry — including log content — leaves the network, and cost scales with volume in a way that encourages reducing observability to reduce spend |
| Zabbix, Nagios | Host- and check-centric, designed before containers. Poor fit for ephemeral workloads and label-based querying |
| OpenTelemetry collector with an alternative backend | OpenTelemetry is an instrumentation standard rather than a backend, and remains compatible with this decision. A backend would still be required. Adopting OTel instrumentation later is not precluded |
| Prometheus with Elasticsearch for logs | Mixes the metric benefits with the log operational cost. Loki's lower cost was preferred, accepting its weaker text search |
| No centralized logging | Rejected. Diagnosing a cross-service failure from per-host log files is not viable |

---

## Security Considerations

A metrics endpoint is a structural description of a service — its routes, dependencies, and queues — and is typically unauthenticated. It should be restricted by network position at minimum. Whether scraping requires authentication in addition is `TBD`.

Log content is where sensitive data most often ends up in a system nobody classified as sensitive: centralized, retained for months, backed up, and readable by a wider group than the systems that produced it. Redaction at the source is the only approach that prevents storage; see [logging-standard.md](../docs/08-observability/logging-standard.md).

Prometheus initiates connections **into** the runtime, which is an access decision rather than an implementation detail.

Alert routing configuration contains credentials for the destination and is subject to the secrets standard.

## Operational Considerations

Two failures define operating this stack.

**Cardinality** fails suddenly rather than gradually. The mitigations are label conventions, review of new metrics, and a series-count limit that alerts before it is reached rather than at it.

**The alerting path fails silently.** A broken path produces the same signal as a healthy platform. The mitigation is a heartbeat alert watched by something **outside** this stack — a heartbeat evaluated by Prometheus and delivered through the same path proves nothing when the failure is Prometheus or that path. This is the most important open item in the observability standards.

Retention, scrape interval, and series count must be decided together; deciding retention alone produces a number that is either unaffordable or insufficient.

---

## Review Trigger

Revisit if:

- Full-text log search becomes a genuine requirement that Loki's label-first model cannot serve.
- Long-term metric retention becomes necessary, requiring downsampled storage or a different backend.
- Prometheus availability becomes materially expensive, justifying redundancy.
- Distributed tracing becomes necessary, at which point the backend choice should be revisited as a whole rather than by adding a fourth component.
- Cardinality incidents recur despite conventions, indicating the model does not fit the workload.

---

## References

- [Observability standard](../docs/08-observability/observability-standard.md)
- [Monitoring standard](../docs/08-observability/monitoring-standard.md)
- [Logging standard](../docs/08-observability/logging-standard.md)
- [Alerting standard](../docs/08-observability/alerting-standard.md)
- [Risk register](../docs/00-executive/risk-register.md)
