# SBOM Standard

## Purpose

Defines what a Software Bill of Materials must contain, when it is generated, where it is stored, how long it is kept, and what it is used for.

## Scope

SBOM generation and retention for container images produced by the pipeline.

## Audience

Platform engineers, security engineers, and anyone answering a question about what a running service contains.

## Status

**Draft for review.** Not implemented. Format, storage location, and retention are undecided.

---

## 1. Why an SBOM Exists

An SBOM is a component inventory for an artifact. Its value is specific and easy to state.

When a vulnerability is disclosed against a widely used component, the question is:

> Which of our running services contain this, and which version?

Without an SBOM the answer requires rebuilding and rescanning every image, which takes long enough that the question is often not answered at all. With one, it is a query.

The interval between disclosure and having an answer is the interval during which nobody knows the exposure. That interval is what an SBOM shortens, and it is the entire justification for the retention and storage requirements below.

A secondary use is dependency review — what a service depends on, transitively — but the response case is what drives the requirements.

---

## 2. Requirements

| Requirement | Detail |
| --- | --- |
| Generated for | Every image published to Harbor |
| Generated at | Build time, after the image is built, before publication |
| Content | OS packages and application dependencies, including transitive ones, with versions |
| Linked to | The image digest, not only the tag |
| Format | `TBD` — SPDX or CycloneDX |
| Storage | `TBD` — see section 4 |
| Retention | At least as long as any image it describes, and preferably longer |

Linking to the digest rather than the tag matters. A tag is a pointer; a digest is the content. An SBOM linked only to a tag describes whatever that tag pointed at when it was generated, which is not necessarily what it points at later. See [image-versioning.md](../06-container/image-versioning.md#6-tags-digests-and-what-actually-guarantees-immutability).

---

## 3. Format

Both candidate formats are widely supported and either is workable.

| Format | Notes |
| --- | --- |
| SPDX | Broad tooling support; often expected where licence compliance also matters |
| CycloneDX | Security-oriented; integrates readily with vulnerability tooling |

`TBD` — the chosen format.

The decision that matters more than the format is that it is machine-readable and consistent. An SBOM that requires manual interpretation does not shorten the response interval, which is the only reason it is being produced.

---

## 4. Storage

**SBOMs must be retained independently of the images they describe.**

The reason is a direct consequence of retention policy. Deleting an image deletes its scan metadata and, if the SBOM lives only alongside it, the record of what that image contained. Retention tuned for storage cost would then also bound how far back a supply-chain question can be answered.

Those two retention requirements are different. Image retention is bounded by rollback depth and storage — see [image-retention-policy.md](../06-container/image-retention-policy.md). SBOM retention should be bounded by how long a question might be asked about what was running, which is longer.

| Option | Trade-off |
| --- | --- |
| Harbor, as an image artifact | Convenient; shares the image's lifecycle, which is the problem |
| Separate artifact store | Independent lifecycle; another system to operate and back up |
| Pipeline artifact retention | Simple; bounded by build retention, which is usually short |

`TBD` — the storage location. Whichever is chosen, its retention must be set deliberately rather than inherited.

---

## 5. Generation

Trivy generates SBOMs, so no additional tool is required.

Placement in the pipeline:

```text
Docker Build
Container Scan
Generate SBOM        <- after the image exists, before publication
Push to Harbor
```

The SBOM must describe the image that is published — the same digest. Generating it from the build context rather than the image produces an inventory of what was intended, not what shipped.

`TBD` — the exact command, and whether SBOM generation failure blocks publication. It should: an image published without an inventory is an image that cannot be assessed later, and the gap is silent.

---

## 6. Using It

The response procedure a disclosed vulnerability triggers:

```text
1. Identify the affected component and version range
2. Query SBOMs for images containing it
3. Determine which of those images are deployed, and where
4. Assess exploitability in context
5. Prioritize and remediate
6. Verify the remediated artifact no longer contains it
```

Step 3 requires the deployment record, not the SBOM. The SBOM says which images contain the component; the deployment record says which of those images are running. Both are needed, and neither is implemented — see the deployment audit trail in [10-governance/](../10-governance/).

Step 4 is where SBOM data stops being sufficient. Presence of a vulnerable component is not the same as exposure: the vulnerable code path may be unreachable in this application. The SBOM narrows the candidate set; it does not decide the response.

---

## 7. Limitations

Worth stating so the SBOM is not over-trusted.

- **Completeness varies.** Generators detect components through package manifests and known file signatures. Statically linked libraries, vendored code, and files copied in without a manifest may not appear.
- **It is a point-in-time record.** It describes the image at build. It does not describe anything installed into a running container afterwards — which is one more reason containers should be immutable at run time.
- **Presence is not exposure.** See step 4 above.
- **It requires the deployment record to be actionable.** On its own it answers "which images", not "which running services".

---

## 8. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — format: SPDX or CycloneDX | Tooling compatibility |
| `TBD` — storage location and its independence from image retention | Whether history survives |
| `TBD` — retention period | How far back a question can be answered |
| `TBD` — whether generation failure blocks publication | Inventory completeness |
| `TBD` — query mechanism across stored SBOMs | Whether the inventory is usable under time pressure |
| `TBD` — whether SBOMs are signed alongside images | Inventory integrity |

The query mechanism is the one most often overlooked. SBOMs stored but not queryable satisfy the letter of the requirement while providing none of the benefit, and the shortfall surfaces during the incident they were meant to shorten.

---

## Security Considerations

An SBOM is a detailed inventory of what a system runs, which makes it useful to an attacker as well as to a responder. It should not be published outside the organization without deliberate consideration.

Its integrity matters if it is to be relied upon. An SBOM that can be modified after generation can be made to omit a component. If image signing is adopted, signing SBOMs alongside images is a small addition — `TBD` in [container-image-signing.md](container-image-signing.md).

## Operational Considerations

The requirement that determines whether this standard delivers anything is section 4: SBOMs outliving the images they describe. Storing them as image artifacts is the convenient choice and quietly couples inventory history to storage-driven retention.

The second is queryability. An inventory that cannot be searched under pressure has the cost of an SBOM programme and the response capability of not having one.

---

## Related

- [Software supply-chain security](software-supply-chain-security.md)
- [Vulnerability management](vulnerability-management.md)
- [Container image signing](container-image-signing.md)
- [Image retention policy](../06-container/image-retention-policy.md)
- [Image versioning](../06-container/image-versioning.md)
- [Governance](../10-governance/)
