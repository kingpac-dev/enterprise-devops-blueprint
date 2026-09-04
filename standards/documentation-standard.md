# Documentation Standard

## 1. Purpose

Defines authoring standards, structural conventions, diagramming rules, and terminology precision for all technical documentation within the repository.

## 2. Mandatory Document Structure

Every standard, architecture document, and runbook must begin with the following baseline sections:

```markdown
# [Document Title]

## 1. Purpose
State concisely what problem this document solves and why it exists.

## 2. Scope
Explicitly define what is covered and what is deliberately excluded.

## 3. Audience
State who this document is written for (e.g., developers, DevOps, security).

## 4. Status
Explicitly state document maturity: `Draft for review`, `Published baseline`, or `Deprecated`.
```

---

## 3. Terminology & Precision Rules

To preserve audit integrity and technical honesty:

### 3.1 Avoid Unsupported Claims
- **Do not use** phrases like `compliant with ISO-27001` or `certified secure` unless independent audit evidence is attached.
- **Use precise phrasing**: `aligned with`, `recommended by`, `required by organizational policy`.

### 3.2 Distinguish Requirements vs Recommendations
- **Requirement (Must/Shall)**: Mandatory condition. Deviation requires a formal documented exception.
- **Recommendation (Should/May)**: Best-practice guidance. Teams may deviate if a documented rationale exists.

### 3.3 Explicit Treatment of Unknowns
- Mark organization-specific parameters that are not yet decided as `TBD` (e.g., `TBD: Production IP CIDR`).
- Never invent fictitious IP addresses or server names as finalized production values.

---

## 4. Diagram Conventions (Mermaid)

- Use **Mermaid** for all architecture and flow diagrams so diagrams remain version-controlled and diffable.
- Quote node labels with special characters: `id["Orders API (:8080)"]`.
- Avoid raw HTML formatting inside node labels.
- Validate Mermaid syntax before submitting pull requests.

---

## 5. Linking & References

- Use **relative markdown links** for all repository-internal navigation (e.g., `[Jenkins Standard](../docs/05-ci-cd/jenkins-architecture.md)`).
- Never use machine-specific absolute file system paths in repository documents.
- Keep links checked and updated during reorganizations.

---

## 6. Code & Configuration Block Standards

- Always specify the language identifier for fenced code blocks (e.g., ```` ```yaml ````, ```` ```bash ````, ```` ```json ````, ```` ```dockerfile ````, ```` ```csharp ````, ```` ```typescript ````, ```` ```go ````).
- **Placeholder Rule**: Never commit real secrets, private certificates, or internal production tokens in examples. Use standardized placeholders:
  - Secrets: `${SECRET_NAME:-change-me-in-production}` or `<YOUR_SECURE_PASSWORD>`
  - Domain: `devops.local` or `example.internal`
  - IPs: `10.0.x.x` or `192.168.1.x`
- Ensure all example configurations are syntactically valid and parseable by standard tooling.

---

## 7. Document Maturity Lifecycle

All technical documents must declare their status in the header block using one of the following states:

| Status | Definition | Review & Change Requirement |
| --- | --- | --- |
| **`Draft for review`** | Initial proposal or undergoing peer review. Not yet enforced in production gates. | Changes accepted via PR without formal architecture committee approval. |
| **`Published baseline`** | Ratified organizational standard. Enforced in CI/CD quality gates and operations. | Requires architecture review and update to related ADRs if changed. |
| **`Deprecated`** | Superseded by newer architecture or process. Kept for historical reference. | Must include explicit relative link to the superseding document. |
