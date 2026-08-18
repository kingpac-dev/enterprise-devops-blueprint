# 06 — Container

## Purpose

Defines how container images are built, configured, versioned, stored, and retained.

## Scope

Docker practice, Dockerfile requirements, Compose usage, Harbor registry standards, image versioning, and retention. Container vulnerability policy is in [07-security/](../07-security/).

## Audience

Developers, platform engineers, and operations.

## Status

**Draft for review.** All six documents are written. Parameters throughout are `TBD` — the standards define where a decision belongs, not what it is.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [docker-standard.md](docker-standard.md) | The runtime contract every container must satisfy: signals, logging, health, resources, filesystem | Draft |
| [dockerfile-standard.md](dockerfile-standard.md) | Multi-stage builds, base image pinning, caching, `.dockerignore`, non-root, build secrets, per-application-type requirements | Draft |
| [docker-compose-standard.md](docker-compose-standard.md) | Compose structure per environment, restart policy, volumes, networks, logging limits, resource limits | Draft |
| [harbor-standard.md](harbor-standard.md) | Projects, access model, immutability, scanning, promotion, storage, backup | Draft |
| [image-versioning.md](image-versioning.md) | Tag scheme and its mapping to commit, release, pipeline, deployment, and rollback | Draft |
| [image-retention-policy.md](image-retention-policy.md) | What is kept, for how long, and what is never garbage-collected | Draft |

## Reading Order

1. [image-versioning.md](image-versioning.md) — the identity scheme everything else references
2. [dockerfile-standard.md](dockerfile-standard.md) — how images are built
3. [docker-standard.md](docker-standard.md) — how they must behave at run time
4. [docker-compose-standard.md](docker-compose-standard.md) — how they are deployed
5. [harbor-standard.md](harbor-standard.md) — where they are stored
6. [image-retention-policy.md](image-retention-policy.md) — how long they survive, and what that means for rollback

---

## Versioning Baseline

Acceptable, traceable identifiers:

```text
app:1.4.2
app:1.4.2-a82f912
app:sha-a82f912
```

Every image must be traceable to its Git commit, release version, pipeline execution, deployment, and rollback target.

`latest` must not be the production deployment identifier.

---

## Container Requirements

- multi-stage builds where appropriate
- minimal runtime images
- non-root execution where practical
- `.dockerignore` present
- no embedded credentials
- controlled or pinned base-image strategy
- explicit runtime configuration
- correct signal handling
- health checks where technically appropriate

Production artifacts must be immutable or otherwise protected against accidental replacement.

---

## Open Items

- `TBD` — Harbor URL, project naming, and robot-account model
- `TBD` — approved base images and their update cadence
- `TBD` — retention windows per environment, derived from required rollback depth
- `TBD` — whether Harbor immutability rules are enforced per project or globally

## Decisions Worth Reviewing First

Three choices in these documents have consequences beyond container practice:

| Decision | Why it matters | Where |
| --- | --- | --- |
| Harbor promotion model | Copying images between projects gives identical content a new identifier, breaking the guarantee that production runs what UAT verified | [harbor-standard.md](harbor-standard.md#2-project-structure) |
| Retention depth | Retention bounds how far back a rollback can reach. Tuning it for storage cost silently shortens the recovery window | [image-retention-policy.md](image-retention-policy.md#1-retention-is-a-reliability-control) |
| Pull-blocking on vulnerability severity | A strong control that can also block an emergency rollback to a previously good image | [harbor-standard.md](harbor-standard.md#5-vulnerability-scanning) |

---

## Related

- [Documentation index](../README.md)
- [CI/CD](../05-ci-cd/)
- [Security](../07-security/)
- [Docker templates](../../templates/docker/)
- [Compose templates](../../templates/compose/)
