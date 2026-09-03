# Database Standard

## Purpose

Defines how application databases are hosted, connected to, protected, and recovered.

## Scope

PostgreSQL as the application database platform. Schema change is in [database-migration-standard.md](../05-ci-cd/database-migration-standard.md); platform component databases — Harbor, SonarQube — are covered by their own runbooks.

## Audience

Platform engineers, developers, and whoever is accountable for the data.

## Status

**Draft for review.** PostgreSQL on a dedicated host is in use. Version, sizing, backup, and monitoring are undecided.

> **No real hostnames, addresses, ports, or credentials appear in this repository.** They carry reconnaissance value and this repository is more widely readable than the systems it describes. See [SECURITY.md](../../SECURITY.md).

---

## 1. The Database Is Not a Container

PostgreSQL runs on a **dedicated host**, not as a container in the application stack.

That is the right decision and its consequences are worth stating, because several of this blueprint's models stop applying at the database boundary.

| Property | Application containers | Database |
| --- | --- | --- |
| Lifecycle | Replaced on every deployment | **Persists across every deployment** |
| Rollback | Redeploy the previous image | **No image to roll back to** |
| State | Discarded with the container | **The state that matters** |
| Recovery | Redeploy from Harbor | **Restore from backup, losing whatever came after** |
| Governed by | This blueprint's promotion model | Change management, and this document |

**The blueprint's core recovery mechanism — redeploy the previous immutable image — does not reach the database.** Everything about rollback safety follows from that, and it is why [database-migration-standard.md](../05-ci-cd/database-migration-standard.md) exists as a separate standard rather than a paragraph.

### Why not a container

`TBD` — record as an ADR if the decision is to be revisited. The reasons that make a dedicated host correct here:

- Its lifecycle is independent of deployments, which is what durable state requires
- Backup, restore, and point-in-time recovery are host-level operations
- Resource contention with application containers is avoided
- Compose has no orchestration, so a database container gains none of the availability benefits it would have under an orchestrator, while inheriting all of the host-fate coupling

A database container is appropriate for **local development only**.

---

## 2. Instances and Environments

| Environment | Instance | Requirement |
| --- | --- | --- |
| DEV | `TBD` | Separate database, synthetic or anonymized data |
| UAT | `TBD` | Separate database, representative but not production data |
| PROD | `TBD` | Production |

**Separation is required.** Whether that means separate hosts, separate instances, or separate databases on one instance is `TBD` — but a single database shared across environments is not acceptable, and a DEV connection string must not authenticate against production.

### Production data must not be copied downward

Production data appearing in DEV or UAT arrives through defect investigation, performance testing, and migration rehearsals — each with a plausible justification.

Where realistic data is genuinely required it is **anonymized before it leaves production**. Anonymizing inside UAT means the raw data was already there.

`TBD` — the anonymization approach, and the approval path for any exception. See [10-governance/](../10-governance/).

---

## 3. Credentials

**One credential set per environment. This has no exceptions.**

| Requirement | Reason |
| --- | --- |
| Distinct credentials per environment | A DEV compromise must not authenticate against production |
| Least privilege per application | The application account owns its schema and nothing else |
| **Separate migration account** | See below |
| No shared account between services | An incident in one service is contained to its data |
| Stored per [ADR-0010](../../adr/0010-portainer-gitops-deployment.md) | **Portainer environment variables**, never the deployment repository |

### The application account should not be able to alter the schema

The account the running application uses needs `SELECT`, `INSERT`, `UPDATE`, `DELETE` — not `CREATE`, `ALTER`, or `DROP`.

A separate account performs migrations, and only the migration step holds it.

This costs a little setup and removes a whole class of incident: an application defect, or a successful SQL injection, cannot drop a table it has no permission to drop. It also makes "who changed the schema" answerable, because only one path can.

`TBD` — role and grant definitions per environment.

---

## 4. Connections

| Requirement | Note |
| --- | --- |
| **TLS** | Credentials and data cross this connection continuously |
| Certificate verification enabled | `sslmode=verify-full` where practical. `require` alone encrypts without authenticating the server |
| Connection pooling | Sized deliberately — see below |
| Statement timeout | A query with no timeout can hold a connection indefinitely |
| Network reachable only from application hosts | See [firewall-and-port-matrix.md](../03-network/firewall-and-port-matrix.md) |

### Pool sizing is a shared-resource problem

Each application instance holds its own pool. PostgreSQL's connection limit is per **server**, and it is reached by the sum across every instance of every service.

```text
total connections ≈ services × instances per service × pool size
```

Exceeding it does not degrade gracefully: new connections are refused, and the symptom appears in whichever service happened to connect next — not the one that consumed them.

`TBD` — `max_connections`, per-service pool sizes, and whether a connection pooler such as PgBouncer is introduced. The pooler question becomes pressing as service count grows, and it is easier to introduce before applications are tuned around direct connections.

---

## 5. Backup — Now the Most Important Backup in the System

Container images are reproducible from source, if imperfectly. **Application data is not reproducible from anything.**

That makes the database backup the one whose loss is unrecoverable, and it currently does not exist — [backup-standard.md](../11-disaster-recovery/backup-standard.md) covers platform components only.

