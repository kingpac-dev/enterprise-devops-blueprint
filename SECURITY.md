# Security Policy

## Purpose and Scope

This document describes security expectations for the Enterprise DevOps Blueprint **repository itself**, and how to report a security problem found in it.

It covers:

- what must never be committed to this repository
- how to report a vulnerability or exposed secret
- how to respond to a committed secret
- the security baseline this blueprint promotes

It does **not** replace the organization's information-security policy, and it is not the detailed security standard for delivered applications. That is planned under [docs/07-security/](docs/07-security/).

---

## 1. Repository Threat Model

This repository contains documentation, standards, and templates. It does not run in production and stores no application data. The realistic risks are:

| Risk | Impact |
| --- | --- |
| A real secret is committed | Credential compromise; Git history retains it after deletion |
| Internal hostnames, IPs, or topology are committed | Reconnaissance value to an attacker |
| An insecure template is copied into many projects | A single weak pattern is replicated organization-wide |
| A weakened standard is merged without review | Controls silently degrade across teams |
| An unsupported compliance claim is published | Audit and legal exposure |

The template-replication risk is the reason security review is required for template and standard changes.

---

## 2. Never Commit

Do not commit real values of:

- passwords
- access tokens and personal access tokens
- API keys
- JWT signing keys
- private certificates and private keys
- private SSH keys
- registry credentials
- database or production connection strings
- webhook secrets
- cloud or service-account credentials

Also avoid committing:

- real internal hostnames and DNS names
- real IP addresses and network ranges
- real firewall rules containing production addresses
- production topology detail beyond what documentation genuinely requires

Use `TBD` or clearly fictional example values instead.

### Acceptable Placeholders

```text
HARBOR_URL=https://harbor.example.internal
HARBOR_USERNAME=<jenkins-credential-id>
HARBOR_PASSWORD=<set-via-jenkins-credentials>
DB_CONNECTION_STRING=<set-per-environment>
JWT_SIGNING_KEY=<set-via-jenkins-credentials>
```

Only `*.env.example` files with placeholder values belong in Git. Generated `.env` files must not be committed.

---

## 3. Reporting a Security Issue

Report privately. Do not open a public issue or pull request that describes the problem in detail.

| Field | Value |
| --- | --- |
| Security contact | `TBD` |
| Reporting channel | `TBD` |
| Acknowledgement target | `TBD` |
| Initial assessment target | `TBD` |
| Resolution target by severity | `TBD` |

Until the contact channel is defined, report to the repository owner or platform team through an internal, non-public channel.

Include where possible:

- what the issue is
- affected file or path
- why it is a security problem
- suggested remediation
- whether a real secret or real infrastructure detail is exposed

Do not include the exposed secret value in the report. Reference its location instead.

---

## 4. If a Secret Is Committed

Treat the secret as compromised the moment it reaches a shared branch, even if it is deleted immediately. Git history and any clone, fork, mirror, or CI cache retain it.

Required response:

1. **Rotate first.** Revoke and reissue the credential at its source before anything else.
2. Notify the security contact and the credential owner.
3. Remove the value from the working tree and replace it with a placeholder.
4. Assess exposure: how long it was present, branch visibility, who cloned or forked, whether CI logs or artifacts captured it.
5. Review access logs of the affected system for misuse during the exposure window.
6. Decide on history rewrite with the repository owner. History rewriting is disruptive to all clones and is not a substitute for rotation.
7. Record the incident and its evidence.

Deleting the file is **not** remediation. Rotation is.

---

## 5. Security Baseline Promoted by This Blueprint

The blueprint promotes the following baseline across delivery. Detailed standards are planned under [docs/07-security/](docs/07-security/).

- least privilege
- defense in depth
- no hard-coded credentials
- no plaintext production secrets in Git
- TLS for sensitive network communication
- environment separation between DEV, UAT, and PROD
- restricted administrative interfaces, not publicly exposed without explicit justification and compensating controls
- dependency pinning where practical
- trusted, controlled base images
- CI credential isolation
- vulnerability scanning of dependencies, images, and configuration
- secret scanning
- SBOM generation
- an image-signing roadmap
- immutable production artifacts
- auditable production deployment
- backup and tested restore

Security controls must not be bypassed for convenience.

### Approved Secret Mechanisms (Initial)

- Jenkins Credentials
- environment-specific protected `.env` files held outside Git
- host-managed secrets

Adoption of Vault or an equivalent secret-management platform may be recommended later, based on scale and risk. It is not adopted at this stage.

---

## 6. Review Requirements for Security-Relevant Changes

A change is security-relevant when it touches:

- secrets handling or credential references
- access control or permission models
- network exposure, ports, or firewall guidance
- base images or image provenance
- scanning thresholds, severity policy, or exceptions
- production approval, deployment, or rollback controls
- audit and evidence requirements

Such changes require security review before merge. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 7. Vulnerability Handling in Delivered Software

Severity thresholds, blocking behaviour, exception process, and remediation SLAs are `TBD` and will be defined in the vulnerability-management standard under [docs/07-security/](docs/07-security/).

Baseline intent, pending that standard:

- Critical vulnerabilities block deployment unless an explicitly approved, time-bounded exception exists.
- Exceptions are recorded with owner role, justification, compensating control, and expiry.
- An expired exception is a control failure, not a default extension.

---

## 8. Claims and Evidence

This repository makes **no claim** of:

- certification
- formal compliance with any standard or regulation
- completed audit
- regulatory approval
- independently verified security testing

Recommendations here may be described as `aligned with` generally accepted practice — including DevOps and SRE principles, OWASP guidance, NIST secure software development guidance, and supply-chain security practice — without asserting formal compliance.

`Aligned with`, `recommended by`, `required by organization`, and `formally compliant with` are not interchangeable.

---

## 9. AI-Generated Content

All AI-generated documentation, configuration, pipeline code, and container definitions in this repository are **untrusted drafts** until reviewed by a qualified human.

Security-relevant AI-generated content requires security review before it is merged or adopted by any application team.
