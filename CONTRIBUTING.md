# Contributing

## Purpose and Scope

This document describes how to propose, review, and merge changes to the Enterprise DevOps Blueprint repository.

It applies to human contributors and to AI assistants or coding agents operating on this repository.

It does **not** define the branching or release process for application repositories. That belongs to the source-control standard under [docs/04-source-control/](docs/04-source-control/).

---

## 1. Before You Start

1. Read [AGENTS.md](AGENTS.md). It is the authoritative engineering and AI-governance policy for this repository.
2. Check for a nested `AGENTS.md` closer to the files you intend to change. Nested policy may add stricter requirements.
3. Inspect existing structure and conventions before proposing structural change.
4. Identify conflicts between `AGENTS.md`, existing conventions, and your intended change **before** making it. Where policies overlap, follow the stricter requirement.

If your change would weaken a policy in `AGENTS.md`, do not make it silently. Raise it for review first.

---

## 2. What Belongs Where

| Content | Location |
| --- | --- |
| Standards and reference documentation | `docs/<NN>-<area>/` |
| Diagrams and decision-support material | `architecture/` |
| Cross-cutting engineering standards | `standards/` |
| Reusable pipeline, container, and configuration templates | `templates/` |
| Minimal reference implementations | `examples/` |
| Operational procedures | `runbooks/` |
| Standard operating procedures | `sop/` |
| Architecture Decision Records | `adr/` |

Do not duplicate the same policy in multiple documents. Link to the authoritative document instead.

---

## 3. Change Types

| Type | Examples | Requirement |
| --- | --- | --- |
| Editorial | Typos, formatting, clarification | Pull request, one reviewer |
| Additive | New document, new template, new example | Pull request, one reviewer with relevant domain knowledge |
| Standard change | Changing an existing requirement or recommendation | Pull request, reviewer plus platform owner acknowledgement |
| Architecture change | Adopting, replacing, or removing a platform component | ADR required in [adr/](adr/), plus review |
| Security-relevant change | Secrets handling, access control, network exposure, scanning thresholds, base images | Security review required |

Reviewer roles are role-based. Named individuals are `TBD` and will be recorded in the governance documentation under [docs/10-governance/](docs/10-governance/).

---

## 4. Branching and Pull Requests

Baseline for this repository:

```text
feature/<short-description>   Work in progress
main                          Reviewed blueprint baseline
```

Rules:

- Do not commit directly to `main`.
- One logical change per pull request. Keep change sets small and reviewable.
- Do not mix unrelated refactoring into a functional change.
- Rebase or merge from `main` before requesting review if the branch is stale.

Suggested branch names:

```text
feature/add-ci-standard
feature/adr-0002-harbor
fix/broken-links-observability
```

---

## 5. Commit Messages

Use a short imperative subject and, where useful, a body explaining the reason for the change.

```text
Add CI standard for Angular applications

Documents the required pipeline stages, coverage threshold, and
Quality Gate behaviour. Coverage threshold is TBD pending team input.
```

Do not record secrets, credentials, internal hostnames, or IP addresses in commit messages.

---

## 6. Pull Request Expectations

A pull request should state:

- what changed
- why it changed
- which policy sections in `AGENTS.md` apply
- which validation was actually performed
- remaining `TBD` items
- known risks
- items requiring human review

Do not state that validation, testing, security review, or compliance was performed unless it actually was.

---

## 7. Documentation Requirements

Every document must:

- use Markdown
- use clear professional English
- keep code, identifiers, commands, variables, comments, and configuration in English
- have a clear title
- state purpose and scope
- state assumptions where relevant
- distinguish requirements from recommendations
- identify security considerations where applicable
- identify operational considerations where applicable
- use relative links for internal repository references
- mark unknown organization-specific values as `TBD`

Use Mermaid for diagrams where practical.

### Language Precision

These terms are not interchangeable:

| Term | Meaning |
| --- | --- |
| `Required by organization` | Mandatory in this organization |
| `Recommended by` | Advised by a named external source or by this blueprint |
| `Aligned with` | Consistent with a named practice, without formal verification |
| `Formally compliant with` | Independently verified against a named standard |

Do not use `compliant with` unless formal evidence exists. Do not claim certification, audit completion, or regulatory approval.

---

## 8. Architecture Decision Records

Create an ADR when a change:

- adopts, replaces, or removes a platform component
- changes the environment or promotion model
- changes the artifact, versioning, or release identity model
- changes production approval, access, or rollback behaviour
- introduces a significant new operational or security obligation

Process:

1. Copy [adr/adr-template.md](adr/adr-template.md).
2. Number it sequentially: `adr/NNNN-short-title.md`.
3. Fill in every section. Do not fabricate historical discussions that did not happen.
4. Set `Status` to `Proposed` in the pull request.
5. Change `Status` to `Accepted` only after review approval.
6. Supersede rather than delete an outdated ADR. Link both directions.

---

## 9. Security Rules for Contributors

Never commit real secrets. This includes passwords, tokens, API keys, JWT signing keys, private certificates, private SSH keys, registry credentials, and production connection strings.

Use obvious placeholders in templates and examples:

```text
HARBOR_USERNAME=<jenkins-credential-id>
DB_PASSWORD=<set-via-jenkins-credentials>
API_BASE_URL=https://api.example.internal
```

Additional rules:

- Do not commit real internal hostnames, IP addresses, or network topology detail. Use `TBD` or clearly fictional example values.
- Do not commit generated `.env` files. Only `*.env.example` files with placeholder values belong in Git.
- Do not include insecure example configuration, even to illustrate a point, unless it is explicitly labelled as an anti-pattern.
- Do not weaken a security control for convenience.

If a secret is committed, treat it as compromised. Follow [SECURITY.md](SECURITY.md).

---

## 10. AI Assistant and Agent Rules

AI-generated output is an **untrusted draft** until reviewed and validated by a human.

Agents must:

1. Read [AGENTS.md](AGENTS.md) before substantial work.
2. Summarize the applicable policy sections for the task.
3. Search for nested `AGENTS.md` files.
4. Report policy conflicts before making affected changes.
5. Keep changes minimal, focused, and reviewable.
6. Avoid unrelated refactoring.
7. Stop and surface missing assumptions for high-risk changes involving production, credentials, access control, networking, deployment, data loss, or destructive operations.
8. Report accurately what was and was not validated.

Agents must not claim that tests passed, security was verified, or compliance was achieved without verifiable evidence.

---

## 11. Validation Before Requesting Review

Check what can actually be checked:

- Markdown links resolve, and relative paths are correct
- no duplicated guidance across documents
- terminology is consistent
- environment names are consistently `DEV`, `UAT`, `PROD`
- image tagging examples are consistent with the container standard
- no secret-looking values are present
- no insecure example configuration is presented as recommended
- no contradiction with an existing standard or ADR
- placeholder content is not presented as final
- unsupported claims are removed

Where tooling is available, validate YAML syntax, Docker Compose syntax, Dockerfile behaviour, Jenkins pipeline syntax, and Mermaid syntax.

Record in the pull request which of these were actually run and which were not.

---

## 12. Change Reporting

After a logical implementation phase, summarize:

- files created or changed
- important design decisions
- validation actually performed
- remaining `TBD` items
- risks
- items requiring human review

Keep the summary concise and evidence-based.
