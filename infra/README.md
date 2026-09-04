# Enterprise DevOps Platform — Deployment & Operations Guide

## 1. Overview

This directory contains the **Infrastructure as Code (IaC)** and deployment manifests to instantiate the core delivery platform defined in the Enterprise DevOps Blueprint.

The platform architecture implements:
- **CI/CD Automation**: Self-hosted Jenkins LTS configured via Jenkins Configuration as Code (JCasC).
- **Static Code Analysis**: SonarQube Community LTS with a dedicated PostgreSQL backend.
- **GitOps & Operational Visibility**: Portainer CE managing Docker Compose stacks.
- **Full-Stack Observability**: Prometheus metrics, Grafana dashboards, Loki log aggregation, Promtail log collector, and cAdvisor/Node Exporter resource monitoring.
- **Edge Gateway**: Nginx TLS reverse proxy terminating HTTPS for all internal tools.

---

## 2. Directory Layout

```text
infra/
├── .env.example                               # Environment variables template
├── README.md                                  # This guide
├── portainer-stacks/                          # Portainer.io "Create Stack" Zero-Build Manifests
│   ├── README.md                              # Complete Portainer Stacks deployment guide
│   ├── portainer-env.txt                      # Ready-to-paste Portainer Environment Variables
│   ├── portainer-templates.json               # Portainer Custom App Template definition
│   ├── stack-devops-all-in-one.yml            # Complete platform in 1 single Portainer stack
│   ├── stack-core-devops.yml                  # Modular: Jenkins + SonarQube + DB
│   ├── stack-observability.yml                # Modular: Prometheus + Grafana + Loki + Exporters
│   └── stack-gateway-proxy.yml                # Modular: Nginx TLS Reverse Proxy
├── docker-compose.platform.yml                # Core toolchain (Jenkins, SonarQube, Portainer)
├── docker-compose.observability.yml           # Prometheus, Grafana, Loki, cAdvisor, Node Exporter
├── docker-compose.proxy.yml                   # Nginx TLS Reverse Proxy
├── configs/
│   ├── nginx/                                 # Reverse proxy configuration & virtual hosts
│   ├── jenkins/                               # Custom Dockerfile, plugins.txt, and JCasC yaml
│   ├── sonarqube/                             # SonarQube performance & database tuning
│   ├── prometheus/                            # Metric scraping configuration & alerting rules
│   ├── grafana/                               # Provisioned datasources (Prometheus, Loki) & dashboards
│   └── loki/                                  # Loki retention & Promtail container log scrapers
└── gitops-workloads/                          # Reference GitOps stacks for Portainer
    ├── dev/orders-stack.yml
    ├── uat/orders-stack.yml
    └── prod/orders-stack.yml
```

> [!TIP]
> **Deploying via Portainer.io UI ("Create stack")**:
> If deploying via the Portainer Web UI, use the dedicated manifests in [`portainer-stacks/`](portainer-stacks/). They require **zero local build contexts**, auto-bootstrap plugins and configurations on container startup, and can be pasted directly into Portainer's **Web editor**. See [`portainer-stacks/README.md`](portainer-stacks/README.md).

---

## 3. Hardware & System Prerequisites

Before deployment, ensure the target host meets the baseline from [docs/02-infrastructure/server-sizing-guideline.md](../docs/02-infrastructure/server-sizing-guideline.md):

| Resource | Minimum (Evaluation) | Recommended (Production) |
| --- | --- | --- |
| **OS** | Ubuntu 24.04 LTS (x86_64) | Ubuntu 24.04 LTS (x86_64) |
| **vCPU** | 4 cores | 8 cores |
| **RAM** | 8 GB | 16 GB - 32 GB |
| **Disk** | 100 GB SSD (dedicated `/var/lib/docker`) | 250+ GB NVMe |
| **Docker** | Docker Engine 25+ & Compose v2.20+ | Pinned Docker Engine 25+ |

---

## 4. Quick Start: Deploying the Platform

### Step 1: Prepare the Host (Run once as root/sudo)

Execute the host setup script to configure system clock, kernel parameters (`vm.max_map_count=524288`), install Docker Engine, and set up UFW firewall rules:

```bash
sudo bash scripts/setup-host.sh
```

### Step 2: Configure Platform Environment Variables

Copy the template and adjust secrets, domain names, and database credentials:

```bash
cp infra/.env.example infra/.env
nano infra/.env
```

### Step 3: Run the Automated Bootstrap

The master bootstrap script handles certificate generation, network provisioning, sequential container startup, and initial health polling:

```bash
bash scripts/bootstrap-platform.sh
```

### Step 4: Run the Verification Drill

Verify that all service endpoints, databases, metrics scraping targets, and log streams are healthy:

```bash
bash scripts/verify-platform.sh
```

---

## 5. Service Endpoints & Default Ports

When accessed through the Nginx Ingress Gateway (HTTPS Port 443):

| Service | Default URL | Purpose |
| --- | --- | --- |
| **Jenkins** | `https://jenkins.devops.local/` | CI/CD Pipeline Controller |
| **SonarQube** | `https://sonarqube.devops.local/` | Code Quality & Security Gate |
| **Portainer** | `https://portainer.devops.local/` | GitOps Stack & Container Operations |
| **Grafana** | `https://grafana.devops.local/` | Metric & Log Dashboards |
| **Prometheus** | `https://prometheus.devops.local/` | Metrics Engine & Alert Manager |

*(Note: Replace `devops.local` with your organization's internal DNS name in `infra/.env`)*

---

## 6. Maintenance & Operational Procedures

- **Backups**: Follow [runbooks/jenkins-backup-and-restore.md](../runbooks/jenkins-backup-and-restore.md) and [docs/11-disaster-recovery/backup-standard.md](../docs/11-disaster-recovery/backup-standard.md).
- **Certificate Renewal**: Follow [docs/09-operations/certificate-renewal-runbook.md](../docs/09-operations/certificate-renewal-runbook.md).
- **Upgrades**: Always pull pinned container versions and test in non-production environments first.
