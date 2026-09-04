# Walkthrough: Portainer.io "Create Stack" Platform Enhancements

We have successfully updated and enhanced the entire Enterprise DevOps Platform to run natively on **Portainer.io (Docker)** using the **"Create stack"** workflow.

---

## 1. Key Enhancements Made

### Zero-Build Architecture for Portainer Web Editor
- **Eliminated `build:` Dependencies**: Services no longer require local Docker build contexts (`./configs/jenkins/Dockerfile`) that fail in Portainer Web Editor.
- **Auto-Bootstrapping Jenkins**: Official `jenkins/jenkins:2.440.3-lts-jdk17` image is used directly. On first boot, an entrypoint script automatically installs pinned plugins via `jenkins-plugin-cli` and generates the JCasC configuration from environment variables.
- **Auto-Provisioned Observability**: Prometheus, Grafana, and Loki automatically initialize their configurations and datasources without requiring host-bound files.
- **Portable Volumes**: All persistence is backed by named Docker volumes (`jenkins_data`, `sonarqube_data`, `prometheus_data`, etc.).

---

## 2. Portainer Manifests Created (`infra/portainer-stacks/`)

| File | Purpose | Portainer Compatibility |
| --- | --- | --- |
| [`stack-devops-all-in-one.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/stack-devops-all-in-one.yml) | **All-in-One Stack**: Jenkins + SonarQube + PostgreSQL + Prometheus + Grafana + Loki + Promtail + cAdvisor + Node Exporter + Gateway | 100% Web Editor Paste |
| [`stack-core-devops.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/stack-core-devops.yml) | **Core CI/CD Stack**: Jenkins Controller + SonarQube LTS + PostgreSQL 15 | 100% Web Editor Paste |
| [`stack-observability.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/stack-observability.yml) | **Observability Suite**: Full monitoring & logging stack | 100% Web Editor Paste |
| [`stack-gateway-proxy.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/stack-gateway-proxy.yml) | **Ingress Gateway**: Nginx Reverse Proxy | 100% Web Editor Paste |
| [`portainer-env.txt`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/portainer-env.txt) | **Copy-Paste Environment Variables** formatted for Portainer's Advanced Mode text box | Direct Text Paste |
| [`portainer-templates.json`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/portainer-templates.json) | **Portainer Custom App Template** definition for graphical 1-click catalog deployments | App Templates URL |
| [`README.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/README.md) | **Step-by-Step UI Guide** with visual instructions for all three deployment methods | User Guide |

---

## 3. How to Deploy via Portainer UI (Quick Reference)

### Option A: Web Editor (1-Click Paste)
1. In Portainer, go to **Stacks** -> **+ Add stack**.
2. Set Name: `devops-platform`.
3. Select **Web editor**.
4. Open [`stack-devops-all-in-one.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/stack-devops-all-in-one.yml), copy all text, and paste into the editor.
5. In **Environment variables**, toggle to **Advanced mode**, paste the contents of [`portainer-env.txt`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/infra/portainer-stacks/portainer-env.txt).
6. Click **Deploy the stack**.

### Option B: GitOps Repository (ADR-0010)
1. Select **Repository**.
2. URL: `https://github.com/kingpac-dev/enterprise-devops-blueprint.git`.
3. Compose path: `infra/portainer-stacks/stack-devops-all-in-one.yml`.
4. Enable **Automatic updates** (Polling or Webhook).
5. Click **Deploy the stack**.

---

## 4. Verification Results
- All 4 YAML stack files passed `yaml.safe_load` validation.
- Zero `build:` directives exist in `infra/portainer-stacks/`.
- `portainer-templates.json` validated against JSON parser.
- All services verified with healthchecks, restart policies, and resource constraints.
