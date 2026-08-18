# Audit Evidence

## Purpose

Defines what evidence the delivery platform produces, where it is retained, for how long, and which questions it must be able to answer.

## Scope

Evidence of what was built, approved, deployed, changed, and accessed. Change classification is in [change-management.md](change-management.md); access rules are in [production-access-policy.md](production-access-policy.md).

## Audience

Platform engineers, security engineers, auditors, and anyone investigating an incident.

## Status

**Draft for review.** Retention periods and storage locations are undecided. No evidence is currently captured.

---

## 1. Start From the Questions

Evidence requirements are usually written as a list of things to log, which produces a large volume of records that answer no question completely.

The useful order is the reverse: decide which questions must be answerable, then capture what answers them.

| Question | Asked by | When |
| --- | --- | --- |
| What is running in production right now, and from which commit? | Anyone | Continuously |
| Who approved this release, and when? | Audit, incident review | After the fact |
| What changed between these two dates? | Incident review, audit | After the fact |
| Was this change reviewed, and by whom? | Audit | After the fact |
| Which quality and security gates passed for this artifact? | Security, audit | After the fact |
| Which of our images contained this newly disclosed component? | Security | On disclosure |
| Who accessed production, when, and why? | Security, audit | After the fact |
| Why was this control not enforced here? | Audit | After the fact |
| What did we do during that incident? | Incident review | After the fact |

If a question cannot be answered from retained evidence, the gap is a requirement, not an inconvenience. Section 2 maps each question to its source.

---

## 2. Evidence Sources

| Evidence | Produced by | Answers | Status |
| --- | --- | --- | --- |
| Commit history and pull requests | GitHub | What changed; who reviewed | Available |
| Pipeline execution record | Jenkins | Which gates ran and their verdicts | Available |
| Quality Gate result | SonarQube | Quality verdict per build | Available |
| Scan results | Trivy, Harbor | Vulnerability posture at build time | Not implemented |
| SBOM | Pipeline | Component inventory per image | Not implemented |
| Image metadata and digest | Harbor | Artifact identity and provenance | Not implemented |
| Registry audit log | Harbor | Who published, pulled, or deleted | Not implemented |
| **Deployment record** | Pipeline | What was deployed, where, when, by whose approval | **Not implemented** |
| Change record | Change process | What changed and why, including manual changes | Not implemented |
| Access record | Access process | Who held which tier, when, and why | Not implemented |
| Exception register | Exception process | Which controls were not enforced, and why | Not implemented |
| Incident record | Incident process | What happened and what was done | Not implemented |

The deployment record is emphasized because it is the join. Every other source describes one stage; the deployment record is what connects a running container to the commit, the pipeline execution, the gates, the approver, and the time. Without it, the other records exist as unconnected fragments and no end-to-end question is answerable.

---

## 3. The Deployment Record

Required per deployment, to any environment:

| Field | Source |
| --- | --- |
| Service | Pipeline |
| Environment | Pipeline |
| Release version | Pipeline |
| Image identifier and **digest** | Pipeline |
| Git commit | Pipeline |
| Git tag, for releases | Pipeline |
| Pipeline execution reference | Pipeline |
| Gate verdicts | Pipeline |
| Approver role and identity | Approval step |
| Approval timestamp | Approval step |
| Deployment timestamp | Pipeline |
| Previous version, for rollback | Pipeline, recorded **before** deployment |
| Outcome | Post-deployment verification |
| Change or ticket reference | Change record |

Two fields deserve comment.

