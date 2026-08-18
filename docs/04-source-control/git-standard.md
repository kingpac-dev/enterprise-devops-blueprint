# Git Standard

## Purpose

Defines repository structure, naming, commit conventions, and protection settings for application repositories.

## Scope

Application repositories on GitHub. Contribution rules for **this blueprint repository** are in [CONTRIBUTING.md](../../CONTRIBUTING.md) and are not repeated here.

## Audience

All developers, and platform engineers configuring repositories.

## Status

**Draft for review.** Reviewer counts and required status checks are undecided.

---

## 1. One Application, One Repository

The default is one repository per deployable application.

| Model | When |
| --- | --- |
| One repository per application | Default |
| One repository containing several closely coupled services | Only where the services are always released together |
| A shared library repository | For code genuinely reused across applications |

The default is not a rejection of monorepos, which solve real problems at larger scale. It is a consequence of the delivery model: the pipeline builds one artifact per repository, tags it with the repository's commit, and promotes it. A repository containing three independently released services needs path-based build triggering and per-service versioning before it can work at all, and that complexity should be adopted deliberately rather than arrived at.

---

## 2. Repository Naming

`TBD` — the convention. Whatever is chosen must be consistent, because the repository name propagates into the Jenkins job name, the SonarQube project key, the Harbor project or image name, and the service label in metrics and logs.

A name that differs between those systems means every cross-system question requires a translation step, performed by a person, during an incident.

Proposal:

```text
<domain>-<application>-<type>

orders-api
orders-worker
orders-web
```

Lowercase, hyphenated, no organizational prefixes that change when teams reorganize.

---

## 3. Repository Contents

```text
project/
├── src/
├── tests/
├── docker/
├── deployment/
│   ├── dev/
│   ├── uat/
│   └── prod/
├── docs/
├── Jenkinsfile
├── Dockerfile
├── compose.yml
├── .dockerignore
├── .gitignore
├── .gitattributes
├── README.md
└── AGENTS.md
```

Do not create directories a project does not need. A worker with no HTTP surface does not need the same structure as a frontend.

### Required files

| File | Purpose |
| --- | --- |
| `README.md` | What it is, how to build, run, test, and deploy it; who owns it |
| `AGENTS.md` | Project-level policy; may add stricter requirements than the blueprint, never weaker |
| `Jenkinsfile` | The pipeline, in version control and therefore reviewable |
| `Dockerfile` | See [dockerfile-standard.md](../06-container/dockerfile-standard.md) |
| `.dockerignore` | Prevents `.git`, `.env`, and build output entering the build context |
| `.gitignore` | Prevents build output, local configuration, and environment files being committed |
| `.gitattributes` | Line-ending normalization — see section 6 |
| Lockfile | `package-lock.json` or `packages.lock.json`; required for reproducible builds |

