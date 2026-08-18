# Backup Standard

## Purpose

Defines what is backed up, how often, where it is stored, how it is protected, and how a backup is verified.

## Scope

Platform components and the data required to rebuild delivery capability. Recovery procedures are in [disaster-recovery-plan.md](disaster-recovery-plan.md); proving that backups work is in [restore-testing.md](restore-testing.md).

## Audience

Platform engineers and whoever is accountable for recovery.

## Status

**Draft for review.** No backup is currently taken. RPO, RTO, frequencies, and retention are undecided.

---

## 1. The Only Thing That Matters

**A backup is not operationally reliable until a restore has been demonstrated.**

Until then, what exists is a job that reports success. That report says the job ran; it does not say the data is complete, consistent, readable, or sufficient to rebuild anything.

This standard therefore defines what to capture. Whether any of it works is established in [restore-testing.md](restore-testing.md), and until that has been done, recovery capability must be described as unproven.

---

## 2. Reproducible Versus Irreplaceable

Not everything needs backing up to the same degree, and the distinction determines where effort goes.

| Class | Meaning | Backup priority |
| --- | --- | --- |
| **Irreplaceable** | Cannot be recreated from any other source | Highest |
| **Reproducible-but-different** | Can be recreated, but the result is not identical | High |
| **Reproducible** | Can be recreated identically from source | Lower |

| Item | Class | Why |
| --- | --- | --- |
| Jenkins credentials | Irreplaceable | Secret values exist nowhere else |
| Harbor image storage | **Reproducible-but-different** | A rebuild produces a different artifact — see below |
| Deployment and audit records | Irreplaceable | The record of what happened |
| Harbor metadata database | Irreplaceable | Projects, robot accounts, tags, retention rules, scan history |
| SonarQube database | Irreplaceable in practice | Historical quality trend cannot be reconstructed |
| Jenkins job configuration | Reproducible, if pipelines are in Git | The `Jenkinsfile` is the source |
| Grafana dashboards | Reproducible, if provisioned as code | The JSON is the source |
| Prometheus historical metrics | Reproducible-but-different | Cannot be recreated; loss is bounded to lost history |
| Repository content | Reproducible | GitHub is authoritative; clones exist widely |

The Harbor row is the one that misleads. Images are reproducible from source in principle — but a rebuild yields a *different* artifact, which cannot serve as a rollback target for a byte-identical known-good version. Reproducibility is not a substitute for retention.

Everything reproducible depends on its source being version-controlled. That is a direct argument for pipelines, dashboards, and repository settings as code: it moves them out of the backup burden entirely.

---

## 3. Backup Scope

| Component | Contents | Frequency | Retention |
| --- | --- | --- | --- |
| Jenkins configuration | Controller config, job definitions, plugin list and versions | `TBD` | `TBD` |
| Jenkins credentials | Credential store **and its master key** — see section 4 | `TBD` | `TBD` |
| Jenkins build history | Execution records, gate verdicts | `TBD` | `TBD` |
| Harbor database | Projects, users, robot accounts, tags, retention rules, scan results | `TBD` | `TBD` |
| Harbor image storage | Image layers | `TBD` | `TBD` |
| SonarQube database | Projects, quality gates, history | `TBD` | `TBD` |
| Prometheus data | Metric history | `TBD` | `TBD` |
| Grafana | Dashboards, data sources, users | `TBD` | `TBD` |
| Loki data | Log history | `TBD` | `TBD` |
| Deployment configuration | Compose files, environment files | `TBD` | `TBD` |
| Application named volumes | Whatever durable state services hold | `TBD` | `TBD` |
| Deployment and change records | Audit evidence | `TBD` | `TBD` |
| Host configuration | OS config, Docker daemon config, firewall rules | `TBD` | `TBD` |

Two rows are frequently missed.

