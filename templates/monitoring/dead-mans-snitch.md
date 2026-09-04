# External Heartbeat Standard & Dead Man's Snitch

## 1. Purpose

Establishes the standard for external monitoring liveness to prevent silent failure of the Prometheus and Alertmanager observability toolchain.

## 2. Scope

Applies to platform monitoring infrastructure, Alertmanager notification paths, and external uptime probes.

## 3. Audience

DevOps engineers, Site Reliability Engineers (SREs), and platform administrators.

## 4. Status

**Published baseline.** Architectural pattern for closing the silent detection failure gap identified in [ADR-0006](../../adr/0006-use-prometheus-grafana-loki.md).

---

## 5. The Silent Failure Problem

```text
[Host Outage / Prometheus Crash] 
            │
            ▼
Prometheus Stops Scraping ──(Silent)──> Alertmanager receives nothing ──> No Alert Sent
```

If the monitoring host crashes, network connectivity drops, or Prometheus runs out of disk space, **the system fails silently**. Alertmanager cannot send an alert because the engine responsible for evaluating alerting rules is dead.

### The Solution: Dead Man's Snitch (Inverted Heartbeat)

```text
Every 60s:
Prometheus (Rule: Watchdog) ──> Ping ──> External Service (Snitch / Healthchecks.io)
                                              │
                                              ▼
                                 If no ping received in 120s
                                              │
                                              ▼
                                 [EXTERNAL ALERT TRIGGERED]
                                 "Monitoring Infrastructure is Down!"
```

---

## 6. Implementation Pattern

### 6.1 Prometheus Watchdog Alert Rule
Add the following rule to `alert-rules.yml`:

```yaml
groups:
  - name: platform-heartbeat
    rules:
      - alert: Watchdog
        expr: vector(1)
        for: 1m
        labels:
          severity: heartbeat
        annotations:
          summary: "Prometheus heart-beat watchdog"
          description: "This alert fires continuously to prove the alerting pipeline is healthy."
```

### 6.2 External Watcher Configuration
1. **Choose an External Endpoint**:
   - SaaS: Healthchecks.io, Dead Man's Snitch, or Opsgenie Heartbeats.
   - Self-hosted: An independent Uptime Kuma instance deployed on a completely separate network/cloud.
2. **Alertmanager Routing**:
   Route alerts with label `severity: heartbeat` to a webhook pointing to the external snitch URL.

---

## 7. Probe Script Alternative

For environments where Alertmanager cannot directly reach an external webhook, use the standalone probe script:

- [`templates/monitoring/heartbeat-probe.sh`](heartbeat-probe.sh)

Run via a cron job on an independent host:
```bash
* * * * * /opt/devops-platform/scripts/heartbeat-probe.sh --snitch-url https://snitch.example.com/api/ping/UUID
```

---

## 8. Related

- [Observability Architecture Diagram](../../architecture/diagrams/observability-flow.md)
- [Prometheus Scrape Configuration](prometheus-scrape.example.yml)
- [Alert Rules Template](alert-rules.example.yml)
