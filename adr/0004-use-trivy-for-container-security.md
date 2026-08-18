# ADR-0004 — Use Trivy for Container Security Scanning

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — security owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established. Alternatives were assessed analytically, not through comparative trials.

---

## Context

The pipeline needs to detect vulnerable dependencies and vulnerable container images before publication, and to generate an SBOM for later vulnerability response.

Requirements:

- Scan application dependencies, OS packages in images, filesystems, and configuration
- Detect secrets in source and image layers
- Run inside the pipeline, on a build agent, without an external service
- Produce a machine-readable verdict a gate can act on
- Generate SBOMs

---

## Decision

Trivy is the vulnerability and misconfiguration scanner.

In practice:

- Dependency and secret scanning run before the image is built.
- Image and misconfiguration scanning run after build, **before publication**.
- SBOM generation uses the same tool.
- Findings at or above the blocking threshold stop the pipeline before publication.
- Harbor performs its own scanning on push and re-scans stored images.

Blocking before publication rather than before deployment is deliberate: an image that fails policy should never enter the registry, because once it exists it is deployable and only a configuration change stands between it and production.

---

## Consequences

### Positive

- One tool covers dependencies, images, filesystems, configuration, secrets, and SBOM generation — fewer tools to operate and one findings format.
- Runs locally on the agent; no source code or image content leaves the network.
- No licensing cost.
- Harbor uses Trivy as its default scanner, so pipeline and registry findings are consistent.
- Developers can run the identical scan locally before pushing.

### Negative

- **The vulnerability database must be kept current.** In a network with controlled outbound access this is a real constraint: either the specific egress is permitted or an internal mirror is maintained.
- **A stale database produces a clean report indistinguishable from a genuinely clean scan.** That is worse than no scan, because false assurance is acted upon. See risk R-10.
- **Unfixable findings.** A critical vulnerability with no available fix cannot be remediated by upgrading. Blocking on it stops delivery without improving security and generates standing exceptions that hollow out the exception process.
- Scanning adds pipeline time on every build.
- Findings volume can be high initially, and a large backlog trains people to grant exceptions rather than fix.

### Neutral

- Trivy detects **known** vulnerabilities. It does not detect a deliberately introduced backdoor or a substituted dependency — those are supply-chain trust problems addressed by lockfiles, pinning, and trusted sources, not by scanning. See [software-supply-chain-security.md](../docs/07-security/software-supply-chain-security.md).

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Harbor's built-in scanning alone** | Harbor scans on push, which is *after* publication — too late to prevent a failing image existing. Pipeline scanning gates publication; registry scanning detects later disclosures. Both are needed, and they are the same engine |
| Grype | Comparable capability and a reasonable alternative. Trivy chosen for its broader scope in one tool — configuration and secret detection alongside vulnerabilities — and for alignment with Harbor's default. **Not compared through trials** |
| Clair | Image scanning only. Narrower scope, and would need supplementing for dependencies, configuration, and secrets |
| Snyk and comparable commercial services | Better remediation guidance and dependency intelligence. Rejected: source and dependency data leave the network, and recurring cost |
| Language-native tools (`npm audit`, `dotnet list package --vulnerable`) | Useful and complementary. Rejected as the gate: per-language formats, no image or configuration coverage, no SBOM |
| No scanning | Rejected. Vulnerability scanning is a mandatory control in the security baseline |

---

## Security Considerations

The failure behaviours matter more than the tool choice, and each needs an explicit decision rather than a default:

| Situation | Required behaviour |
| --- | --- |
| Scanner cannot run | Fail the build. Unable to evaluate is not a pass |
| Database is stale beyond threshold | Fail the build. `TBD` — the threshold |
| Finding at or above threshold | Block publication. `TBD` — the threshold |
| Unfixable finding | `TBD` — recommended: do not block; track separately, so the question becomes "why is this component still in use" |
| Secret detected | **Rotate the credential.** This is not a finding to triage against a severity threshold |

The last is worth separating from the rest. A detected secret is not a vulnerability with a severity; it is a credential to treat as compromised immediately.

Ignore-file entries are exceptions and carry every requirement of one: narrow scope, justification, compensating control, approver, and expiry. A `.trivyignore` has no concept of expiry, so without external enforcement an entry is permanent by construction.

## Operational Considerations

The database update path is the operational dependency to design before the first scan. Interaction I-14 in [service-interaction.md](../docs/01-architecture/service-interaction.md) is currently `TBD`: permitted egress or an internal mirror.

Thresholds must be set from a measured baseline. A threshold the existing codebase cannot meet blocks everything on day one; one nothing triggers is decoration. Blocking on new findings first, with the existing backlog on a schedule, requires measuring the backlog before enabling the gate.

Harbor pull-blocking on severity is a separate decision with a specific hazard: it can block a rollback to a previously good image that has since acquired a finding, at the moment rollback is needed. If enabled, an audited emergency path must exist. See [vulnerability-management.md](../docs/07-security/vulnerability-management.md).

---

## Review Trigger

Revisit if:

- The database update path proves unworkable in the network design, requiring a scanner with different distribution.
- Findings quality is poor enough that exceptions grow steadily — measure the exception count.
- SBOM format requirements exceed what Trivy produces.
- An organizational security tooling standard is adopted that mandates a different scanner.

---

## References

- [Vulnerability management](../docs/07-security/vulnerability-management.md)
- [SBOM standard](../docs/07-security/sbom-standard.md)
- [Software supply-chain security](../docs/07-security/software-supply-chain-security.md)
- [Security templates](../templates/security/)