The lockfile is a supply-chain requirement, not a convenience. Without one, a build resolves the newest version satisfying each range, so the same commit produces different dependency sets on different days — see [software-supply-chain-security.md](../07-security/software-supply-chain-security.md#3-dependency-trust).

The `README.md` must name an **owning role**, not an individual. A repository whose owner left and was never reassigned is a repository nobody maintains.

---

## 4. Never in Git

- credentials, tokens, keys, certificates with private material, connection strings
- `.env` files containing real values — only `*.env.example` with placeholders
- build output, `node_modules`, `bin`, `obj`, coverage reports
- large binary assets without a deliberate decision
- production data, or personal data of any kind

Git history is permanent for practical purposes. A secret committed and then deleted remains in history, in every clone, fork, and mirror, and in any CI cache. Deleting the file is not remediation — **rotate the credential**. See [SECURITY.md](../../SECURITY.md#4-if-a-secret-is-committed).

`TBD` — secret scanning tooling, and whether it runs on push, in the pipeline, or both.

---

## 5. Commits

| Rule | Reason |
| --- | --- |
| One logical change per commit | Reviewable; revertable |
| Imperative subject, under about 72 characters | Consistent with Git tooling output |
| Body explains **why**, not what | The diff already shows what |
| Reference the ticket where one exists | Links code to the reason it was written |
| Never commit a credential, hostname, or IP in a message | Messages are as permanent as content |

```text
Retry order submission on transient gateway failure

The payment gateway returns 503 during its nightly maintenance
window, which currently fails the order. Retry with backoff for
transient status codes only; 4xx still fails immediately.

Refs: TBD-1234
```

`TBD` — whether a structured commit convention such as Conventional Commits is adopted. It enables automated changelog and version derivation, at the cost of a format everyone must follow. That decision belongs with the versioning decision in [release-and-tagging-standard.md](release-and-tagging-standard.md).

### Commit identity matters more here than usual

The image identity scheme tags images with the commit that produced them — see [image-versioning.md](../06-container/image-versioning.md). A commit is therefore not only history; it is the thing a production deployment record points at.

Two consequences:

- **Build promotable images only from protected branches.** A commit on a feature branch may never exist on `develop` in that form, particularly under squash merging.
- **Never force-push a protected branch.** Doing so can orphan a commit that a deployed image references, breaking the traceability chain for artifacts already in production. See section 7.

---

## 6. Line Endings

Every repository includes a `.gitattributes` normalizing line endings.

```text
* text=auto eol=lf
*.sh          text eol=lf
Dockerfile    text eol=lf
Jenkinsfile   text eol=lf
*.yml         text eol=lf
*.ps1         text eol=crlf
```

This is not cosmetic. A shell script or Dockerfile authored on Windows with CRLF endings fails on a Linux build agent, and the error message — typically about a command not being found, with an invisible carriage return in the name — gives no indication of the cause.

---

## 7. Branch Protection

`TBD` — exact configuration. Required on `main` and `develop`:

| Setting | Requirement | Reason |
| --- | --- | --- |
| Require a pull request before merging | Yes | No direct pushes to protected branches |
| Require approving reviews | `TBD` — count | Review boundary |
| Dismiss stale approvals on new commits | Yes | An approval applies to what was reviewed |
| Require status checks to pass | Yes; `TBD` — which | The quality boundary |
| Require branches to be up to date before merging | `TBD` | Prevents merging against a stale base |
| Require conversation resolution | Yes | Review comments are addressed, not ignored |
| **Block force pushes** | Yes | See below |
| **Block deletion** | Yes | |
| Include administrators | `TBD` — recommended yes | A protection administrators bypass is a suggestion |

Force-push protection is the setting with the least obvious justification and one of the more serious consequences. Rewriting the history of a protected branch can remove a commit that a deployed image was built from. The image still runs; the deployment record still names the commit; the commit is no longer reachable in the branch. The audit trail then points at nothing, and it does so silently.

The "include administrators" setting is where branch protection is usually quietly defeated. If those who can bypass a control routinely do, the control describes intent rather than behaviour.

---

## 8. Repository Provisioning

New repositories are created from a template with protection, required checks, and required files already configured.

Manual provisioning produces repositories that differ in ways nobody notices until one is found to have had no required checks for six months.

`TBD` — the provisioning mechanism, and whether repository settings are managed as code. Managing them as code makes the settings reviewable and drift detectable, which is the same argument applied to pipelines and dashboards elsewhere in this blueprint.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — repository naming convention, consistent across GitHub, Jenkins, SonarQube, Harbor | Cross-system traceability |
| `TBD` — required approving review count | Review boundary |
| `TBD` — required status checks per application type | Quality boundary |
| `TBD` — whether administrators are included in protection | Whether protection is real |
| `TBD` — structured commit convention | Automated versioning and changelogs |
| `TBD` — secret scanning tooling and where it runs | Detection of committed secrets |
| `TBD` — repository provisioning and settings-as-code | Consistency across repositories |
| `TBD` — large binary asset handling | Repository size |

---

## Security Considerations

Section 4 is the important one, and the reason is the permanence of history rather than the mistake itself. Every clone, fork, mirror, and CI cache retains what was committed, so remediation is rotation and cleanup is secondary.

Branch protection is the enforcement point for the review boundary described in [logical-architecture.md](../01-architecture/logical-architecture.md#3-boundaries). Protection that administrators bypass, or that permits force pushes, does not enforce that boundary.

Signed commits are not required at this stage. They address commit attribution, which is a lower-order risk here than artifact substitution — see [software-supply-chain-security.md](../07-security/software-supply-chain-security.md#2-trust-points).

## Operational Considerations

Naming consistency across GitHub, Jenkins, SonarQube, Harbor, and the observability labels is worth more than it appears. Every inconsistency becomes a translation step performed by a person under time pressure, and translation steps are where incidents acquire their extra minutes.

Repository provisioning from a template is what prevents settings drift. Repositories created by hand diverge, and the divergence is discovered when someone asks why a merge was possible.

---

## Related

- [Branching strategy](branching-strategy.md)
- [Pull request standard](pull-request-standard.md)
- [Release and tagging standard](release-and-tagging-standard.md)
- [Image versioning](../06-container/image-versioning.md)
- [Software supply-chain security](../07-security/software-supply-chain-security.md)
- [Repository security policy](../../SECURITY.md)
