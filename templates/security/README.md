# Security Templates

## Purpose

Reusable scanning and supply-chain configuration used by the pipeline.

## Scope

Trivy configuration, ignore policy, secret-scanning configuration, and SBOM generation. Security policy is defined in [docs/07-security/](../../docs/07-security/).

## Status

**Draft for review.** All four are written. **Every threshold is `TBD`**, and key names in `trivy.yaml` must be verified against the installed Trivy version.

---

## Templates

| File | Intent | Status |
| --- | --- | --- |
| [trivy.yaml](trivy.yaml) | Scan types, blocking severity, exit behaviour, database policy | Draft |
| [.trivyignore.example](.trivyignore.example) | Ignore-entry format with justification, compensating control, approver, and expiry | Draft |
| [secret-scanning.md](secret-scanning.md) | Where scanning runs, the response procedure, false positives, what it does not cover | Draft |
| [sbom-generation.md](sbom-generation.md) | Commands, storage independent of image retention, querying, limitations | Draft |

## Three Points Worth Reading Before Adopting

**An unrecognised key in `trivy.yaml` is silently ignored.** The schema has changed between major versions, so a mistyped or outdated key produces a scan that runs with defaults while appearing to be configured. Verify against your installed version.

**A detected secret is not a finding to triage.** It is a credential to treat as compromised, and the first action is rotation — not assessment, not an exception, not a ticket. By the time it is detected the exposure is already complete: it is in history, in every clone and mirror, and in any CI cache. Deleting the file changes none of that.

**`.trivyignore` has no concept of expiry.** Every entry is an exception to a security control, and nothing in the file format enforces the expiry date written in its comment. Without an external check comparing those dates against today, entries are permanent by construction — and invisible precisely because they work.

## Validation Performed

| Check | Result |
| --- | --- |
| `trivy.yaml` YAML syntax | Valid |
| No real credential in any template | Confirmed |
| **Key names against the installed Trivy version** | **Not run — Trivy not available in this environment** |
| **A scan executed against a real image** | **Not run** |

---

## Trivy Scope

- filesystem vulnerabilities
- container image vulnerabilities
- dependency vulnerabilities
- misconfiguration detection
- secret detection where appropriate

Critical vulnerabilities should block deployment unless an explicitly approved exception exists.

---

## Ignore-Entry Rules

Every ignore entry must record:

- the vulnerability identifier
- why it does not apply, or what compensating control exists
- the approving role
- an expiry date

An ignore file without justification and expiry becomes a permanent, invisible exception. Entries must be reviewed on expiry — an expired entry is a control failure, not a default extension.

---

## Open Items

- `TBD` — severity thresholds that block the pipeline
- `TBD` — exception approval authority and maximum exception duration
- `TBD` — SBOM format (for example SPDX or CycloneDX) and retention location
- `TBD` — image signing tooling and verification enforcement point

---

## Related

- [Templates index](../README.md)
- [Security standards](../../docs/07-security/)
- [Repository security policy](../../SECURITY.md)
- [Jenkins templates](../jenkins/)
