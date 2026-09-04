# Diagram: Observability Telemetry & Alerting Flow

## 1. Purpose

Visualizes the collection, ingestion, retention, visualization, and alerting pipelines for metrics and logs across the platform.

Implements: [docs/08-observability/observability-standard.md](../../docs/08-observability/observability-standard.md) and [docs/08-observability/alerting-standard.md](../../docs/08-observability/alerting-standard.md).

---

## 2. Telemetry & Alerting Architecture

```mermaid
flowchart TD
    subgraph WorkloadSources["Workload & Infrastructure Telemetry Sources"]
        CONTAINERS["Application Containers\n(Web, API, Worker)"]
        HOST_SYS["Linux Host OS\n(CPU, RAM, Disk, Network)"]
        PLATFORM_TOOLS["Platform Services\n(Jenkins, Harbor, Nginx)"]
    end

    subgraph CollectionLayer["Metric & Log Collection Layer"]
        CADVISOR["cAdvisor\n(Container Resource Metrics)"]
        NODE_EXP["Node Exporter\n(Host Hardware & OS Metrics)"]
        APP_EXPORTERS["App /metrics Endpoints\n(Prometheus .NET/Go Client)"]
        PROMTAIL["Promtail Daemon\n(Docker JSON Log Reader)"]
    end

    subgraph StorageLayer["Storage & Processing Engines"]
        PROM["Prometheus Server\n(15-day Time-Series TSDB)"]
        LOKI["Grafana Loki Engine\n(14-day Chunked Log Storage)"]
    end

    subgraph VisualizationAlerting["Visualization & Alerting"]
        GRAFANA["Grafana Dashboards\n(Unified Metrics & Correlated Logs)"]
        ALERT_RULES["Alertmanager / Rules Engine\n(Evaluates alerts.yml every 15s)"]
        NOTIFY["Alert Destinations\n(Slack, Webhook, PagerDuty)"]
    end

    %% Metric Flow
    CONTAINERS -->|Cgroup Stats| CADVISOR
    HOST_SYS -->|/proc & /sys| NODE_EXP
    CONTAINERS -->|Request Rate, Latency, Errors| APP_EXPORTERS
    PLATFORM_TOOLS -->|Plugin Metrics| PROM

    CADVISOR & NODE_EXP & APP_EXPORTERS -->|Pull Scrape every 15s| PROM

    %% Log Flow
    CONTAINERS & PLATFORM_TOOLS -->|stdout / stderr JSON| PROMTAIL
    PROMTAIL -->|Push Compressed Chunks (HTTP :3100)| LOKI

    %% Visualization Queries
    GRAFANA -->|PromQL Query (:9090)| PROM
    GRAFANA -->|LogQL Query (:3100)| LOKI

    %% Alerting
    PROM -->|Evaluate Rule Expressions| ALERT_RULES
    ALERT_RULES -->|Critical / Warning Fired| NOTIFY

    classDef source fill:#f1f3f4,stroke:#5f6368,stroke-width:1px;
    classDef storage fill:#e8f0fe,stroke:#1a73e8,stroke-width:2px;
    classDef alert fill:#fce8e6,stroke:#c5221f,stroke-width:2px;
    
    class PROM,LOKI storage;
    class ALERT_RULES,NOTIFY alert;
```

---

## 3. Observability Standards Summary

| Telemetry Type | Collection Method | Engine | Default Retention | Key Metrics / Signals |
| --- | --- | --- | --- | --- |
| **System Metrics** | Pull (every 15s) | Prometheus | 15 days | CPU util, memory usage, disk IO, network IO |
| **App Metrics** | Pull (`/metrics`) | Prometheus | 15 days | Request rate, Error rate (5xx), P95/P99 latency |
| **Container Logs** | Push (via Promtail) | Loki | 14 days (336h) | Structured JSON logs, trace IDs, exception stacks |
| **Visual Dashboards** | Web UI (:3000) | Grafana | N/A | Service health, throughput, container resources |
| **Alerts** | Push notification | Alertmanager | Real-time | InstanceDown, DiskSpaceLow, ContainerCrash |
