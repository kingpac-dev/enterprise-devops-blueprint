# AGENTS.md

<!--
Copy to your repository root as AGENTS.md and replace every <placeholder>.
Delete these comments.

Keep this SHORT. It exists to record what is specific to this service, not to
restate the blueprint. A long project policy that duplicates organizational
standards drifts out of step with them, and then contradicts them.
-->

## Purpose

Project-level engineering and AI-governance policy for `<service-name>`.

This inherits the [Enterprise DevOps Blueprint](<link>) and its `AGENTS.md`. It **may add stricter requirements. It must never weaken them.** Where policies overlap, the stricter applies.

---

## 1. Before Substantial Work

1. Read the blueprint `AGENTS.md`.
2. Read this file.
3. Read [README.md](README.md), particularly the Configuration and Rollback sections.
4. Summarize the applicable policy for the task.
5. Surface conflicts before making affected changes.
6. Keep changes minimal and reviewable.

AI-generated output is an **untrusted draft** until reviewed by a human.

---

## 2. What Is Specific to This Service

<!--
The whole value of this file is in this section. Everything else is
inherited. Record what someone unfamiliar would get wrong.
-->

| | |
| --- | --- |
| **Service type** | Angular / .NET Web API / .NET Worker Service |
| **Has database migrations** | Yes / No |
| **Rollback available** | Yes / **No, because `<reason>`** |
| **Holds durable state** | Yes — `<volumes>` / No |
| **External side effects** | `<payments, emails, messages published — anything a rollback cannot undo>` |
| **Stop grace period** | `<seconds, and why>` |

### Constraints a change must respect

<!-- Examples. Replace with this service's actual constraints. -->

- `<This service publishes messages consumed by X. Changing the message
  schema is a BREAKING change even though no API changed — the consumer is
  the thing that breaks.>`
- `<Processing cycles can take up to N seconds. The stop grace period must
  exceed that, or a deployment kills work mid-transaction.>`
- `<Configuration value X must exist before deployment; the service fails at
  start without it, by design.>`

---

## 3. Requirements Beyond the Blueprint

<!--
Only genuinely stricter requirements. If there are none, say "None" — an
empty section is honest and a padded one is noise.
-->

None.

<!-- Or, for example:
- Changes to `<path>` require review by `<role>` in addition to the normal reviewer.
- Coverage threshold for this service is `<higher value>`, because `<reason>`.
-->

---

## 4. High-Risk Areas

Changes here need extra care and, where stated, an additional reviewer.

| Area | Why | Additional requirement |
| --- | --- | --- |
| `<path>` | `<reason>` | `<reviewer role, or none>` |

---

## 5. Never

Inherited from the blueprint, restated because these are the ones that cause real harm:

- Commit a secret. If one is committed, **report it immediately** — the credential is rotated, and nobody is in trouble for reporting quickly. A culture where this is embarrassing produces quiet deletions and unrotated live credentials in history.
- Compile an environment-specific value into the artifact. The same image is promoted to DEV, UAT, and PROD.
- Deploy `latest` to production.
- Merge a change with a rollback limitation without stating it in the pull request.
- Bypass a control for convenience. Where a control genuinely does not fit, request an exception — recorded, scoped, and with an expiry.

---

## 6. Testing Expectations

<!-- What "tested" means for this service specifically. -->

| Change type | Expected |
| --- | --- |
| `<business logic>` | `<unit tests covering the failure paths, not only the happy path>` |
| `<message handling>` | `<poison message, duplicate delivery, shutdown mid-processing>` |
| `<configuration>` | `<verify the service fails to start when a required value is absent>` |

State accurately what was run in the pull request. Reviewers calibrate their scrutiny against it, and the record is permanent.

---

## 7. Ownership

| | |
| --- | --- |
| Owning role | `<role, never an individual>` |
| Escalation | `<role>` |

An unowned service is an unmaintained service.
