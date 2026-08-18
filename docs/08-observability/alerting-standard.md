# Alerting Standard

## Purpose

Defines what triggers an alert, how severe it is, where it goes, and how alert quality is maintained.

## Scope

Alert rules, severity, routing, escalation, and silencing. Metric collection is in [monitoring-standard.md](monitoring-standard.md).

## Audience

Platform engineers, SRE, on-call engineers, and developers who own services.

## Status

**Draft for review.** Not implemented. Thresholds, routing destination, and the on-call model are undecided.

---

## 1. What an Alert Is

An alert is a request for a person to take action now.

That definition rules out most of what alerting systems accumulate. If nobody will act, it is not an alert — it is a dashboard panel, a report, or a metric. Every rule must have an answer to:

> When this fires at 03:00, what does the person do?

If the answer is "look at it and probably nothing", the rule does not belong in the alerting path.

This matters because alert quality is self-reinforcing in both directions. Alerts that reliably require action are read carefully. Alerts that usually require nothing are dismissed reflexively — and the reflex applies to the one that mattered. A noisy alerting system is not merely inefficient; it actively degrades response to real incidents.

---

## 2. Alert on Symptoms

Prefer alerts on what users experience over alerts on internal causes.

| Symptom alert | Cause alert |
| --- | --- |
| Error rate above threshold | CPU above 80% |
| Latency above threshold | Thread pool queue growing |
| Service unavailable | Memory above 75% |

Cause alerts fire when nothing is wrong — a service at 85% CPU serving every request correctly is fine — and stay silent when something is, because not every failure has a resource signature.

Cause metrics remain valuable for *diagnosis*. The distinction is between what wakes someone and what they look at once awake.

Exceptions where a cause alert is correct: conditions that will certainly cause failure but have not yet, where the lead time is the point. Disk filling and certificate expiry are the canonical cases — both are predictable, both are catastrophic, and both are trivially preventable with warning.

---

## 3. Categories

| Category | Condition | Severity |
| --- | --- | --- |
| Service unavailable | Health check failing, or no successful requests | Critical |
| Elevated error rate | Error ratio above threshold, sustained | Critical or High |
| High latency | Percentile above threshold, sustained | High |
| Resource exhaustion | Memory or CPU sustained near limit | High |
| Repeated container restart | Restart count rising | High |
| Disk usage | Above threshold, with lead time | High |
| Certificate expiry | Within the warning window | High |
| Deployment failure | Pipeline deployment stage failed | High |
| Backlog growth | Worker queue depth or age rising | High |
| Platform unavailable | Jenkins, Harbor, SonarQube, or Loki down | High |
| Monitoring unavailable | Prometheus not evaluating | Critical |

Two of these are frequently missing and both are consequential.

