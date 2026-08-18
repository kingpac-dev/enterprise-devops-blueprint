# Harbor Standard

## Purpose

Defines how Harbor is organized and operated as the centralized container registry: project structure, access model, immutability, scanning, promotion, and storage management.

## Scope

Registry configuration and operation. Image identity is in [image-versioning.md](image-versioning.md); retention rules are in [image-retention-policy.md](image-retention-policy.md).

## Audience

Platform engineers operating Harbor, and application teams consuming it.

## Status

**Draft for review.** Harbor is not yet deployed. Project naming, the promotion model, and the access model are undecided.

---

## 1. Why Harbor Matters More Than It Appears To

Harbor holds the only copy of every deployable artifact. Two consequences follow, and both are load-bearing.

**It is a single point of failure for deployment *and* rollback.** Both pull from the same registry. A bad release coinciding with a Harbor outage has no clean recovery path — the recovery mechanism shares its dependency with the failure. See [logical-architecture.md](../01-architecture/logical-architecture.md#6-failure-isolation).

**It is the highest-value supply-chain target in the platform.** An attacker who can replace an image in Harbor puts arbitrary code into production through a legitimate deployment, with a valid audit trail. No other component offers that.

Access control and immutability are therefore primary controls here, not configuration preferences.

---

## 2. Project Structure

Harbor organizes images into projects, which are the unit of access control, retention, and immutability. Project boundaries are consequently a security decision, not an organizational convenience.

Candidate models:

| Model | Structure | Trade-off |
| --- | --- | --- |
| Per team | `team-a/my-api`, `team-a/my-worker` | Simple; access is per team, so all of a team's images share one permission set |
| Per application | `my-api/api`, `my-api/worker` | Fine-grained access; more projects to administer |
| Per environment | `dev/my-api`, `prod/my-api` | Strong environment separation, but promotion copies images, which changes their identity |

The per-environment model conflicts with the promotion rule in [image-versioning.md](image-versioning.md#7-promotion-does-not-change-the-identifier): copying an image between projects gives the same content a new identifier, so "what UAT verified" and "what production runs" become two references requiring a mapping.

Recommendation: per team or per application, with environment separation enforced by **access control** rather than by copying. `TBD` — the chosen model and naming convention.

---

## 3. Access Model

Harbor robot accounts, not personal accounts, are used by automation. Each is scoped to the minimum required.

| Consumer | Permission | Scope |
| --- | --- | --- |
| Jenkins | push, pull | The projects it builds for |
| DEV host | **pull only** | DEV-eligible images |
| UAT host | **pull only** | UAT-eligible images |
| PROD host | **pull only** | PROD-eligible images |
| Developers | pull | Their team's projects |
| Platform team | administer | All |

Runtime hosts get pull-only credentials, with no exception. A production host has no reason to publish an image, and a compromised host that can push is not a host compromise — it is a supply-chain compromise, because everything that pulls from that registry afterwards is affected.

Separate credentials per environment. A single pull credential shared across DEV, UAT, and PROD collapses the secret boundary described in [logical-architecture.md](../01-architecture/logical-architecture.md#3-boundaries).

`TBD` — robot account naming, credential lifetime, and rotation frequency. Harbor robot accounts can be issued with an expiry; a credential that never expires is a credential nobody ever revisits.

---

## 4. Immutability

Tag immutability rules must prevent an existing tag from being repointed to different content.

Without this, a tag is a convention rather than a guarantee, and the traceability chain rests on nobody making a mistake. With it, an attempt to overwrite fails at the registry.

Immutability should apply at minimum to any tag that has been deployed to UAT or PROD. Applying it to all published tags is simpler to reason about and simpler to configure.

`TBD` — the immutability rule pattern per project, and whether it applies to all tags or only release tags.

---

## 5. Vulnerability Scanning

Harbor scans images on push and stores the results as artifact metadata. This complements the Trivy scan in the pipeline; it does not replace it.

The two serve different purposes:

| Scan | When | Answers |
| --- | --- | --- |
| Pipeline scan | Before publication | Should this image be published at all? |
| Registry scan | On push, and re-run later | Is a *previously published* image now known to be vulnerable? |

The second is the one that matters over time. An image scanned clean at build time does not stay clean — vulnerabilities are disclosed against components that were already there. Re-scanning stored images is how that is detected, and it is the reason to keep an SBOM alongside the image.

Harbor can block the pulling of images above a severity threshold. That is a strong control and a dangerous one: it can also block a rollback to a previously good image that has since acquired a finding, at the moment the rollback is needed.

`TBD` — whether pull-blocking is enabled, and if so how an emergency rollback bypasses it. Recommendation: enable it for new deployments, with a documented and audited emergency path.

---

## 6. Storage and Garbage Collection

Registry storage grows continuously and does not shrink on its own. Deleting a tag does not reclaim space; it removes a reference. Space is reclaimed only by garbage collection, which removes layers no longer referenced by any artifact.

Two operational facts to plan around:

- Harbor may enter read-only mode during garbage collection, which blocks pushes and can block pulls. It is a maintenance window, not a background task.
- Layers shared between images are only reclaimed once nothing references them. Actual space recovered is routinely far less than the size of what was deleted.

Storage exhaustion on the registry stops builds from publishing and, depending on configuration, deployments from pulling. It is a platform-wide outage originating in a disk that filled slowly and predictably.

`TBD` — storage capacity, growth projection, alert threshold, and garbage collection schedule.

---

## 7. Backup

Harbor holds two things that must be recovered separately:

| Component | Contains | If lost |
| --- | --- | --- |
| Database | Projects, users, robot accounts, tags, scan results, retention rules | Configuration and metadata lost; images may exist but be unreferenced |
| Storage backend | Image layers | Every artifact lost, including every rollback target |

They must be backed up consistently with each other. A database restored to a different point in time than the storage backend produces references to layers that do not exist, or layers with no references.

Whether image storage needs a full backup is a genuine decision. Images are reproducible from source in principle — but a rebuild produces a *different* artifact, which cannot be used to roll back to a byte-identical known-good version. Reproducibility is not a substitute for retention.

`TBD` — backup scope, frequency, and whether image storage is backed up or accepted as a rebuild-from-source risk. Recorded in [11-disaster-recovery/](../11-disaster-recovery/).

---

## 8. Operational Requirements

| Requirement | Detail |
| --- | --- |
| TLS | Required. Registry credentials cross this connection on every push and pull |
| Availability monitoring | Harbor unavailable blocks deployment and rollback; it must alert |
| Storage monitoring | Alert well before exhaustion, with enough margin to run garbage collection |
| Audit logging | Push, pull, delete, and permission changes retained |
| Upgrade process | Documented, with database backup taken first |

`TBD` — Harbor URL, network placement, TLS certificate management, and audit log retention.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — project structure and naming convention | Access control granularity |
| `TBD` — promotion model: same project or copy between projects | Whether image identity survives promotion |
| `TBD` — robot account naming, lifetime, and rotation | Credential hygiene |
| `TBD` — immutability rule scope | Whether tags are guaranteed or merely conventional |
| `TBD` — pull-blocking on severity, and the emergency rollback path | Rollback reliability |
| `TBD` — storage capacity, growth model, and GC schedule | Platform availability |
| `TBD` — backup scope for database and image storage | Recovery capability |
| `TBD` — Harbor URL and network placement | Network architecture, firewall matrix |

---

## Security Considerations

The two controls that matter most are pull-only credentials on runtime hosts and enforced tag immutability. Together they mean that compromising a runtime host does not let an attacker poison the registry, and that no path exists to silently change what a deployed identifier refers to.

Robot account expiry is worth setting deliberately. Non-expiring automation credentials accumulate, outlive the systems that used them, and are rarely revoked because nobody is certain what would break.

Harbor's audit log is one of the few places where "who published this artifact" is recorded. Its retention period should match the period over which a supply-chain question might be asked, which is longer than most default settings.

## Operational Considerations

Harbor unavailable is worse than Jenkins unavailable: it stops deployment *and* rollback. Its availability monitoring and recovery procedure deserve priority over most other platform components.

Garbage collection needs a scheduled window. Deferring it because it requires a maintenance window is how registries reach full disks — the deferral is invisible until the day the disk fills, which is also the day nothing can be published or deployed.

---

## Related

- [Image versioning](image-versioning.md)
- [Image retention policy](image-retention-policy.md)
- [Logical architecture](../01-architecture/logical-architecture.md)
- [Service interaction](../01-architecture/service-interaction.md)
- [Security standards](../07-security/)
- [Disaster recovery](../11-disaster-recovery/)
