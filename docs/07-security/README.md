# 07 — Security

## Purpose

Defines the security baseline that applies to delivered applications and to the delivery platform itself.

## Scope

Security controls across build, artifact, deployment, and runtime: secrets, vulnerability management, supply-chain security, SBOM, image signing, and access control. Security rules for **this repository** are in [SECURITY.md](../../SECURITY.md).

## Audience

Security engineers, platform engineers, and developers.

## Status

**Draft for review.** All seven documents are written. **No control described in them has been implemented, tested, or independently verified.**

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [security-baseline.md](security-baseline.md) | Threat model, the control catalogue by lifecycle stage with honest implementation status, and the governing principles | Draft |
| [secrets-management.md](secrets-management.md) | Approved mechanisms, reference-not-embed, environment isolation, lifecycle, rotation, and when Vault becomes justified | Draft |
| [vulnerability-management.md](vulnerability-management.md) | Scanning scope, blocking points, thresholds, scanner reliability, response to new disclosures, exceptions | Draft |
| [software-supply-chain-security.md](software-supply-chain-security.md) | Trust points from source to production, dependency and base image trust, build integrity, provenance, adoption order | Draft |
| [sbom-standard.md](sbom-standard.md) | What an SBOM must contain, where it is stored, how long it is kept, and its limitations | Draft |
| [container-image-signing.md](container-image-signing.md) | Intended approach, key custody, verification point, prerequisites — **roadmap, not adopted** | Draft |
| [access-control.md](access-control.md) | Role model, permission matrix, joiner/mover/leaver, review, emergency access | Draft |

## Reading Order

1. [security-baseline.md](security-baseline.md) — what is protected and what is actually in place
2. [access-control.md](access-control.md) — who can do what
3. [secrets-management.md](secrets-management.md) — how credentials are handled
4. [vulnerability-management.md](vulnerability-management.md) — what blocks, and what does not
5. [software-supply-chain-security.md](software-supply-chain-security.md) — the trust chain from source to production
6. [sbom-standard.md](sbom-standard.md) and [container-image-signing.md](container-image-signing.md) — Phase 3

---

## Baseline Controls

- least privilege and defense in depth
- no hard-coded credentials; no plaintext production secrets in Git
- TLS for sensitive communication
- environment separation between DEV, UAT, and PROD
- restricted administrative interfaces
- dependency pinning where practical
- trusted base images
- CI credential isolation
- vulnerability scanning and secret scanning
- SBOM generation
- image-signing roadmap
- immutable, auditable production artifacts
- backup and tested restore

Security controls must never be bypassed for convenience.

## Approved Secret Mechanisms (Initial)

- Jenkins Credentials
- environment-specific protected `.env` files held outside Git
- host-managed secrets

Vault or an equivalent may be recommended later based on scale and risk. It is not adopted at this stage.

---

## Open Items

- `TBD` — severity thresholds that block deployment
- `TBD` — vulnerability exception approval authority and SLA
- `TBD` — secret rotation frequency per credential type
- `TBD` — signing key custody and verification enforcement point
- `TBD` — role-to-permission mapping per platform

## Findings Worth Reviewing First

Four points in these documents affect decisions outside security:

| Finding | Where |
| --- | --- |
| The control catalogue's Status column reads "not implemented" or "policy only" for every row. That is the accurate state, and it means the baseline currently describes intent rather than protection | [security-baseline.md](security-baseline.md#2-control-catalogue) |
| Harbor pull-blocking on vulnerability severity also blocks rollback to a previously good image that has since acquired a finding — at the moment rollback is needed | [vulnerability-management.md](vulnerability-management.md#6-deployment-time-policy) |
| SBOMs must be retained independently of the images they describe, or image retention silently bounds how far back a supply-chain question can be answered | [sbom-standard.md](sbom-standard.md#4-storage) |
| Image signing verified by the same component that signs provides no defense against that component's compromise. The verification point depends on the undecided deployment mechanism | [container-image-signing.md](container-image-signing.md#4-verification-point) |

---

## Claims Discipline

Documents in this area may state alignment with generally accepted practice — including OWASP guidance, NIST secure software development guidance, and supply-chain security practice. They must not claim certification, formal compliance, completed audit, or independently verified security testing.

---

## Related

- [Documentation index](../README.md)
- [Repository security policy](../../SECURITY.md)
- [CI/CD](../05-ci-cd/)
- [Container](../06-container/)
- [Governance](../10-governance/)
- [Security templates](../../templates/security/)
