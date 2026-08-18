# Logging Standard

## Purpose

Defines log format, required fields, levels, aggregation labels, redaction requirements, and retention.

## Scope

Application and platform logs collected into Loki. What a service must emit is in [observability-standard.md](observability-standard.md).

## Audience

Developers, platform engineers, and anyone diagnosing an incident.

## Status

**Draft for review.** Not implemented. Retention periods and the redaction mechanism are undecided.

---

## 1. Destination and Format

Logs go to **stdout and stderr**. Nothing writes log files inside a container: container filesystems are ephemeral, so those files disappear with the container — including at exactly the moment a crash makes them interesting.

Logs are **structured**, meaning machine-parseable key-value records rather than formatted prose.

```json
{"timestamp":"2026-08-16T09:14:22.481Z","level":"Error","service":"orders-api","version":"1.4.2","environment":"prod","correlation_id":"4f2a...","event":"order_submit_failed","order_status":"pending","duration_ms":1284,"message":"Order submission failed"}
```

The difference from an unstructured line is that fields can be queried. `level="Error" and event="order_submit_failed"` is a query; finding the same information in prose requires a regular expression that breaks when someone rewords the message.

Keep `message` human-readable. Structured does not mean unreadable — during an incident, people read these.

---

## 2. Required Fields

| Field | Content | Why |
| --- | --- | --- |
| `timestamp` | UTC, ISO 8601, with milliseconds | Ordering across services |
| `level` | See section 3 | Filtering and routing |
| `service` | Service name | Attribution |
| `version` | Release version | Correlating behaviour with a deployment |
| `environment` | `dev`, `uat`, `prod` | Preventing cross-environment confusion |
| `correlation_id` | Request correlation identifier | Following one request across services |
| `event` | Stable machine-readable event name | Querying without matching on prose |
| `message` | Human-readable description | Reading |

UTC is not a preference. Local-time logs cannot be correlated across services, and the ambiguity is worst around daylight-saving transitions — which is to say, worst exactly when an unexplained hour of duplicated timestamps is least welcome.

`event` is the field most often omitted and the one that makes logs queryable over time. `"order_submit_failed"` stays stable when the message text is improved; matching on the message does not.

---

## 3. Levels

| Level | Meaning | Production use |
| --- | --- | --- |
| `Trace` | Fine-grained internal detail | Never |
| `Debug` | Diagnostic detail | Temporarily, deliberately |
| `Information` | Normal significant events | Default |
| `Warning` | Unexpected but handled | Yes |
| `Error` | Operation failed; needs attention | Yes |
| `Critical` | Service is unusable | Yes |

Two conventions that keep levels meaningful:

**`Error` means someone may need to act.** A handled validation failure from a malformed client request is `Warning` at most. If every rejected input logs an error, error volume stops indicating anything and error-rate alerts become noise.

**`Debug` in production is temporary and deliberate.** It multiplies volume, cost, and the chance of logging something sensitive. If it is enabled to investigate something, it is disabled afterwards — which requires someone to remember, so `TBD` whether a time-bounded mechanism is provided.

`TBD` — default level per environment, and whether levels can be changed at run time.

---

## 4. Loki Labels Versus Fields

