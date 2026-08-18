# ADR-0002 — Use Harbor as Container Registry

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established. Alternatives were assessed analytically against stated constraints, not through proofs of concept.

---

## Context

The delivery model requires a registry that stores the single artifact promoted across DEV, UAT, and PROD. That registry is not merely storage — it is the boundary between "built" and "deployable", and the source every rollback pulls from.

Requirements:

- Self-hosted, inside the controlled network
- Per-project access control, with distinct credentials per environment
- **Tag immutability**, so an identifier cannot later refer to different content
- Retention policy with garbage collection
- Vulnerability scanning of stored images, and re-scanning as new vulnerabilities are disclosed
- Audit logging of publication and retrieval
- A path toward image signing

---

## Decision

Harbor is the centralized container registry.

In practice:

- Every deployable image is published to Harbor and pulled from it by every environment.
- Projects are the unit of access control, retention, and immutability.
- Jenkins holds push credentials; runtime hosts hold **pull-only** credentials, distinct per environment.
- Tag immutability rules prevent an existing tag being repointed.
- Retention is derived from required rollback depth, not from storage cost.

---

## Consequences

### Positive

- Access control, immutability, retention, scanning, and audit logging in one component rather than assembled from parts.
- Self-hosted, so artifacts and their metadata stay inside the controlled network.
- Scanning on push, plus re-scanning of stored images, which is how a newly disclosed vulnerability becomes a finding against images already published.
- Replication and signing support exist if later required.

### Negative

- **Single point of failure for deployment and rollback.** Both pull from Harbor, so the recovery path shares a dependency with the failure path. A bad release during a Harbor outage has no clean way back. See risk R-02
- **Storage grows continuously.** Deleting a tag reclaims nothing; only garbage collection does, and it recovers far less than the size of what was deleted because layers are shared.
- **Garbage collection needs a maintenance window.** Harbor may become read-only during it, blocking publication.
- **Operational burden.** A database and an object store, both requiring backup, and requiring restoration consistent with each other.
- More components than a plain registry: database, job service, scanner, and web interface.

### Neutral

- Harbor uses Trivy as its default scanner, so [ADR-0004](0004-use-trivy-for-container-security.md) and this decision overlap. Pipeline scanning and registry scanning remain complementary — one gates publication, the other detects later disclosures.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Docker Registry (`registry:2`)** | Simplest and lightest. Rejected because it provides no access control model, no immutability rules, no retention policy, no scanning, and no audit log — every requirement above would need assembling separately |
| Nexus Repository, Artifactory | Capable, and broader: they handle NuGet and npm as well as containers, which would consolidate artifact management. Rejected as heavier to operate for the immediate need, and Artifactory's container features are largely commercial. **This is the alternative most worth revisiting** if a package proxy is later adopted |
| GitHub Container Registry | Artifacts and their metadata leave the controlled network, and deployment gains a dependency on an external service |
| Cloud provider registries | Same external dependency, plus egress cost and a cloud relationship not otherwise required |
| Harbor plus a separate scanner | Harbor's integrated scanning already satisfies the need; adding a second increases operational surface without adding capability |

---

## Security Considerations

Harbor is the highest-value supply-chain target in the platform. An attacker able to replace an image puts arbitrary code into production through an entirely legitimate deployment — passing health checks, producing an accurate audit record naming a real approver. No downstream control detects it.

Two controls carry that weight: **pull-only credentials on runtime hosts**, without exception, and **enforced tag immutability**. A runtime host that can push turns a host compromise into a supply-chain compromise. A mutable tag means the identifier in every historical deployment record can be made to mean something else.

Image signing verified at the deployment target would move the guarantee out of Harbor entirely. It is deferred to Phase 3 — see [ADR-0007](0007-use-immutable-container-versioning.md) and [container-image-signing.md](../docs/07-security/container-image-signing.md).

Robot account expiry should be set. Non-expiring automation credentials accumulate and are never revoked, because nobody is certain what would break.

## Operational Considerations

Harbor unavailable is worse than Jenkins unavailable: it stops deployment **and** rollback. Its availability monitoring and recovery procedure deserve priority over the other platform components, and its RTO should be the tightest of them.

Storage capacity, growth projection, and a scheduled garbage collection window are required before production use. Deferring garbage collection because it needs a window is how registries reach full disks — the deferral is invisible until the day nothing can be published.

Database and image storage must be backed up consistently with each other. Restored at different points in time, they produce references to layers that do not exist.

A host-local image cache would decouple rollback from registry availability. It is not currently designed and is the cheapest available mitigation for the platform's worst case.

---

## Review Trigger

Revisit if:

- A package proxy for NuGet or npm becomes necessary, making a unified artifact repository attractive.
- Harbor operational burden — storage, garbage collection windows, upgrades — exceeds the value of its integrated features.
- Registry downtime becomes materially expensive, making replication or high availability worth its cost.
- Kubernetes adoption changes the registry integration requirements.

---

## References

- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Image retention policy](../docs/06-container/image-retention-policy.md)
- [Software supply-chain security](../docs/07-security/software-supply-chain-security.md)
- [Risk register](../docs/00-executive/risk-register.md)
