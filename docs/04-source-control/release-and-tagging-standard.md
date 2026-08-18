# Release and Tagging Standard

## Purpose

Defines the version scheme, the Git tag format, how a tag maps to a container image, and the release process from cut to production.

## Scope

Versioning and tagging for application repositories. Container image identity is in [image-versioning.md](../06-container/image-versioning.md); the production approval flow is in [10-governance/](../10-governance/).

## Audience

Developers, release approvers, and platform engineers.

## Status

**Draft for review.** The version scheme and increment authority are undecided.

---

## 1. What a Version Identifies

A version names a specific, immutable set of changes that were built once, verified, and released together.

It must be:

- **assigned once** — a version never refers to two different builds
- **traceable** — resolvable to a commit, an image, a pipeline execution, and a deployment
- **ordered** — later versions sort after earlier ones
- **meaningful to consumers** — the increment says something about what changed

The four together are what let "which version is in production?" have a precise answer, which the traceability chain in [enterprise-devops-architecture.md](../01-architecture/enterprise-devops-architecture.md#5-the-traceability-chain) depends on.

---

## 2. Version Scheme

`TBD` — confirm. Proposal: semantic versioning.

```text
MAJOR.MINOR.PATCH
```

| Increment | When | Example |
| --- | --- | --- |
| MAJOR | A change consumers must react to | Removing an API field; changing a contract |
| MINOR | New capability, backward compatible | Adding an endpoint or an optional field |
| PATCH | Fix, no interface change | Correcting a calculation; fixing a crash |

### What "breaking" means for an internal service

Semantic versioning is defined against a public API. For an internal service the equivalent question is: **would a consumer have to change to keep working?**

| Change | Increment |
| --- | --- |
| Removing or renaming an API field | MAJOR |
| Changing the type or meaning of a field | MAJOR |
| Making an optional request field required | MAJOR |
| Adding an optional field | MINOR |
| Adding an endpoint | MINOR |
| Internal refactoring, no observable change | PATCH |
| Changing a message schema consumed by a worker | MAJOR — the consumer is the worker |
| A database migration that the previous version cannot run against | MAJOR in effect — see section 6 |

The last two are the ones misclassified in practice. A message schema is an interface even though it is not an HTTP API. A migration that breaks the previous version is a breaking change even when no API changed, because rollback is the consumer that breaks.

### Frontend applications

Semantic versioning fits a frontend poorly — a browser application has no consumers negotiating a contract. `TBD` — whether frontends use semantic versioning for consistency, or a date- or build-based scheme. Consistency across repositories has real value for tooling, and it is worth choosing deliberately rather than by default.

---

## 3. Tag Format

Git tags carry a `v` prefix; image tags do not.

```text
Git tag:     v1.4.2
Image tag:   1.4.2-a82f912
```

The mismatch is conventional — `v1.4.2` is standard for Git tags, and container registries conventionally omit the prefix. It must be stated explicitly because it is otherwise a source of confusion when correlating a release to a running container.

| Property | Requirement |
| --- | --- |
| Annotated tags, not lightweight | Carries tagger, date, and message |
| Applied on `main` only | `main` is what production runs |
| Applied at the merge commit | The tag names what was released |
| **Never moved or deleted** | See below |

A moved tag retroactively invalidates every record referencing it — the same failure as retagging an image, described in [image-versioning.md](../06-container/image-versioning.md#6-tags-digests-and-what-actually-guarantees-immutability). Records written before the move are not merely incomplete afterwards; they are wrong, and nothing indicates it.

`TBD` — whether tag protection rules are configured to enforce this.

---

## 4. Git Tag to Image Mapping

```text
Git tag          v1.4.2
tagged commit    a82f912
image            harbor.example.internal/team/orders-api:1.4.2-a82f912
image digest     sha256:9f2a...
deployment       PROD, 2026-08-16T09:14Z, approved by <role>
```

The commit in the image tag **must be the tagged commit**. If they differ, the image was built from something other than what was released, and every downstream record is describing a build nobody tagged.

`TBD` — whether the pipeline verifies this, or whether it is assumed. It should verify: comparing the built commit against the tag is one check, and the failure it prevents is one that is otherwise invisible.

---

## 5. Release Process

```text
1.  Cut release/<version> from develop
2.  Build; image tagged <version>-<commit>
3.  Deploy to DEV; health check
4.  Deploy to UAT; health check
5.  UAT verification
6.  Fixes, if needed, on the release branch — return to step 2
7.  Merge release/<version> to main
8.  Tag v<version> on main, annotated
9.  Production approval
10. Deploy the SAME image to PROD
11. Health check, smoke test
12. Record deployment evidence
13. MERGE BACK to develop
14. Delete the release branch
```

Step 10 deploys the image built at step 2 — the one UAT verified. Nothing is rebuilt for production. Rebuilding would produce a different artifact, discarding the evidence UAT provided, which is the whole point of the promotion model in [environment-architecture.md](../01-architecture/environment-architecture.md#6-promotion-rules).

Step 13 is the merge-back. Omitting it means fixes made during UAT are reverted by the next release — see [branching-strategy.md](branching-strategy.md#5-merging-back-is-where-this-model-fails).

Steps 8 and 10 are separated deliberately. Tagging records what was released; approval and deployment are separate decisions, and the tag exists before either.

---

## 6. Database Migrations and Version Meaning

A release containing a database migration frequently cannot be rolled back by redeploying the previous image. The old code runs against the new schema and fails.

This makes migration releases a distinct class:

| Requirement | Detail |
| --- | --- |
| The pull request states the rollback limitation | Before merge, not at release |
| The release notes state it | The approver needs to know before approving |
| Backward compatibility is preferred | Expand/contract: add first, migrate, remove in a later release |
| A backup precedes destructive changes | Verified, not assumed |

Under expand/contract, the removal step is a separate release from the addition. That is more releases and more coordination, and it is what keeps rollback available across each individual step.

**Never promise automatic rollback for an irreversible database change.** Where a release cannot be rolled back, say so in the release notes and plan forward recovery instead.

`TBD` — migration tooling, ownership, and execution stage, in [05-ci-cd/](../05-ci-cd/).

---

## 7. Release Notes

Every release produces notes covering:

| Section | Content |
| --- | --- |
| Version and date | |
| Changes | What changed, in terms a reader outside the team understands |
| Breaking changes | Explicitly, even when none — "none" is information |
| Migrations | Present or absent; rollback implications |
| Configuration changes | New or changed values required before deployment |
| Rollback | Whether it is available, and any limitation |
| Known issues | |

The approver reads these before approving. Notes written after deployment serve a different and lesser purpose.

Configuration changes deserve their own line because their failure mode is specific: a release requiring a new configuration value deploys successfully and then fails at run time, in production, on the values that were not set.

`TBD` — whether release notes are generated from commits or written. Generated notes are complete and unreadable; written notes are readable and sometimes omit things. A hybrid — generated change list plus written summary — is usually the workable answer.

---

## 8. Hotfix Versioning

A hotfix increments PATCH from the version currently in production, not from `develop`.

```text
Production:        1.4.2
Hotfix branch:     hotfix/1.4.3-payment-timeout, branched from main
Released:          v1.4.3
develop meanwhile: heading toward 1.5.0
```

After merge-back, `develop` contains the fix and its next release is 1.5.0, which supersedes 1.4.3. The hotfix version does not disturb the planned sequence.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — version scheme confirmation, and whether frontends differ | Every release |
| `TBD` — who decides the increment, and when | Version meaning |
| `TBD` — whether the pipeline verifies tag commit against image commit | Traceability integrity |
| `TBD` — tag protection configuration | Whether tags are immutable in practice |
| `TBD` — release cadence: scheduled or on demand | Planning |
| `TBD` — release note generation approach | Approver information quality |
| `TBD` — migration tooling and ownership | Rollback safety |
| `TBD` — whether a structured commit convention drives versioning | Automation |

---

## Security Considerations

Tag immutability is an audit control. A moved or deleted tag breaks the chain from a running artifact back to a reviewed commit, and it does so for records already written. Tag protection should enforce it rather than relying on convention.

Release notes are read by more people than the code and are frequently exported to tickets and email. They must not contain internal hostnames, addresses, credentials, or detailed vulnerability information about systems still exposed.

## Operational Considerations

The two steps most often skipped are merge-back and release notes, and both fail quietly. Merge-back reverts fixes a release later; missing release notes leave the approver deciding without information and leave configuration changes undiscovered until deployment.

Migration releases deserve separate handling because they remove the rollback path that every other release relies on. Treating them as ordinary releases works until the release that needs rolling back is one of them.

---

## Related

- [Branching strategy](branching-strategy.md)
- [Pull request standard](pull-request-standard.md)
- [Git standard](git-standard.md)
- [Image versioning](../06-container/image-versioning.md)
- [Environment architecture](../01-architecture/environment-architecture.md)
- [Governance](../10-governance/)
