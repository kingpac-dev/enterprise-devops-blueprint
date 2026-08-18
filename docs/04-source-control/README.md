# 04 — Source Control

## Purpose

Defines how application teams use Git and GitHub: repository conventions, branching, pull requests, releases, and tagging.

## Scope

Source-control practice for **application repositories**. Contribution rules for this blueprint repository are in [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Audience

All developers, plus platform engineers configuring repository protection.

## Status

**Draft for review.** All four documents are written. Reviewer counts, required checks, merge strategy, and the version scheme are proposals requiring confirmation.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [git-standard.md](git-standard.md) | Repository structure, naming, required files, commits, line endings, branch protection, provisioning | Draft |
| [branching-strategy.md](branching-strategy.md) | Branch model and lifecycle, naming, release branches, the merge-back failure, hotfix path, honest cost assessment | Draft |
| [pull-request-standard.md](pull-request-standard.md) | PR content, required checks, reviewers, what a review is for, size, merge strategy per branch pair | Draft |
| [release-and-tagging-standard.md](release-and-tagging-standard.md) | Version scheme, tag format and its mapping to image tags, release process, migrations, release notes, hotfix versioning | Draft |

## Reading Order

1. [git-standard.md](git-standard.md) — how a repository is set up
2. [branching-strategy.md](branching-strategy.md) — how work flows through branches
3. [pull-request-standard.md](pull-request-standard.md) — how a change gets reviewed and merged
4. [release-and-tagging-standard.md](release-and-tagging-standard.md) — how a set of changes becomes a release

---

## Baseline Branch Model

```text
feature/* -> develop -> DEV
release/* -> UAT
main      -> PROD
```

Pull requests are required before merging to protected branches. Avoid unnecessary branching complexity.

---

## To Define and Enforce

- branch protection rules
- required reviewers
- required CI checks
- merge strategy
- release tags
- hotfix process
- production release process

---

## Open Items

- `TBD` — minimum number of reviewers, per change type
- `TBD` — required status checks per application type
- `TBD` — merge strategy confirmation
- `TBD` — version scheme, and whether frontends differ

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **A fix that reaches `main` without also reaching `develop` is silently reverted by the next release.** This is the branch model's principal failure mode: the defect returns a full release cycle later, and its author believes it is fixed. An automated `main`-versus-`develop` comparison detects it regardless of discipline | [branching-strategy.md](branching-strategy.md#5-merging-back-is-where-this-model-fails) |
| Squash merging creates a new commit on `develop`, so no feature-branch commit corresponds to a promotable image. Promotable images must be built only from protected branches | [pull-request-standard.md](pull-request-standard.md#7-merge-strategy) |
| Force-pushing a protected branch can orphan a commit that a deployed image was built from. The image still runs, the deployment record still names the commit, and the commit is no longer in the branch | [git-standard.md](git-standard.md#7-branch-protection) |
| A migration the previous version cannot run against is a breaking change even when no API changed — rollback is the consumer that breaks | [release-and-tagging-standard.md](release-and-tagging-standard.md#2-version-scheme) |

## Proposals Requiring a Decision

Three defaults are proposed with reasoning rather than left open, because leaving them open blocks the CI/CD standards:

| Proposal | Reasoning |
| --- | --- |
| **Squash** for `feature/*` → `develop`; **merge commit** for `release/*` and `hotfix/*` → `main` and `develop` | Squash gives one meaningful commit and one image per change. Merge commits preserve the individual changes within a release, which squashing into `main` would erase |
| **One** approving review for ordinary changes, plus a domain reviewer for security, pipeline, or migration changes | Two nominal reviewers each assume the other read it carefully; one accountable reviewer is stronger |
| Coverage thresholds on **new code**, not the whole codebase | A threshold above what the codebase already achieves blocks every pull request on day one and is removed within a week |

---

## Related

- [Documentation index](../README.md)
- [CI/CD](../05-ci-cd/)
- [Container image versioning](../06-container/)
- [Governance](../10-governance/)