**Digest, not only tag.** A tag is a pointer. Recording the digest makes the record independent of whether the tag is later moved — which should be impossible under [image-versioning.md](../06-container/image-versioning.md#6-tags-digests-and-what-actually-guarantees-immutability), but a record that does not depend on that assumption is stronger than one that does.

**Previous version, recorded before deployment.** It is the rollback target. Determining it afterwards, from a system that may already be failing, is how rollbacks get stuck.

Generated automatically. A record a human enters is a record that is sometimes not entered, and the occasions it is missed are the busy ones — which correlate with the occasions it is later needed.

---

## 4. Retention

| Evidence | Proposed retention | Driven by |
| --- | --- | --- |
| Commit history | Indefinite | Repository lifetime |
| Pull requests | Indefinite | Repository lifetime |
| Pipeline logs | `TBD` — medium | Investigation depth; volume |
| Gate verdicts | `TBD` — long | Audit |
| Scan results | `TBD` — long | Vulnerability history |
| SBOM | `TBD` — **longer than the image** | See below |
| Deployment records | `TBD` — long | Audit; incident review |
| Change records | `TBD` — long | Audit |
| Access records | `TBD` — long | Security investigation |
| Exception register | `TBD` — long, including closed entries | Audit |
| Incident records | `TBD` — long | Learning; audit |
| Production logs | `TBD` | Investigation; data protection |

`TBD` — the actual periods, and whether any external requirement sets a floor. Without an external driver, the practical question is: how far back might someone need to answer a question in section 1?

Two entries pull against the rest.

**SBOMs must outlive their images.** Image retention is bounded by rollback depth and storage; the supply-chain question can be asked long after an image is deleted. Storing SBOMs as image artifacts silently couples the two — see [sbom-standard.md](../07-security/sbom-standard.md#4-storage).

**Production logs pull the other way.** Where logs contain personal data, longer retention is a liability rather than an asset. Log retention should be the minimum that supports investigation, not the maximum storage allows — which is another reason for the never-log list in [logging-standard.md](../08-observability/logging-standard.md#5-what-must-never-be-logged).

---

## 5. Integrity

Evidence that the audited system can silently modify is weak evidence.

| Concern | Current position |
| --- | --- |
| Pipeline records are held by Jenkins, which performs the actions they describe | Accepted at this scale |
| Registry audit logs are held by Harbor, which they describe | Accepted at this scale |
| Deployment records are produced by the system that deploys | Accepted at this scale |

This is worth stating rather than leaving implicit. The current evidence model demonstrates what happened under normal operation. It does not demonstrate it against an adversary with administrative access to the platform, because such an adversary can alter the records.

Strengthening it would mean writing evidence to an append-only store outside the platform. That is not proposed now — it adds a system to operate, and the threat it addresses is not the leading one at this scale. It should be a deliberate acceptance rather than an unexamined default.

`TBD` — whether evidence integrity beyond platform-native retention is required.

---

## 6. Access to Evidence

Evidence records what people did, and is therefore sensitive in its own right.

| Requirement | Reason |
| --- | --- |
| Access is granted by role | Auditors read; they do not modify |
| Access to evidence is itself recorded | Otherwise the audit trail has an unaudited reader |
| Evidence containing personal data follows data-protection rules | Access records and logs name people |
| Evidence is not exported without a recorded reason | Export moves it outside its access controls |

`TBD` — who holds evidence access, and whether it is time-bounded.

---

## 7. Gaps

Stated plainly, because an evidence model with unstated gaps invites reliance it cannot support.

| Gap | Consequence |
| --- | --- |
| No deployment records exist yet | No end-to-end question in section 1 is currently answerable |
| No SBOMs | "Which images contain this component?" requires rebuilding everything |
| No change records | Manual changes leave no trace |
| No access records | "Who was on that host?" has no answer |
| No exception register | The total set of unenforced controls is unknown |
| Evidence integrity depends on the platform | Adequate against error; not against a platform-level adversary |

The first is the one to close before the others. Without deployment records, every other evidence source is a fragment describing one stage, and the platform cannot answer its most basic question: what is running, and where did it come from?

---

## 8. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — deployment record implementation and storage | Every end-to-end question |
| `TBD` — retention period per evidence type | Audit capability, cost, data protection |
| `TBD` — whether an external requirement sets a retention floor | Retention decisions |
| `TBD` — change record location and format | Manual change traceability |
| `TBD` — access record mechanism | Production access accountability |
| `TBD` — exception register location | Control-set visibility |
| `TBD` — evidence integrity beyond platform-native storage | Assurance level |
| `TBD` — who may read evidence, and whether that is recorded | Evidence confidentiality |

---

## Security Considerations

The integrity limitation in section 5 is the honest boundary of this evidence model. Records held by the systems they describe demonstrate normal operation; they do not withstand an adversary holding administrative access to those systems. Since Jenkins compromise is already identified as this architecture's principal security concentration — see [security-baseline.md](../07-security/security-baseline.md#security-considerations) — the two limitations are the same one seen from different sides.

Evidence is also sensitive. Access records and logs describe people's activity, and exception registers describe exactly where controls are not enforced — a useful document for an attacker who obtains it.

## Operational Considerations

Automatic generation is what determines whether this model works. Manual evidence is missing precisely when the situation was busy, and busy situations are the ones later investigated.

Retention conflicts must be resolved deliberately: audit wants longer, data protection wants shorter, storage wants smaller. Deciding each type separately, against the questions in section 1, produces defensible answers. Applying one period to everything produces a number that is wrong in both directions.

---

## Related

- [DevOps governance](devops-governance.md)
- [Change management](change-management.md)
- [Production access policy](production-access-policy.md)
- [Exception management](exception-management.md)
- [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md)
- [SBOM standard](../07-security/sbom-standard.md)
