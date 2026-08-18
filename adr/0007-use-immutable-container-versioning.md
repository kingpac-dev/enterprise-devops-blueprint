# ADR-0007 — Use Immutable Container Versioning

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established.

---

## Context

Two questions must have precise answers at any moment:

- Given a running container, which commit produced it?
- Given a commit, where is it running?

Neither is answerable if an image identifier can refer to different content at different times. A mutable identifier does not merely leave records incomplete — it makes records **written before the change** wrong, silently, including the deployment records for artifacts already in production.

This also underpins the promotion model. UAT verification is evidence about production only if production runs the artifact UAT verified, which requires the identifier connecting them to be stable.

---

## Decision

Every deployable artifact carries an immutable, traceable identifier that resolves to exactly one build, permanently.

| Rule | |
| --- | --- |
| Tag format | `<version>-<commit>`, for example `1.4.2-a82f912`. `sha-<commit>` for non-release builds |
| `latest` | Never the production deployment identifier |
| Retagging | Prohibited. An existing tag is never repointed |
| Enforcement | Harbor tag immutability rules, not convention |
| Promotion | Does not change the identifier. The same image is deployed to each environment |
| Rebuilding | Production artifacts are never rebuilt separately from what lower environments verified |

Images additionally carry OCI labels recording commit, version, build time, and source, so a running container is self-describing without access to the pipeline.

---

## Consequences

### Positive

- "What is in production?" has a precise answer, resolvable to a commit.
- Rollback targets are known, specific artifacts rather than rebuilt approximations.
- Deployment records remain accurate indefinitely, because what they reference cannot change.
- Environment-specific build failures disappear, since only one build exists.
- Audit and incident questions are answerable from records rather than recollection.

### Negative

- **Retention becomes a reliability control.** If the previous known-good image is evicted, rollback fails at the moment it is needed — having appeared configured and correct until then. Retention must be derived from required rollback depth, not from storage cost. See risk R-17.
- **Storage grows** with every published build.
- **No convenient repush.** Fixing a broken image means a new version, which is correct and occasionally inconvenient.
- **Discipline is required at the edges.** A hotfix deployed manually with an ad hoc tag defeats the scheme for that release — and that release is the one most likely to be examined later.
- Environment values cannot be compiled in, which for Angular requires a runtime configuration mechanism rather than a build-time substitution.

### Neutral

- Tags remain pointers even when immutability is enforced; only the digest is content-addressed. Recording the digest in the deployment record makes the record independent of that enforcement, at the cost of readability. `TBD` — whether production deploys by tag or digest.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **`latest` or rolling tags** | Simple and convenient. Rejected outright: no deterministic answer to what is running, no reliable rollback target, and deployment records that reference nothing specific |
| Branch-named tags (`develop`, `release`) | Mutable by design. Same failure as `latest`, with the added illusion of specificity |
| Digest-only references | Strongest immutability guarantee — content-addressed and independent of registry configuration. Rejected as the primary scheme because digests are unreadable, which makes release conversations and runbooks worse. The chosen compromise records the digest alongside the readable tag |
| Version-only tags (`1.4.2`) | Acceptable, and loses the commit link. Including the commit answers both questions in the Context without a lookup |
| Build-number tags | Traceable to a pipeline execution but not to source, and build numbers reset when a job is recreated |

---

## Security Considerations

Tag immutability is a supply-chain control, not a naming convention. An attacker able to repoint a tag puts arbitrary code into production through an entirely legitimate deployment, producing a valid audit trail. This is the same threat as artifact substitution in [ADR-0002](0002-use-harbor-as-container-registry.md), reached through a different route.

Enforcement must be at the registry. A prohibition that depends on nobody making a mistake is not a control.

Image signing verified at the deployment target would make artifact identity verifiable independently of the registry. It is deferred to Phase 3.

## Operational Considerations

The scheme's weakest point is retention. It is configured for storage reasons by people who are not thinking about rollback, and the consequence is invisible until a rollback is attempted. Two mitigations: derive retention from rollback depth, and periodically verify that each production service's previous known-good image still exists — a cheap automated check whose absence is only noticed at the worst time.

The second weak point is the exception path. Manual hotfixes and out-of-band deployments defeat the scheme locally, which is why manual changes require records and a follow-up into the pipeline.

---

## Review Trigger

Revisit if:

- Storage cost from retention becomes disproportionate, which would prompt reconsidering retention depth rather than immutability.
- Digest-based deployment becomes practical to operate, making the readable tag redundant for deployment purposes.
- Image signing is adopted, which may change what the identifier needs to carry.

Immutability itself should not be revisited. Its removal invalidates the traceability chain retroactively.

---

## References

- [Image versioning](../docs/06-container/image-versioning.md)
- [Image retention policy](../docs/06-container/image-retention-policy.md)
- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Enterprise DevOps architecture](../docs/01-architecture/enterprise-devops-architecture.md)
- [Release and tagging standard](../docs/04-source-control/release-and-tagging-standard.md)
