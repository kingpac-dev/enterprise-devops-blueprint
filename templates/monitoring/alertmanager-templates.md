# Alertmanager Notification Templates & Channel Guidance

## 1. Purpose

Provides guidance and templates for formatting alerts dispatched by Prometheus Alertmanager to operational communication channels (Slack, Microsoft Teams, Email, PagerDuty).

## 2. Scope

Covers notification message formatting, severity-based channel routing, and alert fatigue reduction patterns.

## 3. Audience

DevOps engineers, SREs, and on-call operational teams.

## 4. Status

**Published baseline.** Implements [alerting-standard.md](../../docs/08-observability/alerting-standard.md).

---

## 5. Routing Architecture & Severities

Alerts are routed according to their `severity` label:

| Severity | Receiver | Target Channel | SLA Response | Repeat Interval |
| --- | --- | --- | --- | --- |
| **`heartbeat`** | `dead-mans-snitch` | Healthchecks.io / Uptime Kuma | Automated (fails if silent) | 5m |
| **`critical`** | `pager-critical` | PagerDuty / On-call Webhook | Immediate (< 15 mins) | 1h |
| **`warning`** | `slack-warning` or `teams-warning` | `#devops-alerts` | Working hours (< 4 hours) | 4h |

---

## 6. Formatting Guidelines

### 6.1 Slack Message Format
Slack notifications use rich Markdown blocks:
- **Title**: Shows alert firing status and alert name (`[FIRING:1] HighHttpErrorRate (orders-api)`).
- **Body**: Includes `summary` (what happened), `description` (actionable guidance), and key labels (service, cluster, instance).

### 6.2 Microsoft Teams Connector
Microsoft Teams webhooks expect an Adaptive Card or MessageCard JSON schema. In Alertmanager, route through a lightweight webhook translator (such as `prometheus-msteams`) or configure the native webhook receiver defined in [`alertmanager.example.yml`](alertmanager.example.yml).

---

## 7. Inhibit Rules (Anti-Alert Fatigue)

To prevent teams from receiving dozens of redundant warnings during a primary outage:
```yaml
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'service', 'instance']
```
*Rule*: If an instance is already firing a `critical` alert (e.g. `HostDown`), all secondary `warning` alerts (e.g. `HighCpuLoad`, `DiskSpaceLow`) on that instance are automatically suppressed.

---

## 8. Related

- [Alertmanager Configuration Template](alertmanager.example.yml)
- [Alert Rules Template](alert-rules.example.yml)
- [External Heartbeat Standard](dead-mans-snitch.md)
