# Container Image Signing

## Purpose

Defines the intended approach to signing container images and verifying them before deployment, and the conditions under which it will be adopted.

## Scope

Artifact signing and verification. Component inventory is in [sbom-standard.md](sbom-standard.md); the surrounding controls are in [software-supply-chain-security.md](software-supply-chain-security.md).

## Audience

Security engineers, platform engineers, and architects.

## Status

**Roadmap — Phase 3. Not adopted.** This document records the intended approach and its prerequisites so the decision can be made deliberately rather than improvised later. No signing exists today.

---

## 1. What Signing Adds

Every other artifact control in this blueprint depends on trusting Harbor.

Registry access control prevents unauthorized publication. Tag immutability prevents an identifier from being repointed. Both are enforced by the registry — so an attacker with sufficient access to Harbor defeats both, and every downstream control continues to operate normally. The pipeline deploys the substituted artifact, health checks pass, and the audit record is accurate in every field except the one that matters.

Signing changes where trust sits. A signature is created by the pipeline and verified at the deployment target, so the guarantee no longer depends on the registry being uncompromised. The registry becomes a distribution mechanism rather than a root of trust.

That is the whole benefit, and it is only realized if verification actually happens at deployment. **Signing without verification provides no protection.** It produces a signature nobody checks, and an assurance nobody has earned.

---

## 2. Approach

`TBD` — the tooling. Two viable models:

| Model | Mechanism | Trade-off |
| --- | --- | --- |
| Key-based signing | A long-lived key pair; the pipeline signs, deployment verifies against the public key | Simple to reason about; requires key custody, rotation, and revocation |
| Keyless signing | Short-lived certificates bound to a workload identity, with a transparency log | No long-lived key to protect; depends on external identity and log infrastructure |

Keyless signing removes the hardest operational problem — protecting a signing key indefinitely — and replaces it with dependencies on identity and transparency infrastructure. Whether those dependencies are acceptable in a controlled internal network is the deciding question, and it is not answered here.

---

## 3. Key Custody, If Key-Based

The signing key is the most sensitive credential in the platform. An attacker holding it can sign arbitrary artifacts that pass every verification the platform performs.

| Requirement | Detail |
| --- | --- |
| Storage | Hardware-backed or a dedicated secret store, not Jenkins Credentials alongside ordinary credentials |
| Access | The signing step only; no human standing access |
| Rotation | Defined schedule, with a procedure that does not invalidate previously signed artifacts |
| Revocation | Defined procedure and a defined effect on already-deployed artifacts |
| Backup | Recoverable, without weakening custody |
| Audit | Every use recorded |

Rotation is the requirement that is hard to satisfy and easy to omit. Rotating a signing key means artifacts signed with the old key must remain verifiable — otherwise every previously published image becomes unverifiable, including the rollback targets. Verification must therefore accept a set of trusted keys with defined validity periods, not a single current key.

A signing key stored alongside build credentials provides considerably less than it appears to: compromise of the controller then yields both the ability to build and the ability to sign.

---

## 4. Verification Point

Verification must occur where the artifact is used, not where it is stored.

| Point | Effect |
| --- | --- |
| At the runtime host, before running | Strongest — an unsigned or invalid image does not run |
| In the deployment pipeline, before deploying | Useful, but the pipeline is the component whose compromise this defends against |
| In the registry, on push | Weakest — verifies publication, not what is deployed |

The second row is worth reading carefully. If Jenkins both signs and verifies, a compromised Jenkins signs its own artifact and verifies it successfully. Verification at the runtime host is what makes the control independent of the component being defended against.

