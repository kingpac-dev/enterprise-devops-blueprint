# Business Value

## Purpose

States the outcomes the blueprint is expected to deliver, the costs it carries, and the basis on which either could be verified.

## Audience

Engineering management and anyone deciding whether to fund the implementation.

## Status

**Draft for review.** Every outcome below is **projected**. Nothing has been implemented, and therefore nothing has been measured. No baseline exists.

---

## 1. The Honest Framing

The platform does not exist yet, so this document cannot report improvement. It can state which outcomes the design is intended to produce, what would demonstrate them, and what they cost.

Claims here should be read as hypotheses with a stated test, not as results. Where a benefit is commonly asserted and cannot be substantiated at this stage, that is said.

---

## 2. Expected Outcomes

### Delivery becomes traceable

Every production deployment resolves to a commit, a pipeline execution, an image digest, an approver, and a timestamp.

| Value | Today's alternative |
| --- | --- |
| "What is running?" is answered in seconds | Reconstructed from memory and inspection |
| Incident scoping starts from a known version | Starts by determining what is deployed |
| Audit questions are answerable from records | Answered by recollection, or not answered |

**How it would be demonstrated:** pick any running container; resolve it to its commit and approver from records alone, without asking anyone.

### Releases become repeatable

Build once, promote the same artifact. The image verified in UAT is the image production runs.

| Value | Today's alternative |
| --- | --- |
| UAT verification is evidence about production | Evidence about a different build of the same source |
| Environment-specific build failures disappear | Discovered per environment |
| Rollback targets are known artifacts | Rebuilt, and therefore different |

**How it would be demonstrated:** compare image digests across DEV, UAT, and PROD for one release. They are identical, or the model is not being followed.

### Recovery becomes designed rather than improvised

Rollback is defined before the first production deployment. The previous known-good version is recorded before deployment, not reconstructed during a failure.

**How it would be demonstrated:** a deliberate rollback exercise, timed, in a non-production environment first. Until that has been performed, recovery capability is unproven — the same standard this blueprint applies to backups.

### Security controls become consistent

One baseline applies to every team: scanning, secret handling, least privilege, immutable artifacts.

The value is not that controls exist somewhere. It is that the organization's exposure stops being set by whichever team has the weakest practice, because there is one practice.

**How it would be demonstrated:** control coverage across repositories, and the count of active exceptions. Both are measurable once implemented, and both are currently zero because nothing is implemented.

### Delivery knowledge stops being individual

Standards, runbooks, and templates make delivery transferable. A new team follows a documented path; an unfamiliar service can be operated from its runbook.

**How it would be demonstrated:** time from a new project's creation to its first production deployment, and whether an operator unfamiliar with a service can execute its runbook without escalating.

### Duplicated effort is removed

Shared pipeline templates and a Jenkins shared library mean pipeline improvements are made once.

This is the outcome most likely to be **overstated**. It materializes only if teams actually adopt the shared templates rather than copying and diverging from them, which is a governance and usability question rather than a technical one. Templates that are hard to use get copied and modified, and the duplication returns with an extra layer.

---

## 3. What Cannot Be Claimed

| Not claimed | Why |
| --- | --- |
| Faster delivery | Quality and security gates add time per release. The intended effect is fewer failed releases and faster recovery, not faster individual deployments |
| Fewer defects | No evidence exists. Gates catch some classes of defect; they do not make software correct |
| Compliance with any standard | No assessment has been performed. The blueprint states alignment with generally accepted practice and nothing more |
| Reduced headcount | The platform requires people to operate it. See section 4 |
| A secure platform | No control has been implemented, tested, or independently verified |

The first row is worth stating to management explicitly, because it is the expectation most likely to be disappointed. Introducing mandatory gates makes each release slower. The argument for them is that a failed production release costs more than the gate time, and that the failures prevented are the expensive kind.

---

## 4. Costs

A benefits case that omits costs is not a case.

| Cost | Nature |
| --- | --- |
| Platform operation | Ongoing. Jenkins, Harbor, SonarQube, and the observability stack need patching, backup, storage management, and upgrade |
| Infrastructure | Ongoing. Hosts, storage, and growth — particularly registry storage |
| Standards maintenance | Ongoing. A standard nobody maintains becomes misleading |
| Per-release gate time | Ongoing, per release |
| Approval availability | Ongoing. Manual production approval means release throughput depends on a person |
| Initial implementation | One-off, substantial. Building the toolchain and migrating existing applications |
| Learning | One-off per team |

The recurring costs are the ones that determine whether this survives. Credential rotation, access review, base image updates, restore testing, and standard review all have ongoing cost and no immediate consequence for skipping — which is the category of work that quietly stops.

---

## 5. Sequencing

The largest returns come earliest, which argues for implementing in order rather than waiting for completeness.

| Order | Capability | Return |
| --- | --- | --- |
| 1 | Source control standards and branch protection | Immediate; no infrastructure needed |
| 2 | CI with quality and security gates | High; catches defects before they are deployable |
| 3 | Immutable artifacts in a registry | High; makes traceability and rollback possible at all |
| 4 | Controlled deployment with approval and rollback | High; this is where production risk actually drops |
| 5 | Observability | High, and easy to defer — until an incident |
| 6 | Supply-chain hardening: SBOM, signing | Moderate; depends on 1 to 4 being real first |

Item 5 is the one most often deferred and most regretted. It has no visible benefit until something breaks, at which point its absence is the difference between a diagnosis and a guess.

---

## 6. What Would Falsify This

Signals that the blueprint is not delivering, and should be revisited rather than defended:

| Signal | Interpretation |
| --- | --- |
| Emergency changes rise as a share of all changes | The normal path is too painful and is being routed around |
| Active exceptions grow steadily | The standards do not fit how work is actually done |
| Teams copy templates and diverge instead of using shared ones | The templates are not usable |
| Change failure rate does not fall after gates are enforced | The gates are checking the wrong things |
| Mean time to recovery does not improve after rollback is implemented | Rollback is not usable in practice |

Each is measurable once the platform exists. A blueprint that cannot be falsified cannot be improved.

---

## 7. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — baseline measurement of current delivery performance | Whether improvement can ever be demonstrated |
| `TBD` — implementation cost estimate | Funding decision |
| `TBD` — platform operating cost, including storage growth | Ongoing budget |
| `TBD` — who measures the metrics in [kpi-and-success-metrics.md](kpi-and-success-metrics.md) | Whether outcomes are tracked at all |

The first is time-critical. Baselines can only be captured **before** implementation. Once the platform is in place, the pre-implementation state is unmeasurable, and every claim of improvement becomes an assertion.

---

## Related

- [Executive summary](executive-summary.md)
- [DevOps roadmap](devops-roadmap.md)
- [KPIs and success metrics](kpi-and-success-metrics.md)
- [Risk register](risk-register.md)
