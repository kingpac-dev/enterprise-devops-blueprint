# Image Retention Policy

## Purpose

Defines how long container images are kept, what must never be deleted, and how retention relates to rollback capability.

## Scope

Retention rules and garbage collection in Harbor. Registry operation is in [harbor-standard.md](harbor-standard.md); identity is in [image-versioning.md](image-versioning.md).

## Audience

Platform engineers configuring retention, and anyone reasoning about how far back a rollback can reach.

## Status

**Draft for review.** All retention periods are undecided. The rollback-depth requirement below is the constraint that should determine them.

---

## 1. Retention Is a Reliability Control

Retention is usually treated as storage housekeeping. Here it is the setting that bounds recovery.

Rollback works by redeploying the previous known-good image. If that image has been evicted by a retention rule, the rollback fails — at the exact moment it is needed, having appeared configured and correct until then.

The failure mode is specific and worth stating plainly: a retention policy tuned for storage cost silently shortens the recovery window, and nobody discovers it until a bad release coincides with an image that aged out. Retention length must be derived from required rollback depth, not from disk pressure.

---

## 2. Never Delete

The following must be exempt from every retention rule:

| Artifact | Reason |
| --- | --- |
| Any image currently deployed to any environment | Deleting a running deployment's image breaks restart and rescheduling |
| The previous known-good image for each production service | It is the rollback target |
| Every image deployed to PROD, for the audit retention period | Required to answer what was running at a given time |

The second entry needs care: "previous known-good" is not necessarily the immediately preceding tag. If three releases failed verification in sequence, the last good image may be several versions back.

Recommendation: retain the last **N** production-deployed images per service, where N is large enough to cover the worst realistic sequence of failed releases. `TBD` — the value of N. A minimum of 5 is a reasonable starting point.

---

## 3. Retention by Class

| Class | Example tag | Proposed retention | Rationale |
| --- | --- | --- | --- |
| Production-deployed | `1.4.2-a82f912` | `TBD` — long; aligned with audit retention | Rollback target and audit evidence |
| Release candidate | `1.5.0-rc-b91c332` | `TBD` — medium | May still be promoted or need investigation |
| DEV build | `sha-c04d551` | `TBD` — short, or last N per service | Superseded quickly; high volume |
| Feature branch build | `TBD` | `TBD` — very short | Never deployed beyond verification |
| Untagged artifact | — | Delete after a short grace period | Almost always garbage; the grace period covers in-flight operations |

The grace period on untagged artifacts matters. An image pushed but not yet tagged, deleted immediately, breaks a pipeline mid-run.

---

## 4. Storage Growth

Retention length is bounded by storage. The relationship is worth quantifying before configuring anything:

```text
storage growth ≈ builds per day × average unique layer size × retention days
```

Two properties make naive estimates wrong in opposite directions.

Layers are shared, so total consumption is much less than the sum of image sizes — many images differ only in their application layer. But deleting an image frees only layers nothing else references, so reclaimed space is also much less than expected. Deleting 100 GB of images may return a few GB.

`TBD` — measured build volume, average image and layer size, allocated storage, and projected growth. These cannot be estimated meaningfully before the platform exists; they should be measured once it does, and the retention values in section 3 revisited then.

---

## 5. Garbage Collection

Deleting a tag removes a reference. Space is reclaimed only when garbage collection runs and removes unreferenced layers.

Operational constraints:

- Harbor may enter read-only mode during collection, blocking pushes and potentially pulls. It requires a maintenance window.
- Duration scales with registry size, so the first run after a long gap is the longest and most disruptive.
- Collection must not run during a release window.

`TBD` — garbage collection schedule and its coordination with release windows.

---

## 6. Scan Metadata and SBOMs

Deleting an image deletes its scan results, and with them the record of what that image contained.

This interacts with vulnerability response. When a vulnerability is disclosed against a component, answering "which of our production images contain it?" requires the SBOM for each candidate image. If SBOMs live only alongside the image in the registry, retention determines how far back that question can be answered.

Recommendation: store SBOMs independently of the registry, with their own retention aligned to audit requirements rather than to storage pressure. `TBD` — SBOM storage location and retention, in [07-security/](../07-security/).

---

## 7. Enforcement

Retention rules are configured per Harbor project and evaluated on a schedule. Two configuration properties are worth checking explicitly:

- Rules must be verified against the exemptions in section 2. A rule expressed as "keep the most recent 10" does not know which image is currently deployed.
- Harbor supports a dry run. Every rule change should be dry-run and its output reviewed before the rule is enabled, because the alternative is discovering the mistake as a failed rollback.

`TBD` — rule expression per project, evaluation schedule, and who reviews rule changes.

---

## 8. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — required rollback depth (N) per service | Every retention value |
| `TBD` — retention period per class | Storage, rollback, audit |
| `TBD` — audit retention requirement for production images | Long-term retention floor |
| `TBD` — measured storage growth and allocated capacity | Whether the policy is affordable |
| `TBD` — garbage collection schedule and window | Registry availability |
| `TBD` — SBOM storage independent of the registry | Vulnerability response capability |
| `TBD` — whether currently deployed images are automatically exempt | Rollback safety |

---

## Security Considerations

Retention has two competing security effects. Keeping images longer preserves audit evidence and the ability to investigate what was running when. Keeping them longer also retains images with known vulnerabilities, which remain pullable and deployable.

The resolution is not shorter retention. It is preventing the deployment of images that fail current policy, while retaining them for evidence — see the pull-blocking discussion in [harbor-standard.md](harbor-standard.md#5-vulnerability-scanning). Deleting evidence to reduce vulnerability count improves a metric and degrades the platform.

## Operational Considerations

The failure this policy exists to prevent is specific: a rollback that fails because the target image was evicted. It is silent until it happens, and it happens during an incident.

Two mitigations follow. Derive retention from rollback depth rather than from storage cost. And verify periodically that the previous known-good image for each production service is still present — a check cheap enough to automate, and one whose absence is only noticed at the worst possible time.

---

## Related

- [Harbor standard](harbor-standard.md)
- [Image versioning](image-versioning.md)
- [CI/CD standards](../05-ci-cd/)
- [Security standards](../07-security/)
- [Disaster recovery](../11-disaster-recovery/)
