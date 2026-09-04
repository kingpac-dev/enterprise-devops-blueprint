# HashiCorp Vault Integration Guide

## Purpose

Defines the architecture, authentication workflows, and migration roadmap for integrating **HashiCorp Vault** into the Enterprise DevOps Platform.

Per [AGENTS.md](../../../AGENTS.md) Sections 1, 11, and 21, the baseline platform starts with Jenkins Credentials and protected `.env` files. This guide defines how and when the organization transitions to centralized dynamic secrets management as operational scale demands.

---

## 1. When to Adopt Vault

As defined in [devops-roadmap.md](../../../docs/00-executive/devops-roadmap.md), Vault is adopted when:

1. Secret count and rotation frequency exceed the manual capacity of Jenkins Credentials and host `.env` files.
2. Ephemeral, short-lived credentials (e.g., dynamic database users with 1-hour TTL) become a compliance requirement.
3. Centralized secret access auditing (who accessed which credential and when) is mandated by internal or external security policy.

---

## 2. Integration Architecture

```mermaid
flowchart TD
    subgraph CI_CD ["CI/CD Pipeline (Jenkins)"]
        J[Jenkins Master / Agent]
        VP[HashiCorp Vault Plugin]
        J --> VP
    end

    subgraph VAULT_SRV ["Central Secret Management"]
        V[HashiCorp Vault Cluster]
        KV[KV v2 Engine\n(Static Secrets)]
        DBE[Database Secrets Engine\n(Dynamic DB Users)]
        APPR[AppRole Auth Engine]
        V --> KV
        V --> DBE
        V --> APPR
    end

    subgraph RUNTIME ["Runtime Host (Portainer / Compose)"]
        VA[Vault Agent Sidecar]
        APP[Application Container]
        ENV[Protected .env.runtime\nchmod 0600]
        VA -->|Renders & Rotates| ENV
        ENV -->|Injected into| APP
    end

    VP -->|AppRole Auth & Fetches Secrets| V
    VA -->|AppRole Auth & Auto-Renew Leases| V
```

---

## 3. Jenkins CI/CD Integration

### 3.1 Authentication via AppRole
Jenkins authenticates to Vault using a scoped AppRole:
- `role_id`: Non-sensitive identifier configured in Jenkins System Settings.
- `secret_id`: Sensitive token stored as a Jenkins Secret Text credential, restricted to the platform engineering administration folder.

### 3.2 Declarative Pipeline Usage
Pipelines consume secrets using the `withVault` step provided by the **HashiCorp Vault Plugin**:

```groovy
stage('Deploy with Vault Credentials') {
    steps {
        withVault(vaultSecrets: [
            [
                path: 'secret/data/production/harbor',
                engineVersion: 2,
                secretValues: [
                    [envVar: 'HARBOR_USER', vaultKey: 'username'],
                    [envVar: 'HARBOR_TOKEN', vaultKey: 'token']
                ]
            ],
            [
                path: 'database/creds/prod-db-migrator',
                secretValues: [
                    [envVar: 'DB_USER', vaultKey: 'username'],
                    [envVar: 'DB_PASS', vaultKey: 'password']
                ]
            ]
        ]) {
            // Credentials are masked in Jenkins console logs automatically
            sh 'echo "Deploying with ephemeral database credentials..."'
            sh './scripts/run-migrations.sh'
        }
    }
}
```

---

## 4. Runtime Host & Container Secrets (Vault Agent)

For long-running application containers running under Docker Compose or Portainer:

1. **Vault Agent** runs on the host or as a sidecar container alongside the application stack.
2. The agent uses configuration from [`vault-agent-config.example.hcl`](vault-agent-config.example.hcl).
3. Secrets are read from Vault and written to an in-memory or protected volume (`/opt/app/config/.env.runtime`, mode `0600`).
4. When a secret rotates or a database lease expires, Vault Agent automatically:
   - Fetches new credentials.
   - Re-renders `.env.runtime`.
   - Executes an `exec` hook (e.g. `docker kill -s HUP <container_name>` or triggers application configuration reload endpoint).

---

## 5. Security Principles

1. **Least Privilege**: Each application and pipeline possesses its own Vault policy allowing read-only access to its exact secret path.
2. **Short TTLs**: Dynamic database credentials should default to a 1-hour lease with a maximum 4-hour renewal ceiling.
3. **Zero Secrets in Git**: Neither `role_id` nor `secret_id` are committed to source control.
4. **Audit Logging**: All Vault requests must log to centralized Loki or syslog with sensitive payload values redacted.

---

## Related Documents

- [Secrets Management](../../../docs/07-security/secrets-management.md)
- [Security Baseline](../../../docs/07-security/security-baseline.md)
- [Architecture Decisions: Runtime Platform](../../../architecture/decisions/adr-0005-runtime-platform-options.md)
- [Vault Agent Configuration](vault-agent-config.example.hcl)