`TBD` — the verification point. It depends on the deployment mechanism, which is itself undecided — see interaction I-06 in [service-interaction.md](../01-architecture/service-interaction.md#2-interaction-i-06-the-open-question).

---

## 5. Failure Behaviour

Signing introduces a new way for a deployment to fail, and the behaviour must be decided before adoption rather than discovered during an incident.

| Situation | Question |
| --- | --- |
| Signature invalid | Block. This is the control working |
| Signature missing | Block, or warn during a transition period? `TBD` |
| Verification infrastructure unavailable | Block, or proceed? `TBD` |
| Emergency rollback to an image signed with a rotated key | Must still verify — see section 3 |

The third row is the one that collides with availability. Fail-closed is consistent with [security-baseline.md](security-baseline.md#3-principles), and it means an outage in verification infrastructure stops deployments including rollbacks. Fail-open means the control is absent exactly when the infrastructure is under stress, which is also when an attacker would prefer it to be.

This is a genuine trade-off. It should be decided explicitly and recorded in an ADR.

---

## 6. Prerequisites

Signing is last in the supply-chain adoption order in [software-supply-chain-security.md](software-supply-chain-security.md#7-adoption-order), and the reason is worth stating.

A signature attests that an artifact came from the expected pipeline. It says nothing about whether that pipeline's inputs were controlled. Signing an image built from unpinned dependencies, on a persistent agent holding every environment's credentials, produces a verifiable cryptographic guarantee about an uncontrolled process.

Before signing is worth adopting:

| Prerequisite | Reason |
| --- | --- |
| Dependencies pinned via lockfiles | Otherwise the signed contents are not reproducible |
| Base images pinned | Same |
| Registry access control and tag immutability in place | Signing complements these; it does not replace them |
| Build credentials isolated | A compromised build that can sign defeats the control |
| SBOM generation working | Provenance and inventory are complementary |
| Deployment mechanism decided | Determines where verification can occur |

The last is the immediate blocker. Verification at the runtime host requires knowing how the runtime host obtains and starts images.

---

## 7. Adoption Plan

When Phase 3 is reached:

```text
1. Decide key-based or keyless           -> ADR
2. Decide the verification point          -> depends on I-06
3. Decide failure behaviour               -> ADR
4. Establish key custody and rotation     -> if key-based
5. Sign in the pipeline, do not verify    -> transition; build signature coverage
6. Verify in warn mode                    -> measure what would be blocked
7. Verify in blocking mode                -> the control becomes real
8. Extend to SBOM signing                 -> optional
```

Steps 5 and 6 exist so that enabling enforcement does not block deployments on day one for reasons nobody predicted. Step 7 is when the control begins to provide anything.

Stopping at step 5 is a common outcome and produces signatures nobody verifies. If the programme is unlikely to reach step 7, the effort is better spent on the prerequisites in section 6.

---

## 8. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — key-based or keyless | Everything below |
| `TBD` — verification point | Depends on I-06 |
| `TBD` — failure behaviour when verification is unavailable | Availability versus assurance |
| `TBD` — key custody, rotation, and revocation, if key-based | Whether the key is defensible |
| `TBD` — whether SBOMs are signed | Inventory integrity |
| `TBD` — transition timeline | Adoption |

---

## Security Considerations

Signing is the only control here that survives compromise of the registry. That is its entire value, and it is realized only at the verification step.

The signing key is the platform's highest-value secret if key-based signing is chosen. Storing it alongside ordinary build credentials gives an attacker who compromises the controller both build and signing capability, which returns the platform to its unsigned security posture while displaying signatures.

Verification performed by the same component that signs provides no defense against that component's compromise.

## Operational Considerations

Signing adds a failure mode to deployment, including rollback. Key rotation must preserve verifiability of previously signed artifacts, or every rollback target becomes unverifiable at rotation time.

The realistic risk to this programme is not technical difficulty. It is stopping after signing is enabled and before verification is enforced — at which point the platform has the operational cost of signing and none of its protection, while appearing to have both.

---

## Related

- [Software supply-chain security](software-supply-chain-security.md)
- [SBOM standard](sbom-standard.md)
- [Security baseline](security-baseline.md)
- [Harbor standard](../06-container/harbor-standard.md)
- [Service interaction](../01-architecture/service-interaction.md)
- [Architecture Decision Records](../../adr/)
