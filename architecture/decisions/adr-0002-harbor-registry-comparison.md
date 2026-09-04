# Supporting Analysis: Container Registry Options & Evaluation

## 1. Context

This analysis provides the architectural evaluation supporting [ADR-0002: Use Harbor as Container Registry](../../adr/0002-use-harbor-as-container-registry.md).

The organization requires a self-hosted container registry deployed inside the internal network to serve as the single source of truth for immutable artifacts promoted across `DEV`, `UAT`, and `PROD`.

---

## 2. Options Evaluated

| Option | Description | License |
| --- | --- | --- |
| **Option A: Plain Docker Registry (`registry:2`)** | Minimal OCI registry implementation maintained by CNCF/Distribution. | Apache 2.0 |
| **Option B: Sonatype Nexus OSS** | General-purpose artifact repository supporting Docker, Maven, NuGet, npm. | Eclipse Public License |
| **Option C: JFrog Artifactory Community Edition (C/C++ & Conan)** | Dedicated artifact repository; free tier has restricted Docker capabilities. | Proprietary / Free |
| **Option D: CNCF Harbor** | Cloud-native, dedicated container registry with built-in RBAC, Trivy scanning, and immutability. | Apache 2.0 |

---

## 3. Evaluation Matrix

| Criterion | Weight | Docker Registry (A) | Nexus OSS (B) | Artifactory CE (C) | Harbor (D) |
| --- | --- | --- | --- | --- | --- |
| **Project-Level RBAC & Robot Accounts** | High | ❌ None (Basic HTTP auth only) | ⚠️ Generic role mapping | ⚠️ Limited | ✅ Native robot accounts per project with TTL |
| **Tag Immutability Rules** | Critical | ❌ Overwrite allowed | ⚠️ Read-only repository flags | ❌ Paid tier | ✅ Native per-repo / per-tag regex immutability |
| **Automated Vulnerability Scanning** | High | ❌ None (requires external cron) | ❌ Commercial plugin required | ❌ Requires Xray (Commercial) | ✅ Built-in Trivy scanner with scan-on-push |
| **Scheduled Retention & GC** | High | ⚠️ Manual registry GC command | ✅ Scheduled tasks | ⚠️ Manual / limited | ✅ Dry-runnable tag retention & GC policies |
| **Artifact Signing (Cosign / Notation)** | Medium | ❌ None | ❌ None | ⚠️ Commercial | ✅ Native artifact signing & signature verification |
| **Operational Resource Footprint** | Medium | ✅ Very low (< 100MB RAM) | ⚠️ High (JVM 4GB+ RAM) | ⚠️ High (JVM 4GB+ RAM) | ⚠️ Moderate (~2GB RAM, multi-container) |
| **Audit Logging & Traceability** | High | ⚠️ Syslog only | ⚠️ General audit log | ⚠️ Limited | ✅ Comprehensive UI & API audit trail of pulls/pushes |

---

## 4. Key Architectural Findings

### 4.1 Immutability is Non-Negotiable
In the delivery blueprint, once an image `orders-api:1.4.2` is built and verified in `UAT`, it must be technically impossible for any user or automated process to overwrite that tag with different layer contents. Plain Docker Registry and Nexus OSS require complex reverse proxy filters or repository duplication to achieve this, whereas Harbor enforces tag immutability natively via regex rules.

### 4.2 Security Boundary & Re-scanning
Harbor executes Trivy scans on push and on a scheduled basis against stored images. When a new Zero-Day CVE is disclosed, Harbor identifies affected images already in the registry without requiring Jenkins to trigger builds.

### 4.3 Robot Accounts for Least Privilege
Jenkins pipelines require push access to `apps/*`, while runtime nodes (DEV, UAT, PROD) require pull-only access. Harbor's robot account model allows generating tokenized, non-interactive credentials scoped to specific actions with automated expiration.

---

## 5. Decision Support Recommendation

**Harbor is strongly recommended** as the centralized container registry. Its feature set addresses all core security, governance, and immutability requirements out of the box without custom reverse proxy scripting or commercial licensing dependencies.
