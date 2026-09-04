# Environment Identifiers Standard

## 1. Purpose

Establishes the canonical environment model, names, boundaries, and promotion criteria across the enterprise software delivery lifecycle.

## 2. Canonical Environment Identifiers

The organization recognizes exactly three baseline runtime environments:

| Identifier | Full Name | Lifecycle Stage | Deployment Trigger |
| --- | --- | --- | --- |
| **`DEV`** | Development | Feature integration & component testing | Automated on merge to `develop` |
| **`UAT`** | User Acceptance Testing / Staging | Quality assurance, smoke tests & business sign-off | Automated on branch `release/*` |
| **`PROD`** | Production | Customer-facing live operational environment | **Manual Approval Required** |

---

## 3. Environment Specifications & Boundaries

| Attribute | `DEV` | `UAT` | `PROD` |
| --- | --- | --- | --- |
| **Audience** | Developers, Automated Tests | QA Engineers, Product Owners, Security | End users, Customers |
| **Data Policy** | **Strictly Synthetic / Mock Data**. No real PII. | Anonymized / Masked data subset | Authoritative live production data |
| **Secrets Boundary** | DEV-only credentials; grants zero access elsewhere | Isolated staging credentials | Vault / Protected Jenkins secrets with audit trail |
| **Resource Limits** | Relaxed (Diagnosability prioritised) | Strict (Mirrors production capacity) | **Enforced CPU/RAM limits & reservations** |
| **Logging Level** | `Debug` / `Trace` allowed | `Information` | `Warning` / `Error` (Strictly no secrets or PII) |
| **Artifact Used** | Built once in CI, pushed to Harbor | **Same immutable container promoted from DEV** | **Same immutable container validated in UAT** |
| **Rollback Requirement** | Re-deploy or fix-forward | Manual or automated rollback | **Automated rollback pre-configured** |

---

## 4. Key Architectural Rules

### 4.1 Build Once, Promote Everywhere
Binaries and container images must **never** be rebuilt between environments. The exact SHA-256 digest validated in UAT is what gets promoted to PROD.

### 4.2 Configuration Lives in Environment
All environmental differences (database connection strings, logging verbosity, external API endpoints) must be supplied via runtime environment variables or protected `.env` files, never baked into the container image.

### 4.3 Production Network Isolation
Production runtime networks must **never** bridge or accept incoming connections from DEV or UAT networks. Cross-environment database connections are prohibited by firewall policy.
