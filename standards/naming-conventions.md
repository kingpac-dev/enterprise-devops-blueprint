# Naming Conventions Standard

## 1. Purpose

Defines organization-wide naming conventions across source control, container registries, build pipelines, deployment configurations, and runtime environments.

Consistent naming enables automated policy enforcement, audit traceability, log correlation, and seamless GitOps deployment.

## 2. Scope

Applies to all engineering teams building, deploying, or operating software within the Enterprise DevOps ecosystem.

---

## 3. Source Control Conventions

### 3.1 Repository Names

Repository names must be **lowercase**, hyphen-separated (`kebab-case`), and follow the pattern:

```text
<team-or-domain>-<service-name>[-<type>]
```

| Component | Rule | Examples |
| --- | --- | --- |
| `<team-or-domain>` | Team, product, or domain identifier | `orders`, `billing`, `inventory`, `platform` |
| `<service-name>` | Purpose or workload name | `checkout`, `payment`, `catalog` |
| `[<type>]` | Suffix denoting component type | `-api`, `-web`, `-worker`, `-infra` |

**Approved Examples:**
- `orders-api`
- `orders-worker`
- `customer-portal-web`
- `billing-service-api`

### 3.2 Branch Names

Branches must follow strict semantic prefixes:

| Branch Type | Pattern | Target Base | Deploys To |
| --- | --- | --- | --- |
| **Main** | `main` | N/A | PROD |
| **Develop** | `develop` | `main` | DEV |
| **Release** | `release/v<semver>` | `develop` | UAT |
| **Feature** | `feature/<ticket>-<description>` | `develop` | Local / Preview |
| **Bugfix** | `bugfix/<ticket>-<description>` | `develop` | Local / Preview |
| **Hotfix** | `hotfix/<ticket>-<description>` | `main` | UAT -> PROD |

**Rules:**
- All characters in `<description>` must be lowercase alphanumeric and hyphens.
- `<ticket>` represents the issue tracking ID (e.g., `JIRA-1024`, `GH-45`).

---

## 4. Container Registry (Harbor) Conventions

### 4.1 Harbor Project Hierarchy

Harbor projects partition access control, vulnerability scanning policies, and retention:

| Project | Purpose | Immutability Rule |
| --- | --- | --- |
| `library` / `base` | Approved, scanned base images (`alpine`, `dotnet`, `node`) | Enabled |
| `apps` | Standard enterprise application container images | Enabled for release tags |
| `external` | Cached third-party vendor images | Enabled |

### 4.2 Image Names & Repository Path

```text
<harbor-host>/<project>/<service-name>:<tag>
```

**Example:**
```text
harbor.devops.local/apps/orders-api:1.4.2-a82f912
```

### 4.3 Image Tagging Standard

In accordance with [ADR-0007](../adr/0007-use-immutable-container-versioning.md), container tags must provide deterministic traceability:

| Environment | Tag Pattern | Example |
| --- | --- | --- |
| **DEV** | `sha-<short-sha>` or `<semver>-dev.<build>` | `orders-api:sha-a82f912`<br>`orders-api:1.4.2-dev.84` |
| **UAT** | `<semver>-rc.<build>` | `orders-api:1.4.2-rc.12` |
| **PROD** | `<semver>` or `<semver>-<short-sha>` | `orders-api:1.4.2`<br>`orders-api:1.4.2-a82f912` |

> [!CAUTION]
> The `latest` tag must **never** be used as the sole identifier for production deployments.

---

## 5. Pipeline & Job Conventions

### 5.1 Jenkins Multibranch Pipeline

```text
<domain>/<repository-name>/<branch-name>
```

**Example:**
- `Orders/orders-api/main`
- `Orders/orders-api/develop`
- `Orders/orders-api/PR-42`

### 5.2 Jenkins Credentials Identifiers

Credentials stored in Jenkins Credentials Manager must use explicit descriptive prefixes:

| Category | Identifier Pattern | Example |
| --- | --- | --- |
| Harbor Registry | `harbor-robot-<purpose>` | `harbor-robot-jenkins-push` |
| SonarQube Token | `sonarqube-token` | `sonarqube-token` |
| SSH Keys | `ssh-key-<host-or-role>` | `ssh-key-prod-deployer` |
| Service Tokens | `token-<service>-<env>` | `token-github-webhook` |

---

## 6. Runtime & Portainer Stack Conventions

### 6.1 Portainer Stack Names

Stack names must incorporate application name and environment:

```text
<application>-<environment>
```

**Examples:**
- `orders-dev`
- `orders-uat`
- `orders-prod`
- `devops-platform-core`

### 6.2 Service Names inside Docker Compose

Service names within a Compose file must be generic, functional, lowercase words:
- `web` (Frontend / SPA)
- `api` (REST / gRPC API)
- `worker` (Background processor)
- `db` (Database)
- `cache` (Redis / Memcached)

---

## 7. Observability Resource Labels

Prometheus metrics and Loki logs must contain standard contextual labels:

| Label | Description | Example Values |
| --- | --- | --- |
| `app` | Application workload identifier | `orders-api`, `orders-worker` |
| `environment` | Deployment environment | `dev`, `uat`, `prod` |
| `version` | Release version | `1.4.2` |
| `team` | Owning engineering squad | `orders-team`, `platform-team` |