**Application named volumes.** Every named volume in production is a backup obligation, and volumes are added without anyone updating the backup scope. The mismatch surfaces during a recovery. See [docker-compose-standard.md](../06-container/docker-compose-standard.md#6-volumes).

**Host configuration.** Rebuilding a host from scratch is slower than restoring one, and the configuration that made it work is often nowhere but on the host.

---

## 4. Jenkins Credentials Need Care

Jenkins encrypts its credential store with a master key held separately. Two consequences follow, and they pull in opposite directions.

**Backing up the credential store without the master key produces an unrecoverable file.** The restore appears to succeed and every credential is unusable. This failure is only discovered by testing a restore that includes actually using a restored credential.

**Backing up both together makes the backup as sensitive as the entire platform.** It contains the credentials for every environment. Anyone who can read that backup can reach production.

| Requirement | Reason |
| --- | --- |
| Both are backed up | Otherwise the restore is useless |
| Backup storage is encrypted at rest | It holds every environment's credentials |
| Access to backup storage is restricted like production access | It confers production access |
| Access to backups is recorded | Reading a backup is reading the credentials |
| Restore testing includes **using** a restored credential | Verifies the key was captured |

The last is the only check that catches the failure mode.

---

## 5. Consistency

Some components store state in two places that must be restored consistently with each other.

| Component | Parts | If inconsistent |
| --- | --- | --- |
| Harbor | Database and image storage | References to layers that do not exist, or layers with no references |
| Jenkins | Configuration and credential store | Jobs referencing credential IDs that were not captured |
| Grafana | Dashboards and data source definitions | Dashboards querying data sources that do not exist |

Backups of related parts must be taken at a consistent point, or the recovery procedure must handle reconciliation explicitly.

`TBD` — whether backups are taken with the service quiesced, or from a consistent snapshot. Backing up a live database by copying its files usually produces a copy that will not open.

---

## 6. Where Backups Live

| Requirement | Reason |
| --- | --- |
| Not on the host being backed up | Host loss then takes the backup with it |
| Not reachable with the same credentials as the source | A compromise that reaches the source should not reach the backups |
| At least one copy off the primary infrastructure | A site or platform-level event should not take everything |
| Encrypted at rest | Backups contain credentials and production data |
| Immutable or delete-protected where supported | Deletion — accidental or malicious — is the failure backups exist to survive |

The second requirement is the one most often violated. Backups written by the same account that administers the source system are reachable by anyone who compromises that account, which removes the protection against the scenario most worth protecting against.

`TBD` — storage location, encryption, access model, and whether immutability is available.

---

## 7. Verification

Distinguish three different things, because they are routinely conflated:

| Check | Confirms | Sufficient? |
| --- | --- | --- |
| Backup job succeeded | The job ran | **No** |
| Backup file exists and is a plausible size | Something was written | No |
| Backup is readable and passes an integrity check | The file is not corrupt | No |
| **A restore produces a working system** | Recovery capability | **Yes** |

The first three are monitoring. Only the fourth is verification, and it belongs in [restore-testing.md](restore-testing.md).

A silently failing backup is worse than no backup, because it removes the awareness that would otherwise prompt a manual copy. Backup job failure must alert.

`TBD` — backup monitoring and alerting.

---

## 8. RPO and RTO

| Term | Question |
| --- | --- |
| **RPO** — recovery point objective | How much data may be lost? Sets backup frequency |
| **RTO** — recovery time objective | How long may recovery take? Sets the recovery method |

`TBD` — both, per component. The framework for deciding:

| Component | RPO driven by | RTO driven by |
| --- | --- | --- |
| Jenkins credentials | How often credentials change | How long delivery can be stopped |
| Harbor metadata | How often images are published | Deployment and rollback are both blocked while it is down |
| Harbor image storage | Publication rate | As above |
| SonarQube | Analysis rate; history is nice-to-have | Delivery can continue with a documented exception |
| Application volumes | Business data loss tolerance | Service outage tolerance |
| Deployment records | Change rate | Audit need, not urgent operationally |

Harbor deserves the tightest RTO of the platform components, because its absence blocks recovery as well as delivery — see [disaster-recovery-plan.md](disaster-recovery-plan.md).

Set these before designing the backup schedule. A frequency chosen first and an RPO written afterwards to match is not a requirement; it is a description.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — RPO and RTO per component | Every frequency and method below them |
| `TBD` — backup frequency and retention per component | Data loss exposure |
| `TBD` — backup storage location, encryption, and access model | Backup confidentiality and survivability |
| `TBD` — whether backup storage supports immutability | Protection against deletion |
| `TBD` — consistency method for database backups | Whether restores work at all |
| `TBD` — backup monitoring and failure alerting | Silent failure |
| `TBD` — application volume backup scope per service | Data loss |
| `TBD` — who owns backup operation | Whether it happens |

---

## Security Considerations

Backup storage holds credentials for every environment and whatever production data application volumes contain. It is therefore a production-equivalent asset and needs production-equivalent controls: encryption at rest, restricted and recorded access, and isolation from the credentials that administer the source systems.

The Jenkins master key case in section 4 is a genuine dilemma rather than an oversight. Capturing the key makes the backup recoverable and makes it a complete set of platform credentials. There is no configuration that avoids the trade-off, only controls that manage it.

## Operational Considerations

Backups have recurring cost and no immediate consequence for skipping, which places them in the category of work that quietly stops. Monitoring backup *failure* is what keeps that visible, and it is distinct from monitoring backup success — a job that stopped running reports neither.

The reproducible-versus-irreplaceable classification in section 2 is where effort should be concentrated. Moving pipelines, dashboards, and repository settings into version control removes them from the backup burden and improves reviewability at the same time.

---

## Related

- [Disaster recovery plan](disaster-recovery-plan.md)
- [Restore testing](restore-testing.md)
- [Harbor standard](../06-container/harbor-standard.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
- [Audit evidence](../10-governance/audit-evidence.md)
- [Risk register](../00-executive/risk-register.md)
