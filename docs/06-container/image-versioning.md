# Image Versioning

## Purpose

Defines the container image identity scheme and how an image identifier maps to the Git commit, release version, pipeline execution, deployment, and rollback target.

## Scope

Tag format, which tags are applied when, metadata carried by the image, and the rules that keep an identifier meaningful over time.

## Audience

Developers, platform engineers, and anyone answering the question "what is running in production?"

## Status

**Draft for review.** The release version scheme and the digest-pinning decision are undecided.

---

## 1. What an Identifier Must Guarantee

An image identifier must resolve to exactly one build, permanently.

That single property is what makes the traceability chain in [enterprise-devops-architecture.md](../01-architecture/enterprise-devops-architecture.md#5-the-traceability-chain) work. Every deployment record references an identifier; if the identifier's meaning can change, every record that references it becomes unreliable — including records written before the change.

Two questions must have precise answers at any moment:

- Given a running container, which commit produced it?
- Given a commit, where is it running?

---

## 2. Tag Formats

| Format | Example | Meaning |
| --- | --- | --- |
| Release version | `my-api:1.4.2` | A released version |
| Version with commit | `my-api:1.4.2-a82f912` | A released version, with its source commit visible |
| Commit only | `my-api:sha-a82f912` | A build of a specific commit, not a release |

All three are acceptable. `1.4.2-a82f912` is recommended as the primary production tag because it answers both questions in section 1 without a lookup.

`TBD` — whether the version component follows semantic versioning, and what increments it.

---

## 3. Tags by Branch

| Source | Tag applied | Promotable to |
| --- | --- | --- |
| `develop` | `sha-<commit>` | DEV |
| `release/*` | `<version>-<commit>` | DEV, UAT, PROD |
| `main` | `<version>-<commit>` | PROD |
| Feature branch | `TBD` | Nothing — build verification only |

A single image is built once and carries its tags for its lifetime. Promotion does not retag. What moves between environments is a deployment referencing the same identifier — see section 6.

`TBD` — whether feature branch builds produce an image at all, or only run verification. Producing one gives developers something to test with; not producing one avoids filling the registry with images that will never be deployed.

---

## 4. `latest`

`latest` must not be the production deployment identifier. It is a moving pointer: the image it names today is not necessarily the image it named yesterday, so a deployment record referencing it records nothing.

The question of whether `latest` should exist at all in this registry is `TBD`. Two positions:

- **Do not publish it.** Nothing can then accidentally depend on it. A Compose file that omits a tag fails rather than silently pulling something.
- **Publish it, pointing at the newest DEV-eligible build.** Convenient for local development, at the cost of it being available to be misused.

The risk of the second is that a missing tag in a Compose file resolves to `latest` by default. That failure is silent: the deployment succeeds and runs the wrong thing.

---

## 5. The Mapping

Every production image must be resolvable across all of these:

| Element | Where it is recorded |
| --- | --- |
| Git commit | Tag suffix, and `org.opencontainers.image.revision` label |
| Release version | Tag, and `org.opencontainers.image.version` label |
| Container image | The identifier itself, and its digest |
| Pipeline execution | Deployment record; `TBD` whether also an image label |
| Deployment | Deployment record: environment, timestamp, approver |
| Rollback target | The previous known-good identifier, recorded before deployment |

Labels are set at build time — see [dockerfile-standard.md](dockerfile-standard.md#8-image-metadata). They make an image self-describing, so a running container can be identified without access to the pipeline that built it. During an incident, that difference matters.

```bash
docker inspect --format '{{json .Config.Labels}}' <image>
```

---

## 6. Tags, Digests, and What Actually Guarantees Immutability

A tag is a mutable pointer. A digest is content-addressed and cannot refer to anything else.

```text
my-api:1.4.2                    tag — a pointer, repointable unless prevented
my-api@sha256:9f2a...           digest — the content itself
```

Harbor immutability rules prevent a tag from being repointed, which is the primary control. Deploying by digest makes the guarantee independent of that configuration.

`TBD` — whether production deployments reference the tag or the digest. Digest references are unambiguous but unreadable, so most teams deploy by tag and record the digest in the deployment record. That combination gets both properties.

### Retagging is prohibited

An existing tag must never be repointed to a different image. Doing so retroactively invalidates every deployment record referencing that tag — including records for deployments that already happened, whose evidence is now wrong. The audit trail does not merely become incomplete; it becomes actively misleading.

Harbor immutability rules should enforce this rather than relying on convention. `TBD` — enforcement configuration, in [harbor-standard.md](harbor-standard.md).

---

## 7. Promotion Does Not Change the Identifier

The image deployed to production is the same image, under the same identifier, that was deployed to UAT.

Some registries model promotion by copying an image between projects, which produces a new identifier for identical content. That breaks the property in section 1: "the artifact UAT verified" and "the artifact production runs" become two identifiers requiring a mapping to relate.

`TBD` — the Harbor promotion model, in [harbor-standard.md](harbor-standard.md). If copy-based promotion is chosen, the mapping between source and destination identifiers must be recorded in the deployment record.

---

## 8. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — version scheme and what increments it | Release management |
| `TBD` — whether feature branches produce images | Registry volume, developer workflow |
| `TBD` — whether `latest` is published at all | Risk of accidental dependency |
| `TBD` — deploy by tag or by digest | Immutability guarantee strength |
| `TBD` — whether the pipeline execution reference is an image label | Traceability without pipeline access |
| `TBD` — Harbor promotion model | Whether identity survives promotion |

---

## Security Considerations

Tag immutability is a supply-chain control, not a naming convention. An attacker able to repoint a tag can put arbitrary code into production through an entirely legitimate deployment path, producing a valid-looking audit trail. Harbor access control and immutability rules are what prevent this — see [harbor-standard.md](harbor-standard.md).

Deploying by digest removes the tag as an attack surface entirely, at the cost of readability.

## Operational Considerations

The scheme is only as reliable as its worst-supported path. A hotfix deployed manually with an ad hoc tag defeats it for that release, and that release is the one most likely to be examined later.

Rollback depends on the previous identifier still resolving to a retained image. Retention policy therefore bounds how far back a rollback can reach — see [image-retention-policy.md](image-retention-policy.md).

---

## Related

- [Harbor standard](harbor-standard.md)
- [Image retention policy](image-retention-policy.md)
- [Dockerfile standard](dockerfile-standard.md)
- [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md)
- [CI/CD standards](../05-ci-cd/)
