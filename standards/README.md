# Standards

## Purpose

Cross-cutting engineering standards that are not owned by a single documentation area.

## Scope

Conventions that apply across multiple areas — naming, tagging, documentation structure, environment identifiers, and versioning of the blueprint's own artifacts.

## Status

**Skeleton.** No standards published yet.

---

## Boundary With `docs/`

`docs/` is organized by domain: architecture, CI/CD, container, security, and so on. Most standards belong there, next to the context that explains them.

This directory holds **only cross-cutting conventions** — those that would otherwise have to be repeated in several `docs/` areas. Placing a standard here is a deliberate decision, not a default.

| Content | Belongs here? |
| --- | --- |
| Naming conventions used by repositories, images, Harbor projects, and Jenkins jobs | Yes |
| Environment identifiers (`DEV`, `UAT`, `PROD`) used consistently everywhere | Yes |
| Documentation structure and authoring conventions | Yes |
| CI pipeline stage definitions | No — belongs in [docs/05-ci-cd/](../docs/05-ci-cd/) |
| Dockerfile requirements | No — belongs in [docs/06-container/](../docs/06-container/) |
| Secrets handling | No — belongs in [docs/07-security/](../docs/07-security/) |

Test to apply: if the convention would need to be restated in **two or more** `docs/` areas to be usable, it belongs here and those areas link to it. If it belongs to one domain, it stays in that domain.

---

## Planned Documents

| File | Intent | Status |
| --- | --- | --- |
| `naming-conventions.md` | Repository, branch, image, Harbor project, and Jenkins job naming | Planned |
| `environment-identifiers.md` | Canonical environment names and where each is used | Planned |
| `documentation-standard.md` | Required document structure, tone, and terminology precision | Planned |

---

## Related

- [Documentation index](../docs/README.md)
- [Contribution process](../CONTRIBUTING.md)
- [Engineering and AI-governance policy](../AGENTS.md)
