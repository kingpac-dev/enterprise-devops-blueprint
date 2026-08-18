# Security Baseline

## Purpose

Defines the mandatory security controls across the software delivery lifecycle, and states plainly which of them are currently enforced.

## Scope

Controls applying to delivered applications and to the delivery platform. Security rules for **this repository** — what must never be committed, and how to report a problem — are in [SECURITY.md](../../SECURITY.md).

## Audience

Security engineers, platform engineers, developers, and reviewers of security-relevant changes.

## Status

**Draft for review.** No control below has been implemented, tested, or independently verified. This document describes a target baseline.

## Claims Discipline

This document may state alignment with generally accepted practice, including OWASP guidance, NIST secure software development guidance, and supply-chain security practice.

It makes **no claim** of certification, formal compliance, completed audit, regulatory approval, or independently verified security testing. `Aligned with`, `recommended by`, `required by organization`, and `formally compliant with` are not interchangeable, and only the first three are used here.

---

## 1. What This Baseline Protects Against

The delivery platform's security properties differ from an application's. The assets are the source, the artifacts, the credentials that publish and deploy them, and the audit record of what happened.

| Threat | Consequence | Primary control |
| --- | --- | --- |
| Credential committed to Git | Compromise of whatever it grants; history retains it | Secret scanning, `.gitignore`, review |
| Compromised CI credentials | Arbitrary artifacts published; every environment reachable | Credential isolation, least privilege, rotation |
| Artifact substituted in the registry | Arbitrary code in production through a legitimate path with a valid audit trail | Registry access control, tag immutability, signing |
| Vulnerable dependency shipped | Exploitable service in production | Dependency scanning, blocking gates, SBOM |
| Unpatched base image | Known vulnerabilities in every image built on it | Base image pinning plus an update process |
| Manual production change | Runtime diverges from the audit record | Change control, deployment audit trail |
| Excessive standing privilege | Ordinary compromise becomes broad compromise | Access control, periodic review |
| Missing or untested backup | Unrecoverable loss | Backup standard, restore testing |

The third row is the one specific to this architecture. An attacker who reaches Harbor does not need to defeat any deployment control — the pipeline will deploy their artifact correctly, verify its health, and record an accurate deployment against a legitimate approver.

---

## 2. Control Catalogue

Controls by lifecycle stage. The Status column is honest about the current state, not aspirational.

### Source

| Control | Requirement | Status |
| --- | --- | --- |
| Branch protection on protected branches | Required | `TBD` — configuration |
| Review before merge | Required | `TBD` — reviewer count |
| Secret scanning on push and in the pipeline | Required | Not implemented |
| No secrets in Git, in any form | Required | Policy only; unenforced |
| Signed commits | Not required at this stage | Not adopted |

### Build

| Control | Requirement | Status |
| --- | --- | --- |
| Dependency vulnerability scanning | Required | Not implemented |
| Static analysis with an enforcing Quality Gate | Required | `TBD` — gate conditions |
| Dependency pinning where practical | Required | Not implemented |
| Build credentials isolated per pipeline | Required | Not implemented |
| No secrets in build arguments or logs | Required | Policy only |
| Reproducible base images | Required | `TBD` — pinning level |

### Artifact

| Control | Requirement | Status |
| --- | --- | --- |
| Container image scanning before publication | Required | Not implemented |
| SBOM generated and retained | Required | Not implemented |
| Tag immutability enforced at the registry | Required | Not implemented |
| Registry access least privilege, pull-only at runtime | Required | Not implemented |
| Image signing | Roadmap — Phase 3 | Not adopted |

### Deploy

| Control | Requirement | Status |
| --- | --- | --- |
| Explicit immutable version, never `latest` | Required | Policy only |
| Production approval, recorded | Required | `TBD` — approver role |
| Deployment audit trail | Required | Not implemented |
| Environment-separated credentials | Required | Not implemented |
| Rollback path verified before first production deploy | Required | Not implemented |

### Runtime

