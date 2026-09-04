# Implementation Plan: Portainer.io "Create Stack" Platform Deployment

## 1. Overview & Goal

The user requested:
> **"ปรับปรุงและพัฒนาระบบทั้งหมด ให้รันอยู่บน on Portainer.io(Docker) แบบ Create stack"**  
> *(Refactor and develop all systems to run on Portainer.io (Docker) using Portainer's "Create stack" capability.)*

In Portainer CE/EE, deploying systems via **"Create stack"** (under **Stacks -> Add stack**) presents specific requirements compared to raw command-line `docker compose`:
1. **No local `build:` context in Portainer Web Editor**: If a user pastes a compose file into Portainer's Web Editor, any service with `build: { context: ./configs/... }` will fail immediately because Portainer runs on a remote engine without access to client files.
2. **Configuration & Volume Portability**: Files mounted via relative paths (`./configs/prometheus/prometheus.yml`) must be accessible or handled cleanly via named volumes, container self-initialization, or Portainer Git Repository mode.
3. **Portainer Environment Variables**: Portainer provides a dedicated UI for environment variables (Key-Value pairs or raw text paste) rather than reading a local `.env` file from disk.
4. **GitOps vs Web Editor**: Portainer supports two primary "Create stack" methods:
   - **Method A: Web Editor (Pasting YAML directly)**: Requires self-contained images and standalone definitions.
   - **Method B: Git Repository (ADR-0010 GitOps)**: Portainer clones the Git repo and can read relative config files and auto-sync via webhooks.

This plan details how we will optimize and package the entire Enterprise DevOps Platform to run natively on Portainer.io with 1-click / copy-paste convenience.

---

## 2. User Review Required

> [!IMPORTANT]
> **Zero-Build Image Strategy for Portainer Web Editor**:
> In the current `infra/configs/jenkins/Dockerfile`, Jenkins is built locally with plugins and tools. To make Jenkins 100% compatible with Portainer Web Editor (without requiring a prior `docker build` command):
> - We will configure Jenkins in the Portainer stack to use the official image `jenkins/jenkins:2.440.3-lts-jdk17`.
> - On startup, an inline wrapper or initialization script will invoke `jenkins-plugin-cli` to install pinned plugins into `/var/jenkins_home` and load JCasC automatically.
> - Alternatively, teams that build images via CI can set `JENKINS_IMAGE` to their private Harbor registry image.

> [!NOTE]
> **Modular vs All-in-One Stacks in Portainer**:
> We will provide:
> 1. **All-in-One Stack** (`stack-devops-all-in-one.yml`): Runs Jenkins, SonarQube + DB, Observability (Prometheus, Grafana, Loki), and Nginx Ingress in a single Portainer stack — ideal for single-host deployments.
> 2. **Modular Stacks**:
>    - `stack-core-devops.yml`: Jenkins + SonarQube + PostgreSQL
>    - `stack-observability.yml`: Prometheus + Grafana + Loki + Promtail + cAdvisor + Node Exporter
>    - `stack-gateway-proxy.yml`: Nginx TLS Ingress
> 3. **Portainer Custom Template (`portainer-templates.json`)**: Can be added to Portainer App Templates for graphical 1-click deployment.

---

## 3. Proposed Changes & Architecture

### New Directory: `infra/portainer-stacks/`

```text
infra/
├── portainer-stacks/
│   ├── README.md                              # Complete Portainer "Create stack" walkthrough
│   ├── portainer-env.txt                      # Ready-to-paste Portainer Environment Variables
│   ├── portainer-templates.json               # Portainer App Template specification
│   ├── stack-devops-all-in-one.yml            # Complete platform in 1 single Portainer stack
│   ├── stack-core-devops.yml                  # Modular: Jenkins + SonarQube + DB
│   ├── stack-observability.yml                # Modular: Prometheus + Grafana + Loki + Exporters
│   └── stack-gateway-proxy.yml                # Modular: Nginx TLS Reverse Proxy
```

---

### Component Details

#### 1. Zero-Build Jenkins in Portainer Stack
Instead of failing on `build:`, Jenkins in `stack-core-devops.yml` and `stack-devops-all-in-one.yml` will:
- Use official image: `jenkins/jenkins:2.440.3-lts-jdk17`.
- Map `/var/run/docker.sock` to allow Jenkins jobs to run Docker commands.
- Use entrypoint/bootstrap script to install essential plugins on initial startup:
  `jenkins-plugin-cli --plugins configuration-as-code git workflow-aggregator sonar docker-workflow prometheus`
- Automatically mount Jenkins JCasC configuration from volume or environment.

#### 2. Self-Contained Observability in Portainer Stack
- **Prometheus**: Runs with a pre-baked / volume-initialized scrape configuration pointing to internal Docker service names (`node-exporter:9100`, `cadvisor:8080`, `jenkins:8080`).
- **Grafana**: Automatically pre-wires Prometheus & Loki via `GF_DATASOURCES_DEFAULT` or inline provisioning.
- **Loki & Promtail**: Scrapes Docker container logs using `/var/run/docker.sock` and `/var/lib/docker/containers`.

#### 3. Ready-to-Paste Portainer Environment (`portainer-env.txt`)
A pre-formatted list of environment variables with documentation for Portainer's **"Environment variables"** section:
- `PLATFORM_DOMAIN=devops.local`
- `JENKINS_ADMIN_PASSWORD=...`
- `SONAR_DB_PASSWORD=...`
- `GRAFANA_ADMIN_PASSWORD=...`
- `HARBOR_DOMAIN=...`

#### 4. Portainer App Templates (`portainer-templates.json`)
Allows administrators to add the repository template URL into Portainer (**Settings -> App Templates**), enabling developers to deploy the entire DevOps platform with a single click from the Portainer UI catalog.

#### 5. Step-by-step Operational Documentation in `infra/portainer-stacks/README.md`
- Visual guide for:
  - **Method 1: Create stack via Web Editor** (Copy & paste YAML + paste env vars).
  - **Method 2: Create stack via Git repository** (Point to this repo with automatic polling / webhook).
  - How to view logs, inspect container health, and access the services.

---

## 4. Verification Plan

### Automated Verification:
1. Syntax-validate all new Portainer stack Compose files (`stack-devops-all-in-one.yml`, `stack-core-devops.yml`, `stack-observability.yml`, `stack-gateway-proxy.yml`) using `yaml.safe_load`.
2. Validate JSON schema of `portainer-templates.json`.
3. Verify that NO stack file contains unsupported `build:` directives, ensuring 100% compatibility with Portainer Web Editor.

### Manual / Operational Verification:
1. Test stack simulation with `docker compose config` with mock environment variables.
2. Confirm volume definitions and network bridging work out-of-the-box.
