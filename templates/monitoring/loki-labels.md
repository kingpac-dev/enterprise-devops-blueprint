# Loki Labels

## Purpose

Which fields become Loki labels, which stay as content, and why the distinction determines whether Loki survives production.

## Status

**Draft for review.** Not implemented. The confirmed label set is undecided.

Implements [logging-standard.md](../../docs/08-observability/logging-standard.md).

---

## 1. The Distinction

Loki indexes **labels** and stores everything else as content.

Every distinct combination of label values creates a separate **stream**. Streams are the unit of indexing, chunking, and storage — so label cardinality drives Loki's cost and stability the same way series cardinality drives Prometheus's.

| Property | Label | Field |
| --- | --- | --- |
| Indexed | Yes | No |
| Query cost | Cheap | Scans matching streams |
| Cardinality | Must be **bounded** | May be unbounded |
| Changed by | Deployment or configuration | Every log line |

The rule that follows: **a label's value set must be small, predictable, and not derived from user input.**

---

## 2. Label Set

`TBD` — confirm.

| Label | Example values | Cardinality |
| --- | --- | --- |
| `environment` | `dev`, `uat`, `prod` | 3 |
| `service` | `orders-api`, `orders-web`, `orders-worker` | Number of services |
| `level` | `Information`, `Warning`, `Error`, `Critical` | 4 |
| `job` | `containers` | Small |
| `container` | Container name | Number of containers |

Total streams ≈ environments × services × levels × containers. For 10 services across 3 environments that is a few hundred — entirely fine.

### Not labels

| Field | Why |
| --- | --- |
| `correlation_id` | One stream **per request**. This is the single most common way a Loki deployment is destroyed |
| `user_id` | Unbounded, and personal data in an index |
| `order_id`, any entity identifier | Unbounded |
| `trace_id`, `span_id` | Unbounded |
| Full URL with parameters | Unbounded, and attacker-controllable |
| `version` | Bounded but changes on every release, and old streams persist for the retention period |
| `timestamp`, `duration_ms` | Continuous values |

`version` deserves the explanation. It looks bounded — there are only so many releases. But each release multiplies the stream count and the old streams remain until retention expires, so the count grows with release frequency rather than with service count. Keep it as a field.

---

## 3. Querying by Label, Filtering by Field

The model is: **narrow by label first, then filter content.**

```logql
# Narrow by label, then filter by field
{environment="prod", service="orders-api", level="Error"}
  | json
  | event = "order_submit_failed"

# Follow one request across services — correlation_id is a FIELD
{environment="prod"} | json | correlation_id = "4f2a9c1e"

# Error rate as a metric derived from logs
sum by (service) (
  rate({environment="prod", level="Error"}[5m])
)
```

The second query is the one people expect to need a label for. It does not: the label selector narrows to the environment's streams, and `correlation_id` is then a content filter. Slower than an indexed lookup, and correct.

---

## 4. Promtail Configuration Shape

```yaml
scrape_configs:
  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 15s

    relabel_configs:
      # Bounded values only. Everything else stays in the log body.
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: 'service'
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'

      # ADJUST per host. Set here rather than by the application, so it is
      # consistent regardless of what each service happens to emit.
      - target_label: 'environment'
        replacement: 'prod'

    pipeline_stages:
      - json:
          expressions:
            level: level
            event: event
            correlation_id: correlation_id
            timestamp: timestamp

      # `level` becomes a label — bounded, and worth indexing.
      # `event` and `correlation_id` deliberately do NOT.
      - labels:
          level:

      - timestamp:
          source: timestamp
          format: RFC3339Nano
```

The `labels:` block is where cardinality incidents originate. Adding `correlation_id:` there is a one-line change that makes Loki unusable, and it looks reasonable in review unless the reviewer knows to check.

`TBD` — confirm the Promtail or Alloy configuration against the installed version.

---

## 5. Retention

`TBD` — per environment. Retention is driven by:

- incident investigation depth
- audit requirements
- **data protection** — personal data must not be retained longer than its purpose justifies
- cost

The third can conflict with the first two. Where logs contain personal data, longer retention is a liability rather than an asset — which is another reason for the never-log list in [logging-standard.md](../../docs/08-observability/logging-standard.md#5-what-must-never-be-logged).

---

## 6. Symptoms of a Cardinality Problem

| Symptom | Likely cause |
| --- | --- |
| Ingestion rejected: too many streams | A high-cardinality label was added |
| Queries slow across all time ranges | Stream count too high for the index |
| Memory growth on ingesters | Too many active streams |
| Storage growth disproportionate to log volume | Many small chunks, one per stream |

The last is the subtle one. Each stream produces its own chunks, so high cardinality inflates storage even when the total number of log lines has not changed.

The fix is always the same: remove the label, and accept that the field is filtered rather than indexed.

---

## 7. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — confirmed label set | Loki stability |
| `TBD` — retention per environment | Cost, investigation depth, data protection |
| `TBD` — Promtail or Grafana Alloy, and its configuration | Collection |
| `TBD` — stream count limit and alerting before it is reached | Preventing the failure rather than reacting |
| `TBD` — who has access to production logs | Exposure of whatever the never-log list failed to keep out |

---

## Related

- [Logging standard](../../docs/08-observability/logging-standard.md)
- [Monitoring standard](../../docs/08-observability/monitoring-standard.md)
- [Observability standard](../../docs/08-observability/observability-standard.md)