**Platform unavailable.** Harbor down stops deployment *and* rollback — the recovery path and the failure path share a dependency, as noted in [logical-architecture.md](../01-architecture/logical-architecture.md#6-failure-isolation). That deserves an alert, not a discovery during an incident.

**Monitoring unavailable.** See section 6.

`TBD` — all thresholds and durations.

---

## 4. Severity and Response

| Severity | Meaning | Response | Hours |
| --- | --- | --- | --- |
| Critical | Users affected now, or detection is blind | Immediate | Any |
| High | Degraded, or failure is imminent | Within the working day | Business hours, unless escalating |
| Low | Worth knowing; no immediate action | Next working day | Business hours |

Only Critical pages outside working hours. Every rule assigned Critical should be justified against that: an alert that wakes someone must be worth waking them for, or the next one will not be read.

`TBD` — response time targets and the on-call model.

---

## 5. Rule Quality

Every rule must satisfy all of the following:

| Requirement | Reason |
| --- | --- |
| Actionable | There is something to do |
| Documented | Links to a runbook describing what to do |
| Attributed | States which service and environment |
| Debounced | Uses a `for` duration so transient spikes do not fire |
| Not duplicated | One condition produces one alert, not five |
| Reviewed | Rules that fire without action are removed or fixed |

The `for` duration is what separates a rule from a noise generator:

```text
expr: job:http_request_error_rate:ratio5m > 0.05
for: 5m
```

Without it, a single scrape above threshold fires. With it, the condition must persist — which is what "there is a problem" means, as distinct from "there was a moment".

The runbook link is the difference between an alert and an interruption. Someone woken at 03:00 who has never seen this alert before needs a procedure, not a metric name. See [09-operations/](../09-operations/).

---

## 6. Monitoring the Monitoring

**A broken alerting path produces exactly the same signal as a healthy platform: silence.**

This is the failure mode that must be designed against explicitly, because nothing about it is observable from the inside. Prometheus stopped, the alert rules failed to load, the routing configuration broke, the notification destination stopped accepting messages — in every case, the operator's experience is an absence of alerts, which is indistinguishable from everything working.

The standard mitigation is a **heartbeat alert**: a rule that always fires, routed to a destination that expects it on a schedule. If the expected notification does not arrive, the *absence* is the alarm.

That external watcher must be outside the system it watches. A heartbeat evaluated by Prometheus and delivered by the same alerting path proves nothing when the failure is Prometheus or that path.

`TBD` — the heartbeat mechanism and what watches for its absence. This is the single most important open item in this document; without it, detection failure is undetectable, which corresponds to interaction I-11 in [service-interaction.md](../01-architecture/service-interaction.md#4-failure-behaviour).

---

## 7. Routing

`TBD` — the destination and the on-call model.

Requirements whatever is chosen:

| Requirement | Reason |
| --- | --- |
| Critical reaches a person immediately, whatever the hour | Otherwise Critical means nothing |
| High reaches the owning team during working hours | Attribution |
| Escalation if unacknowledged | An alert nobody sees is an unmonitored system |
| Grouping | One incident produces one notification, not forty |
| The destination is monitored | See section 6 |

Grouping matters more than it sounds. A host failure takes down every container on it, and ungrouped rules generate an alert per container per condition. Forty notifications for one event is worse than one, because the operator now spends the first minutes of the incident determining that they describe the same thing.

---

## 8. Silencing

Silences suppress an alert for a defined period. They are legitimate during planned maintenance and while an acknowledged incident is being worked.

| Requirement | Reason |
| --- | --- |
| Always time-bounded | A permanent silence is a deleted alert that still appears to exist |
| Scoped narrowly | A broad silence hides unrelated problems |
| Attributed and justified | Someone must be answerable for the suppression |
| Reviewed on expiry | Expiry is a prompt to fix the underlying cause |

An indefinite silence is the worst outcome available: the rule exists, appears active, and never fires. The alert list shows coverage that is not there.

`TBD` — maximum silence duration and who may create one.

---

## 9. Alert Review

Alerting degrades without maintenance. Rules accumulate, thresholds drift out of relevance, and services change.

`TBD` — review frequency. At each review:

| Question | Action if the answer is bad |
| --- | --- |
| Which alerts fired most? | Investigate whether they are noise or a real recurring problem |
| Which fired and required no action? | Fix the threshold or remove the rule |
| Which incidents had no alert? | Add coverage |
| Which alerts have no runbook? | Write one or remove the alert |
| How many silences are active? | Investigate anything long-lived |

The third question is the one that finds gaps. An incident detected by a user report rather than by an alert is a monitoring gap with a concrete example attached — which is the most useful form of feedback the alerting system receives.

---

## 10. Environment Scope

| Environment | Alerting |
| --- | --- |
| DEV | None, or Low severity to a non-paging channel |
| UAT | Low severity, business hours |
| PROD | Full, per this standard |

DEV alerting is near-zero deliberately. Alerts from an environment nobody acts on are the fastest way to train a team to dismiss alerts, and the habit does not stay in DEV.

---

## 11. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — heartbeat mechanism and external watcher | Whether detection failure is detectable |
| `TBD` — alert destination and on-call model | Whether Critical means anything |
| `TBD` — thresholds and durations per category | Every rule |
| `TBD` — escalation policy | Unacknowledged alerts |
| `TBD` — grouping configuration | Notification volume during a large incident |
| `TBD` — maximum silence duration and authority | Suppression of real problems |
| `TBD` — alert review frequency and owner | Long-term alert quality |
| `TBD` — runbook coverage per alert | Whether an alert is actionable at 03:00 |

---

## Security Considerations

Alert content can disclose service state to whatever receives it. Where alerts are routed to an external service, consider what the payload reveals — service names, error messages, and hostnames are common and are all reconnaissance value.

Alert routing configuration typically contains credentials for the destination. It is subject to [secrets-management.md](../07-security/secrets-management.md) like any other credential.

Silencing is a control-suppression capability. Who may create a silence is an access control question, and an unbounded silence on a security-relevant alert is functionally a disabled control.

## Operational Considerations

The two failure modes with the largest consequences are opposites: too many alerts, which trains people to ignore them, and a broken alerting path, which produces none at all. The first degrades gradually and is measurable through review. The second is instantaneous and invisible without a heartbeat.

Runbook coverage is what determines whether an alert is useful to the person who receives it, which is frequently not the person who wrote the rule.

---

## Related

- [Observability standard](observability-standard.md)
- [Monitoring standard](monitoring-standard.md)
- [Logging standard](logging-standard.md)
- [Dashboard standard](dashboard-standard.md)
- [Operations runbooks](../09-operations/)
- [Service interaction](../01-architecture/service-interaction.md)