| Control | Requirement | Status |
| --- | --- | --- |
| Non-root container execution where practical | Required | Policy only |
| TLS for sensitive communication | Required | `TBD` — termination points |
| Administrative interfaces not publicly exposed | Required | `TBD` |
| Resource limits in production | Required | Policy only |
| Structured logs free of credentials and unnecessary personal data | Required | Policy only |
| Backup with tested restore | Required | Not implemented |

Every row reads "not implemented" or "policy only". That is the accurate current state, and stating it is more useful than a document that reads as though the platform were protected.

---

## 3. Principles

### Least privilege

Every identity — human, robot, or service — holds the minimum access required for its function, for the shortest practical time. The recurring failure is not granting too much deliberately; it is granting broadly once and never revisiting it.

### Defense in depth

No single control is assumed sufficient. Secret scanning will miss secrets; scanners will miss vulnerabilities; reviewers will miss defects. Controls are layered so that one failure is not a breach.

### Secure by default

The default configuration must be the safe one. A control requiring opt-in will be absent wherever someone was busy, and its absence is invisible.

This applies directly to templates: a template copied unchanged must not produce a weakened control. See [templates/](../../templates/).

### Fail closed

When a control cannot be evaluated, it fails closed. If SonarQube is unavailable, the Quality Gate has not passed — an unavailable gate is not a pass. If the vulnerability database is stale, the scan result is unreliable, not clean.

This is the principle most often abandoned under delivery pressure, and abandoning it converts an outage into a silent bypass.

### No bypass for convenience

Security controls are not disabled to unblock a release. Where a genuine business need requires an exception, it goes through the exception process: recorded, time-bounded, with a compensating control and an owner role. See [10-governance/](../10-governance/).

---

## 4. Approved Secret Mechanisms

At this stage:

- Jenkins Credentials
- environment-specific protected environment files held outside Git
- host-managed secrets

Vault or an equivalent may be recommended later based on scale and risk. It is not adopted now. Criteria that would justify it are in [secrets-management.md](secrets-management.md).

---

## 5. AI-Generated Content

All AI-generated documentation, configuration, pipeline code, and container definitions are **untrusted drafts** until reviewed by a qualified human.

Security-relevant AI-generated content requires security review before it is merged or adopted by any application team. This applies to every document in this repository, including this one.

---

## 6. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — severity thresholds that block promotion | [vulnerability-management.md](vulnerability-management.md) |
| `TBD` — secret rotation frequency per credential type | [secrets-management.md](secrets-management.md) |
| `TBD` — role-to-permission mapping per platform | [access-control.md](access-control.md) |
| `TBD` — SBOM format, storage, and retention | [sbom-standard.md](sbom-standard.md) |
| `TBD` — signing tooling, key custody, verification point | [container-image-signing.md](container-image-signing.md) |
| `TBD` — TLS termination points per interaction | [03-network/](../03-network/) |
| `TBD` — exception approval authority and maximum duration | [10-governance/](../10-governance/) |

---

## Security Considerations

The concentration of trust in Jenkins is this architecture's defining security property. It holds credentials for every environment, publishes artifacts, and changes production. Compromise of the controller is compromise of the delivery chain, and no downstream control detects it — the resulting deployments are legitimate in every observable respect.

Harbor is the second concentration, for the reason in section 1.

Neither can be removed at this scale. Both can be constrained: credential scoping, restricted administrative access, audit logging, and — once implemented — signing, which is the only control that lets a deployment target verify an artifact's origin independently of the registry that served it.

## Operational Considerations

A control that is defined but unenforced provides no protection and considerable false assurance. Section 2 exists to keep that distinction visible, and its Status column should be updated as controls are implemented rather than left to drift.

The controls most likely to erode are the ones with recurring cost: credential rotation, access review, base image updates, and restore testing. Each is easy to defer indefinitely because deferring one has no immediate consequence.

---

## Related

- [Secrets management](secrets-management.md)
- [Vulnerability management](vulnerability-management.md)
- [Software supply-chain security](software-supply-chain-security.md)
- [SBOM standard](sbom-standard.md)
- [Container image signing](container-image-signing.md)
- [Access control](access-control.md)
- [Repository security policy](../../SECURITY.md)
- [Enterprise DevOps architecture](../01-architecture/enterprise-devops-architecture.md)
