# Supporting Analysis: Runtime Platform Options & Evaluation

## 1. Context

This analysis provides the architectural evaluation supporting [ADR-0005: Use Docker Compose for Initial Runtime Platform](../../adr/0005-use-docker-compose-for-initial-runtime.md).

The organization delivers Angular frontends, React SPAs, .NET Web APIs, Go Fiber APIs, and .NET Workers. The platform must balance operational reliability, deployment automation, security, and maintenance overhead against the current engineering team size.

---

## 2. Options Evaluated

| Option | Description | Target Environment |
| --- | --- | --- |
| **Option A: Bare Linux VMs (Systemd)** | Services run as OS services; dependencies installed directly on host. | Traditional VMs |
| **Option B: Docker Engine + Docker Compose + Portainer** | Containerized workloads managed declaratively via Compose files and Portainer Stacks. | Linux VMs |
| **Option C: HashiCorp Nomad** | Lightweight workload orchestrator paired with Consul for service discovery. | Clustered VMs |
| **Option D: Kubernetes (K8s / K3s / RKE2)** | Full container orchestration with pods, ingress controllers, CRDs, and control plane. | Clustered VMs / Bare metal |

---

## 3. Evaluation Matrix

| Criterion | Weight | Bare VM (A) | Compose + Portainer (B) | Nomad (C) | Kubernetes (D) |
| --- | --- | --- | --- | --- | --- |
| **Operational Simplicity** | Critical | ⚠️ Poor (dependency drift) | ✅ High (single host per env) | ⚠️ Moderate | ❌ High cognitive load / complexity |
| **Artifact Portability** | High | ❌ Environment drift | ✅ Strict (same OCI image) | ✅ Strict (OCI image) | ✅ Strict (OCI image) |
| **Declarative Deployment** | High | ❌ Imperative scripts | ✅ Declarative `compose.yml` | ✅ Nomad job files | ✅ Kubernetes manifests |
| **Resource Overhead** | Medium | ✅ Minimal | ✅ Minimal (< 2% CPU/RAM) | ⚠️ Moderate | ❌ Heavy (Control plane requires 8GB+ RAM) |
| **Disaster Recovery Simplicity** | High | ⚠️ Complex VM imaging | ✅ Trivial (re-run Compose stack) | ⚠️ Cluster quorum restore | ❌ Complex (etcd restore, cert renewal) |
| **Future Expansion Compatibility** | High | ❌ None | ✅ High (OCI images migrate directly) | ⚠️ Proprietary syntax | ✅ Native standard |
| **Team Learning Curve** | High | ✅ Familiar | ✅ Near zero for developers | ⚠️ Unfamiliar | ❌ Steep learning curve |

---

## 4. Key Architectural Findings

### 4.1 Avoiding Premature Kubernetes Complexity
Kubernetes introduces substantial operational surface area: etcd quorum maintenance, CNI networking, ingress controllers, certificate rotation, storage class CSI drivers, and multi-node troubleshooting. For teams running dozens of services rather than thousands, Kubernetes frequently causes more downtime from platform misconfiguration than it prevents in application availability.

### 4.2 Docker Compose Provides the Necessary Abstractions
Docker Compose v2 meets all immediate requirements:
- Declarative service definitions with explicit ports, networks, and environment variables.
- CPU and memory reservations and limits (`deploy.resources`).
- Healthcheck integration (`test: ["CMD", "curl", "-f", "..."]`).
- Stop grace periods for clean connection draining.
- Log rotation bounding (`json-file` with `max-size: 10m`).

### 4.3 Clean Evolution Path
Because all applications are packaged into standardized OCI container images with standard `/healthz` endpoints and externalized configurations, migrating to Kubernetes in the future requires only writing Kubernetes manifests or Helm charts. **No application code or CI build logic needs to change.**

---

## 5. Decision Support Recommendation

**Docker Compose with Portainer is the recommended initial runtime platform.** It delivers the benefits of containerization and declarative deployment without the operational penalty of managing Kubernetes control planes.