Loki indexes **labels** and stores everything else as content. The distinction has the same cardinality consequences as Prometheus labels — see [monitoring-standard.md](monitoring-standard.md#5-labels-and-cardinality).

| Use as a label | Keep as a field |
| --- | --- |
| `service` | `correlation_id` |
| `environment` | `user_id` |
| `level` | `order_id` |
| `job` | `duration_ms` |
| `container` | `message` |

Labels must be **bounded**: a small, predictable set of values. Fields may be unbounded; they are searched, not indexed.

Using `correlation_id` as a label creates one stream per request and will render Loki unusable. This is the single most common way a log aggregation deployment fails, and it fails in a way that looks like a query problem rather than a design problem.

`TBD` — the confirmed label set.

---

## 5. What Must Never Be Logged

| Never | Why |
| --- | --- |
| Passwords, tokens, API keys, connection strings | Centralized storage retains them for the whole retention period |
| Authorization headers and cookies | Session hijacking material |
| Full request or response bodies of sensitive operations | Contains whatever the operation handles |
| Personal data beyond what is necessary | Retention and access exceed what the purpose justifies |
| Complete exception objects without inspection | Frequently carry connection strings and request state |

The last row is where this goes wrong in practice. Logging an exception is normal; some exception types include the failing connection string or the full request in their data. A generic "log the whole exception" handler will therefore log credentials on the specific occasions when a database connection fails — the occasions most likely to be investigated by the most people.

### Why deletion is not the fix

A credential logged once is in centralized storage, in backups of that storage, and in any export taken since. It is readable by everyone with log access, which is a wider group than those with access to the system it belongs to.

Treat it as compromised and rotate, following [secrets-management.md](../07-security/secrets-management.md#8-compromise-response). Removing the log line is cleanup, not remediation.

### Redaction

`TBD` — the mechanism. Options:

| Approach | Trade-off |
| --- | --- |
| At the source, in application logging configuration | Most effective — the value never leaves the process. Requires every service to configure it correctly |
| At the collection agent | Central and consistent. The value has already left the process |
| At query time | Does not protect stored data at all |

Source-level redaction is the only approach that prevents the value from being stored. The others reduce exposure without removing it.

---

## 6. Volume

Log volume is an operational cost and a reliability risk.

Container log files are written to the host disk. Without rotation limits they grow until the disk is full, and a full disk on a runtime host stops every container on it — not just the noisy one. Rotation is configured per service in Compose; see [docker-compose-standard.md](../06-container/docker-compose-standard.md#7-logging-and-disk).

Volume also determines Loki cost and query speed. A service logging every request at `Information` with a large payload will dominate both.

Guidance: log events, not steps. One line per significant outcome, with enough fields to explain it, is more useful and cheaper than fifteen lines narrating the path taken.

`TBD` — per-service volume expectations and whether an alert fires on sudden growth. A sharp rise in log volume is often the first sign of an incident, so the alert has diagnostic value beyond cost control.

---

## 7. Retention

| Environment | Proposed retention |
| --- | --- |
| DEV | `TBD` — short |
| UAT | `TBD` — medium |
| PROD | `TBD` — longest |

Retention is driven by:

- incident investigation — how far back an investigation realistically reaches
- audit requirements — `TBD` in [10-governance/](../10-governance/)
- data protection — personal data must not be retained longer than its purpose justifies
- cost

The third can conflict with the first two. Where logs contain personal data, longer retention is a liability rather than a benefit, which is another reason for section 5.

`TBD` — retention per environment, and whether any log class has a separate, longer audit retention.

---

## 8. Platform Logs

Application logs are not the whole picture. Also collected:

| Source | Value |
| --- | --- |
| Jenkins build logs | What the pipeline did; retained separately from Loki |
| Harbor audit log | Who published, pulled, or deleted an artifact |
| Host system logs | Kernel, Docker daemon, OOM kill events |
| Reverse proxy or ingress | Requests that never reached the application |

OOM kill events belong on this list specifically. When a container is killed for exceeding its memory limit, the application typically logs nothing — it is terminated without warning. The only record is on the host, and without it the symptom is an unexplained restart.

`TBD` — whether platform logs go into Loki or are retained separately.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — logging library and structured output configuration per application type | Format consistency |
| `TBD` — confirmed Loki label set | Loki stability |
| `TBD` — redaction mechanism and where it runs | Whether sensitive data is stored |
| `TBD` — default log level per environment, and run-time adjustment | Volume, diagnosis |
| `TBD` — retention per environment | Cost, investigation depth, data protection |
| `TBD` — log volume alerting | Cost control and incident detection |
| `TBD` — platform log collection and retention | Diagnosis of host-level failures |
| `TBD` — who has access to production logs | Exposure of whatever is in them |

The last item is easy to overlook. Log access is frequently granted broadly for convenience, which makes the log store an access path to whatever section 5 failed to keep out.

---

## Security Considerations

Logs are the most common route by which sensitive data ends up in a system nobody classified as sensitive. They are centralized, retained, backed up, and widely readable.

Section 5 is therefore a security control, not a style guide. The exception-logging case is the one to design against specifically, because it is introduced by a reasonable-looking generic handler rather than by a careless individual line.

Log access should be scoped like access to any other store of the data it contains — see [access-control.md](../07-security/access-control.md).

## Operational Considerations

Structure and correlation identifiers are what make logs usable under pressure. Unstructured logs without correlation are readable, and useless at any concurrency above one request at a time.

Two failures are worth pre-empting: label cardinality, which makes Loki unusable, and unrotated container logs, which fill a host disk and stop every container on it. Both are configuration mistakes with platform-level consequences.

---

## Related

- [Observability standard](observability-standard.md)
- [Monitoring standard](monitoring-standard.md)
- [Alerting standard](alerting-standard.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
- [Secrets management](../07-security/secrets-management.md)
- [Access control](../07-security/access-control.md)
