# Portainer.io "Create Stack" Deployment Guide

This directory provides production-ready Docker Compose manifests specifically tailored for deployment via **Portainer.io CE/EE** through the **"Create stack"** workflow.

All stacks in this directory are **Zero-Build Enabled**: they require no local Docker build contexts, pull standard images from public/private registries, and automatically bootstrap configurations, plugins, and dependencies on container startup.

---

## 1. Available Portainer Stacks

| Stack File | Purpose | Recommended Use Case |
| --- | --- | --- |
| [`stack-devops-all-in-one.yml`](stack-devops-all-in-one.yml) | **Complete Platform**: Jenkins LTS + SonarQube LTS + DB + Prometheus + Grafana + Loki + Promtail + cAdvisor + Node Exporter + Gateway | Evaluation, Single-Node VM, Quick Bootstrap |
| [`stack-core-devops.yml`](stack-core-devops.yml) | **Core CI/CD & Quality**: Jenkins Controller + SonarQube LTS + PostgreSQL 15 | Dedicated Toolchain Host |
| [`stack-observability.yml`](stack-observability.yml) | **Observability Suite**: Prometheus + Grafana + Loki + Promtail + cAdvisor + Node Exporter | Dedicated Monitoring Host |
| [`stack-gateway-proxy.yml`](stack-gateway-proxy.yml) | **Edge Ingress Gateway**: Nginx Reverse Proxy with path & host routing | Edge / Public Facing Ingress |

---

## 2. Deployment Method 1: Web Editor (Copy & Paste)

This is the fastest method to deploy directly from the Portainer Web UI:

### Step 1: Open Portainer & Navigate to Stacks
1. Log in to your Portainer instance (e.g., `https://<PORTAINER_IP>:9443`).
2. Select your Docker environment (e.g., **local**).
3. On the left sidebar, click **Stacks** -> **+ Add stack**.

### Step 2: Configure Stack Details
1. **Name**: Enter a name, e.g., `devops-platform`.
2. **Build method**: Ensure **Web editor** is selected.

### Step 3: Paste Stack YAML
1. Open [`stack-devops-all-in-one.yml`](stack-devops-all-in-one.yml) (or [`stack-core-devops.yml`](stack-core-devops.yml)).
2. Copy the entire file content and paste it into the Portainer Web editor area.

### Step 4: Supply Environment Variables
1. Scroll down to the **Environment variables** section.
2. Click the **Advanced mode** toggle button (switch from Key/Value inputs to raw text box).
3. Open [`portainer-env.txt`](portainer-env.txt).
4. Copy the contents, paste them into the box, and customize any passwords or domain names as desired.

### Step 5: Deploy
1. Click **Deploy the stack**.
2. Portainer will pull the container images, create the network `devops-platform-net`, mount named volumes, and start all containers.

---

## 3. Deployment Method 2: Git Repository (GitOps per ADR-0010)

Using Portainer's Git repository integration allows automatic updates whenever commits are pushed to your blueprint repository:

1. In Portainer, go to **Stacks** -> **+ Add stack**.
2. **Name**: e.g., `devops-platform-gitops`.
3. **Build method**: Select **Repository**.
4. **Repository URL**: Enter your Git repository URL:
   `https://github.com/kingpac-dev/enterprise-devops-blueprint.git`
5. **Repository reference**: `refs/heads/main` (or your deployment branch).
6. **Compose path**:
   `infra/portainer-stacks/stack-devops-all-in-one.yml`
7. **Automatic updates**:
   - Turn **ON** `Automatic updates`.
   - Choose **Polling** (e.g., fetch every 5 minutes) OR copy the **Webhook URL** to configure in GitHub repository webhooks.
8. **Environment variables**:
   - Paste the contents of [`portainer-env.txt`](portainer-env.txt) into the Environment variables section.
9. Click **Deploy the stack**.

---

## 4. Deployment Method 3: Portainer Custom App Template

You can register this entire blueprint into Portainer's graphical catalog:

1. In Portainer, navigate to **Settings** -> **App Templates**.
2. In **URL**, enter the raw URL to [`portainer-templates.json`](portainer-templates.json) in your repository:
   `https://raw.githubusercontent.com/kingpac-dev/enterprise-devops-blueprint/main/infra/portainer-stacks/portainer-templates.json`
3. Click **Save settings**.
4. Now, go to **App Templates** in the sidebar: you will see **Enterprise DevOps Platform (All-in-One)** and **DevOps Core Toolchain** cards.
5. Click a template, fill out the simple form fields (Passwords, Domain), and click **Deploy**.

---

## 5. Service Ports & Initial Access

Once deployed, access the services on your Docker host IP:

| Service | Port / URL | Default Credentials |
| --- | --- | --- |
| **Gateway (Reverse Proxy)** | `http://<HOST_IP>:80/` | Web Landing Page |
| **Jenkins Controller** | `http://<HOST_IP>:8080/` | `admin` / Password set in `portainer-env.txt` |
| **SonarQube Server** | `http://<HOST_IP>:9000/` | `admin` / `admin` (Change on first login) |
| **Grafana Dashboards** | `http://<HOST_IP>:3000/` | `admin` / Password set in `portainer-env.txt` |
| **Prometheus Metrics** | `http://<HOST_IP>:9090/` | Open (Internal metrics) |
| **cAdvisor Metrics** | `http://<HOST_IP>:8082/` | Container Resource Inspector |

---

## 6. Host Preparation Notes (Important)

Before deploying SonarQube in Portainer, the Docker host must satisfy kernel requirements:
```bash
# Set required Elasticsearch memory map count
sudo sysctl -w vm.max_map_count=524288
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.d/99-sonarqube.conf
```
*(Or run `sudo bash scripts/setup-host.sh` on the host prior to deployment).*
