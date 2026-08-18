# SBOM Generation

## Purpose

How the pipeline produces, stores, and later queries a Software Bill of Materials.

## Status

**Draft for review.** Not implemented. Format and storage location are undecided.

Implements [sbom-standard.md](../../docs/07-security/sbom-standard.md).

---

## 1. Where It Runs

```text
Docker Build
Container Scan
Generate SBOM        <- after the image exists, before publication
Push to Harbor
```

The SBOM must describe the **image that is published**, identified by digest. Generating it from the build context instead produces an inventory of what was intended rather than what shipped.

---

## 2. Commands

Trivy generates SBOMs, so no additional tool is required.

```bash
# CycloneDX
trivy image \
  --format cyclonedx \
  --output "sbom-${IMAGE_NAME}-${VERSION}.cdx.json" \
  "${IMAGE_REF}"

# SPDX (JSON)
trivy image \
  --format spdx-json \
  --output "sbom-${IMAGE_NAME}-${VERSION}.spdx.json" \
  "${IMAGE_REF}"
```

`TBD` — which format. Either is workable; consistency matters more than the choice, because a mixed set cannot be queried uniformly, and uniform querying is the entire point.

Record the **digest** alongside, not only the tag:

```bash
DIGEST=$(docker inspect --format '{{index .RepoDigests 0}}' "${IMAGE_REF}")
```

A tag is a pointer. An SBOM linked only to a tag describes whatever that tag pointed at when it was generated.

---

## 3. Generation Must Block Publication

If SBOM generation fails, the pipeline fails and no image is published.

An image published without an inventory cannot be assessed when a vulnerability is later disclosed, and the gap is silent — the image looks like every other image until someone needs to query it.

`TBD` — confirm this behaviour.

---

## 4. Storage

**SBOMs must be retained independently of the images they describe.**

Deleting an image deletes its scan metadata, and if the SBOM lives only alongside it, the record of what that image contained. Image retention is bounded by rollback depth and storage; the supply-chain question can be asked long after an image is gone.

| Option | Trade-off |
| --- | --- |
| Harbor, as an image artifact | Convenient. Shares the image's lifecycle, which is exactly the problem |
| Separate artifact store | Independent lifecycle. Another system to operate and back up |
| Pipeline artifact retention | Simple. Bounded by build retention, which is usually short |

`TBD` — the location. Whichever is chosen, its retention must be set deliberately rather than inherited from something else.

Naming should make an SBOM findable without a lookup:

```text
sbom-<image-name>-<version>-<commit>.<format>.json
sbom-orders-api-1.4.2-a82f912.cdx.json
```

---

## 5. Querying

Storage without queryability satisfies the letter of the requirement and provides none of the benefit — and the shortfall surfaces during the incident it was meant to shorten.

The question that must be answerable under time pressure:

> Which images contain `<component>` at `<version>`?

A minimal starting point over a directory of CycloneDX files:

```bash
# Which SBOMs contain a given component?
grep -l '"name": "<component>"' sboms/*.cdx.json

# With versions, using jq
jq -r --arg c "<component>" \
  'select(.components[]?.name == $c)
   | .metadata.component.name + " -> "
     + (.components[] | select(.name == $c) | .version)' \
  sboms/*.cdx.json
```

`TBD` — the real query mechanism. A grep over files is adequate for tens of images and not for hundreds.

Note what this does **not** answer: which of those images are actually deployed. That requires the deployment record — see [audit-evidence.md](../../docs/10-governance/audit-evidence.md). Both are needed, and neither exists yet.

---

## 6. Pipeline Fragment

```groovy
stage('Generate SBOM') {
    steps {
        sh '''
            set -eu
            trivy image \
              --format cyclonedx \
              --output "sbom-${IMAGE_NAME}-${VERSION}-${GIT_COMMIT_SHORT}.cdx.json" \
              "${IMAGE_REF}"
        '''
    }
    post {
        success {
            // TBD: publish to the chosen SBOM store rather than relying on
            // build artifact retention, which is bounded by build retention.
            archiveArtifacts artifacts: 'sbom-*.json', fingerprint: true
        }
    }
}
```

`set -eu` matters: without it a failing `trivy` invocation inside a multi-line `sh` step can leave the stage green.

---

## 7. Limitations to Record

An SBOM is not a complete inventory, and over-trusting it is its own risk.

- **Completeness varies.** Generators detect components through package manifests and known file signatures. Statically linked libraries, vendored code, and files copied in without a manifest may not appear.
- **It is point-in-time.** It describes the image at build, not anything installed into a running container afterwards.
- **Presence is not exposure.** A vulnerable component may sit on an unreachable code path. The SBOM narrows the candidate set; it does not decide the response.

---

## 8. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — format: SPDX or CycloneDX | Tooling compatibility |
| `TBD` — storage location, independent of image retention | Whether history survives |
| `TBD` — retention period | How far back a question can be answered |
| `TBD` — whether generation failure blocks publication | Inventory completeness |
| `TBD` — query mechanism at scale | Whether the inventory is usable under pressure |
| `TBD` — whether SBOMs are signed | Inventory integrity |

---

## Related

- [SBOM standard](../../docs/07-security/sbom-standard.md)
- [Vulnerability management](../../docs/07-security/vulnerability-management.md)
- [Software supply-chain security](../../docs/07-security/software-supply-chain-security.md)
- [Image retention policy](../../docs/06-container/image-retention-policy.md)
