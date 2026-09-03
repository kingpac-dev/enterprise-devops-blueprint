# Monitoring Templates

## Purpose

Reusable Prometheus, alerting, and Grafana configuration so every service is observable in the same way.

## Scope

Scrape configuration, alert rules, and dashboard definitions. Observability policy is defined in [docs/08-observability/](../../docs/08-observability/).

## Status

**Draft for review.** All four are written and validated. **Every threshold is `TBD`** — they are shapes, not decisions.

---

## Templates

| File | Intent | Status |
| --- | --- | --- |
| [prometheus-scrape.example.yml](prometheus-scrape.example.yml) | Scrape configuration for applications, containers, hosts, and the platform itself | Draft |
| [alert-rules.example.yml](alert-rules.example.yml) | 4 recording rules and 13 alerts, including the heartbeat | Draft |
| [grafana-dashboard-service.json](grafana-dashboard-service.json) | Per-service dashboard, 11 panels | Draft |
| [loki-labels.md](loki-labels.md) | Label-versus-field split and cardinality guidance | Draft |

## The Heartbeat Is the Most Important Rule

A broken alerting path produces exactly the same signal as a healthy platform: **silence**.

`Heartbeat` always fires, and is routed to a watcher that expects it on a schedule. Its **absence** is the alarm.

The watcher must be **outside** this stack. A heartbeat evaluated by Prometheus and delivered through the same alerting path proves nothing when the failure is Prometheus or that path. `TBD` — the external watcher; without it, detection failure is undetectable.

## Dashboard Design Decisions

The dashboard follows [dashboard-standard.md](../../docs/08-observability/dashboard-standard.md). Four choices are deliberate and easy to undo by accident:

| Choice | Reason |
| --- | --- |
| **No panel has a second y-axis** | Error rate and request rate are separate panels. Two independently scaled axes make the alignment of the lines an artifact of the scaling, so the chart shows a correlation that is not in the data |
| **Series colours are pinned per entity** | Grafana assigns palette colours by series order, so filtering repaints the survivors — and a reader who learned "orders-api is blue" is now looking at something else |
| **Latency percentiles use one hue stepped light-to-dark**, not categorical colours | p50/p95/p99 are an ordered scale, not distinct identities. p99 is lightest because it is the one to look at |
| **Stat tiles use `colorMode: value`** | The number is coloured, not the background, so the value is always readable — status is never carried by colour alone |

## Validation Performed

| Check | Result |
| --- | --- |
| YAML syntax, both files | Valid |
| Alert rule structure: every alert has `for`, severity, summary, and a runbook link | Pass — 13 alerts, 4 recording rules |
| Grafana dashboard JSON | Valid; 11 panels, unique ids, every panel has a description |
| No panel declares a second y-axis | Confirmed |
| Status colours never reused as series colours | Confirmed |
| Every colour drawn from the validated palette | Confirmed |
| **Palette CVD separation** (`validate_palette.js`, dark surface) | Categorical **PASS** — worst adjacent ΔE 26.8 protan, 32.4 tritan. Ordinal ramp **PASS** — monotone lightness, single hue, light end clears the surface |
| **`promtool check rules`** | **Not run — promtool not available in this environment** |
| **Dashboard imported into Grafana** | **Not run — no Grafana available** |

Structure and colour are verified. The PromQL expressions have not been evaluated against a real Prometheus, and the dashboard has not been rendered.

---

## Baseline Alert Coverage

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

Every alert must be actionable. An alert nobody acts on trains people to ignore alerts, which is worse than not having it.

---

## Cardinality Caution

Do not label metrics or logs with unbounded values such as request IDs, user identifiers, or full URLs with parameters. High-cardinality labels degrade Prometheus and Loki and are difficult to reverse once adopted.

---

## Open Items

- `TBD` — alert thresholds per service class
- `TBD` — alert routing destination and on-call model
- `TBD` — metric and log retention periods
- `TBD` — Grafana organization and folder structure

---

## Related

- [Templates index](../README.md)
- [Observability standards](../../docs/08-observability/)
- [Operations runbooks](../../docs/09-operations/)
