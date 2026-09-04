# Diagram: Network Flows & Zone Architecture

## 1. Purpose

Visualizes network segmentation, security zones, protocol ports, and directional flows between developers, external source control, build toolchain, runtime targets, and observability systems.

Implements: [docs/03-network/network-architecture.md](../../docs/03-network/network-architecture.md) and [docs/03-network/firewall-and-port-matrix.md](../../docs/03-network/firewall-and-port-matrix.md).

---

## 2. Network Segmentation Flowchart

```mermaid
flowchart TB
    subgraph ClientZone["External / Developer Zone"]
        DEV_USER["Developers / Engineers"]
        GITHUB["GitHub.com\n(Source Control & PRs)"]
    end

    subgraph IngressGateway["Ingress Gateway (DMZ / Edge)"]
        NGINX["Nginx TLS Reverse Proxy\n(HTTPS :443 / HTTP :80)"]
    end

    subgraph ToolchainZone["Toolchain Zone (Internal Network)"]
        JENKINS["Jenkins Controller\n(:8080 / :50000)"]
        SONAR["SonarQube + DB\n(:9000)"]
        HARBOR["Harbor Container Registry\n(:8443)"]
    end

    subgraph RuntimeZone["Runtime Zones (Isolated Environments)"]
        subgraph DevEnv["DEV Runtime"]
            DEV_HOST["DEV Containers\nPortainer Agent"]
        end
        subgraph UatEnv["UAT Runtime"]
            UAT_HOST["UAT Containers\nPortainer Agent"]
        end
        subgraph ProdEnv["PROD Runtime (Strict Firewall)"]
            PROD_HOST["PROD Containers\nPortainer Agent"]
        end
    end

    subgraph ObsZone["Observability Zone"]
        PROM["Prometheus Server\n(:9090)"]
        GRAF["Grafana Dashboards\n(:3000)"]
        LOKI["Loki Log Storage\n(:3100)"]
    end

    %% External & Ingress Flows
    DEV_USER -->|1. Git Push / PR (HTTPS :443)| GITHUB
    GITHUB -->|2. Webhook Trigger (HTTPS :443)| NGINX
    NGINX -->|Forward Webhook| JENKINS

    %% Toolchain Internal Flows
    JENKINS -->|3. Git Checkout (HTTPS :443)| GITHUB
    JENKINS -->|4. Static Analysis (HTTPS :443)| SONAR
    JENKINS -->|5. Push Image & SBOM (HTTPS :443)| HARBOR

    %% Runtime Inbound/Outbound Flows
    DEV_HOST -->|6. Pull DEV Image (HTTPS :443)| HARBOR
    UAT_HOST -->|6. Pull UAT Image (HTTPS :443)| HARBOR
    PROD_HOST -->|6. Pull PROD Image (HTTPS :443)| HARBOR

    %% Logging & Monitoring Flows
    DEV_HOST & UAT_HOST & PROD_HOST -->|7. Ship Logs (HTTP :3100)| LOKI
    PROM -->|8. Scrape Metrics (:9100 / :8080)| DEV_HOST & UAT_HOST & PROD_HOST
    PROM -->|Scrape Toolchain Metrics| JENKINS & HARBOR
    GRAF -->|Query Metrics (:9090)| PROM
    GRAF -->|Query Logs (:3100)| LOKI

    %% Management UI Access via Ingress
    DEV_USER -->|Management HTTPS (:443)| NGINX
    NGINX -->|Route by Domain| JENKINS & SONAR & GRAF & HARBOR

    %% Blocked Traffic
    DevEnv -.-x|DENY: Cross-Env Traffic Prohibited| ProdEnv
    UatEnv -.-x|DENY: Cross-Env Traffic Prohibited| ProdEnv

    classDef zone fill:#f8f9fa,stroke:#3c4043,stroke-width:1px;
    classDef security fill:#fce8e6,stroke:#c5221f,stroke-width:2px;
```

---

## 3. Directional Flow Principles

1. **Inbound Surface**: Only the Nginx Ingress Gateway accepts external inbound HTTPS traffic (Port 443).
2. **Harbor Pull-Only**: Runtime hosts (DEV, UAT, PROD) initiate outbound TLS connections to Harbor to pull images. Harbor never initiates connections into runtime hosts.
3. **Observability Ingress**: Prometheus initiates scrapes into application metric endpoints (`/metrics`).
4. **Environment Isolation**: No network routes or firewall allowances exist between DEV, UAT, and PROD.