| Requirement | `TBD` |
| --- | --- |
| Full backup frequency | |
| **Point-in-time recovery** — WAL archiving | Recommended. Without it, recovery granularity is the last full backup |
| Retention | |
| Storage: off the database host, encrypted | |
| **Restore tested** | See below |
| Backup before every destructive migration | Required — see [database-migration-standard.md](../05-ci-cd/database-migration-standard.md) |

**Point-in-time recovery matters more here than anywhere else in the platform.** The realistic database disaster is not a lost host; it is a migration or a defect that corrupted data at a known moment. Without WAL archiving the only option is restoring the last full backup and losing everything since. With it, recovery targets the moment before the damage.

### A database backup is unproven until restored

The same standard applied everywhere else in this repository. Restore into an **isolated** target, and verify functionally — the application starts against it and reads its data. See [sop/restore-test.md](../../sop/restore-test.md).

A database backup taken by copying files from a running server usually produces a copy that will not open. `TBD` — confirm the method produces a consistent backup.

---

## 6. Monitoring

`TBD` — thresholds. The signals that matter:

| Signal | Why |
| --- | --- |
| **Connection count against the limit** | Exhaustion refuses new connections and the symptom appears elsewhere |
| **Disk usage and growth** | A full database disk stops writes; recovery is slower than for an application host |
| Replication lag | If replication exists |
| Long-running queries and locks | A lock held during a migration blocks the application |
| Transaction age | Long-lived transactions prevent vacuum and cause bloat |
| Cache hit ratio | Sizing signal |
| **Backup success and age** | A silently failed backup is worse than none — it removes the awareness that would prompt a manual copy |
| **Restore test recency** | Recovery capability is unproven without it |

`TBD` — `postgres_exporter` for Prometheus, and its scrape configuration in [templates/monitoring/](../../templates/monitoring/).

The database is outside the container monitoring already configured, so it needs its own scrape target and its own alerts. Without them the platform monitors everything except the component whose failure is least recoverable.

---

## 7. Data Classification

`TBD` — this is an organizational question, and it changes the requirements above.

| Question | Affects |
| --- | --- |
| Does the database hold personal data? | Retention limits, access control, log redaction, anonymization for lower environments |
| Any regulated data? | Backup retention, encryption, audit requirements |
| What is the retention obligation, and the retention **limit**? | Both directions matter — data kept longer than its purpose justifies is a liability |

Until this is answered, the requirements in sections 2, 3, and 5 are being set without knowing what they protect.

---

## 8. Access

Direct database access follows the tier model in [production-access-policy.md](../10-governance/production-access-policy.md), and it is **not** granted by holding tier 4 on an application host.

| Access | Tier |
| --- | --- |
| Read via the application | Not database access |
| Read-only query access to production | `TBD` — restricted, recorded |
| Write access to production | `TBD` — restricted, and a change under change control |
| Schema change | Migration path only — see [database-migration-standard.md](../05-ci-cd/database-migration-standard.md) |

**Reading production data is a data-protection matter, not merely a technical permission.** A production access policy that grants host access without addressing data access has left the more consequential of the two undecided.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — PostgreSQL version and upgrade path | Everything |
| `TBD` — environment separation: hosts, instances, or databases | Isolation |
| `TBD` — role and grant model, including the separate migration account | Section 3 |
| `TBD` — TLS mode and certificate management | Connection security |
| `TBD` — `max_connections`, pool sizes, and whether a pooler is used | Availability under load |
| `TBD` — **backup method, frequency, retention, and WAL archiving** | Recoverability |
| `TBD` — **restore test schedule** | Whether recovery is proven |
| `TBD` — `postgres_exporter` and alert thresholds | Detection |
| `TBD` — **data classification** | Sections 2, 3, 5, and 8 |
| `TBD` — anonymization approach for lower environments | Section 2 |
| `TBD` — sizing and growth forecast | Capacity |

---

## Security Considerations

The separate migration account in section 3 is the control with the best return here. It costs a grant statement and removes the possibility that an application defect or an injection flaw alters the schema.

Credential separation per environment is the other. DEV has the widest access and the weakest controls, which makes a shared credential the fastest route from a low-value compromise to a production one.

Backup storage now holds the organization's application data. It needs encryption at rest, restricted and recorded access, and isolation from the credentials that administer the database — a backup reachable with the same account that administers the source is not protection against the scenario most worth protecting against.

## Operational Considerations

This is the component whose loss is least recoverable and whose backup does not yet exist. Ranked against the [risk register](../00-executive/risk-register.md), it belongs alongside R-30 rather than below it.

Connection exhaustion is the failure most likely to appear first, and it is confusing when it does: the service that fails is not the one that consumed the connections.

---

## Related

- [Database migration standard](../05-ci-cd/database-migration-standard.md)
- [Backup standard](../11-disaster-recovery/backup-standard.md)
- [Restore test](../../sop/restore-test.md)
- [Rollback strategy](../05-ci-cd/rollback-strategy.md)
- [Production access policy](../10-governance/production-access-policy.md)
- [ADR-0010 — Portainer GitOps deployment](../../adr/0010-portainer-gitops-deployment.md)
