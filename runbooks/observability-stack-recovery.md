# Runbook — Observability Stack Recovery

> **This runbook has never been executed.** Verify against the installed versions before relying on it.

## When to Use

| Situation | Section |
| --- | --- |
| The heartbeat has stopped arriving | 2 |
| Prometheus unavailable | 3 |
| Loki unavailable | 4 |
| Grafana unavailable | 5 |
| Alerts not reaching their destination | 6 |
| Prometheus out of memory or storage | 7 |

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| On-call (`TBD`) | Detects; escalates |

---

## 1. Treat Production as Unmonitored

While any part of this stack is down, **assume production is unmonitored** until proven otherwise.

Consider freezing deployments. Deployment verification and automatic rollback both depend on health signals; deploying without them means deploying without knowing the outcome.

**Nothing appears wrong during this failure.** Services run, deployments succeed, dashboards may even load. The absence of alerts is indistinguishable from health — which is why this stack needs a watcher outside itself.

---

## 2. The Heartbeat Has Stopped

The heartbeat always fires and is routed to a watcher outside this stack. Its **absence** is the alarm — and it is the only signal that distinguishes a broken alerting path from a healthy platform.

Work outward from the delivery end, because that is the order in which the failure is cheapest to find:

```text
1. Is the notification destination itself working?
     Send a test notification from another source
2. Is the alert router (Alertmanager) running and reachable?
3. Is Prometheus running?
4. Are Prometheus rules loading?
     Check for rule evaluation failures
5. Is the heartbeat rule present and evaluating?
6. Is the route from the rule to the destination correct?
```

Steps 1 and 2 are checked first because a broken destination or router produces the same silence as a dead Prometheus, and both are faster to check.

**Until the heartbeat resumes, no alert can be trusted to fire.** Say so explicitly to whoever is relying on alerting.

---

## 3. Prometheus Unavailable

**Lost:** metric collection, alert evaluation, and therefore detection.

```text
1. Check the process and its logs
2. Check disk — Prometheus stops writing when its storage is full
3. Check memory — see section 7; this is the most common cause
4. Restart
5. Verify targets are being scraped
6. Verify rules load without evaluation failures
7. Verify the heartbeat resumes at the external watcher
```

**Verify:**

- [ ] All expected targets are up
- [ ] No rule evaluation failures
- [ ] Heartbeat arriving
- [ ] Gap in the metric history recorded — it will appear on dashboards and in any later incident review

Step 7 is the real verification. Prometheus running is not the same as alerts reaching people.

---

## 4. Loki Unavailable

**Lost:** centralized log search. Incident diagnosis is degraded; nothing stops working.

```text
1. Check the process and its logs
2. Check disk
3. Check the collector on each host — logs may be buffering or dropping
4. Restart
5. Verify logs arrive with the correct labels
```

Whether logs from the outage window are recoverable depends on the collector's buffering. `TBD` — confirm the configured behaviour, because it determines whether an outage costs visibility or costs the record.

Container logs remain on each host, subject to rotation limits, so a short outage is usually recoverable and a long one is not.

---

## 5. Grafana Unavailable

**Lost:** dashboards. Metrics and logs are still collected; alerting is unaffected because Prometheus evaluates rules.

The least urgent of the three.

```text
1. Check the process and its logs
2. Check its data source connectivity
3. Restart
4. Verify a dashboard loads against each data source
```

If Grafana's own state is lost and dashboards were **provisioned as code**, restoring it is redeploying and re-provisioning. If they were hand-edited in the UI, they are gone — which is the argument for dashboards as code, encountered at the worst moment.

---

## 6. Alerts Not Reaching Their Destination

Rules evaluate; notifications do not arrive.

```text
1. Confirm the rule is firing — check the Prometheus alerts view
2. Check the router received it
3. Check routing configuration: does this alert match a route?
4. Check for an active SILENCE — an indefinite silence looks exactly
   like a broken alert path
5. Check the destination's own status and credentials
6. Send a test notification
```

Step 4 catches a common and frustrating case. A silence created during a previous incident and never removed suppresses the alert while the rule fires correctly, and every diagnostic step above it passes.

Silences must be time-bounded. An indefinite one is a deleted alert that still appears in the alert list.

---

## 7. Prometheus Out of Memory or Storage

Almost always **cardinality**, not scale.

```text
1. Check the current series count
2. Identify the metrics with the highest series count
3. Look for a label carrying an unbounded value:
     user identifiers, request or correlation identifiers,
     session identifiers, full URLs with parameters, IP addresses
4. Identify the change that introduced it
5. Remove the label at the source, or drop it with a relabel rule
6. Restart Prometheus
7. Old series expire with retention — space is not reclaimed immediately
```

Step 5's relabel rule is the fast mitigation; removing the label at the source is the fix. Do both, in that order.

**Route labels are the usual culprit**: `/api/orders/84213` instead of `/api/orders/{id}` creates one series per order ever requested. It is the single most common way a Prometheus instance is destroyed by a well-intentioned change.

`TBD` — a series-count limit that alerts *before* it is reached rather than at it.

---

## 8. After Any Recovery

- [ ] Verify the heartbeat is arriving
- [ ] Verify all targets are scraped
- [ ] Verify logs are arriving
- [ ] Verify an alert reaches its destination — **test it, do not assume**
- [ ] Record the monitoring gap window
- [ ] Check whether anything went wrong during the blind period

The last is easy to skip and is the reason the outage mattered. Nothing alerted during the gap; that is not evidence that nothing happened.

---

## 9. Open Items

| Item |
| --- |
| `TBD` — the external heartbeat watcher, without which detection failure is undetectable |
| `TBD` — collector buffering behaviour during a Loki outage |
| `TBD` — series-count limit and its alert |
| `TBD` — whether dashboards are provisioned as code |
| `TBD` — maximum silence duration and who may create one |
| `TBD` — retention and storage sizing for Prometheus and Loki |

The first is the most important open item in the observability standards. Everything else in this runbook assumes someone noticed.

---

## Related

- [Alerting standard](../docs/08-observability/alerting-standard.md)
- [Monitoring standard](../docs/08-observability/monitoring-standard.md)
- [Logging standard](../docs/08-observability/logging-standard.md)
- [Dashboard standard](../docs/08-observability/dashboard-standard.md)
- [Disaster recovery plan](../docs/11-disaster-recovery/disaster-recovery-plan.md)
