# Developer Onboarding

## Purpose

Gets a developer productive on the platform without requiring them to read every standard.

## Scope

What a developer building applications needs. Platform engineers have a separate path in [devops-team-onboarding.md](devops-team-onboarding.md); setting up a new project is in [new-project-onboarding.md](new-project-onboarding.md).

## Audience

Developers joining a team, and whoever onboards them.

## Status

**Draft for review.** The platform described does not exist yet — see section 1. Access processes and tooling versions are undecided.

---

## 1. What You Are Onboarding To Today

The blueprint is documentation. The platform it describes has not been built.

Today, onboarding means understanding the standards your work will be held to. Once the platform exists, the access and setup sections below become real. Both are written here so the document does not need rewriting later, and so the distinction stays visible.

---

## 2. What You Must Read

39 standards exist. **You need five of them**, and one page of constraints.

| Read | Why |
| --- | --- |
| [Repository overview](../../README.md) | What this is and how it fits together |
| [Branching strategy](../04-source-control/branching-strategy.md) | How your work reaches production |
| [Pull request standard](../04-source-control/pull-request-standard.md) | What is expected of your changes |
| [Dockerfile standard](../06-container/dockerfile-standard.md) | How your application is packaged |
| [Observability standard](../08-observability/observability-standard.md) | What your service must expose |
| Section 3 below | The constraints that are not obvious |

Everything else is reference material — read it when the situation arises. A standard you read before you needed it is a standard you will not remember when you do.

Your project's own `README.md` and `AGENTS.md` may add stricter requirements. They never weaken these.

---

## 3. Ten Things That Will Catch You Out

These are the non-obvious constraints. Most onboarding friction comes from these ten.

**1. The same image goes to DEV, UAT, and PROD.** Configuration is supplied at run time. Anything compiled into the artifact cannot differ per environment.

**2. Angular makes that hard, and it is still required.** A naive build bakes the API URL into the bundle, which would mean one artifact per environment. Use the runtime configuration mechanism — see [dockerfile-standard.md](../06-container/dockerfile-standard.md#9-per-application-type).

**3. `latest` is never deployed to production.** Every deployment names an explicit, immutable version.

**4. Secrets never go in Git.** Not in code, not in `.env`, not in Compose files, not in build arguments. `ARG` values are readable in image history by anyone who can pull the image. If you commit one, say so immediately — the credential is rotated, not deleted.

**5. Logs go to stdout, structured, with no credentials.** Log files inside a container disappear with the container. A generic "log the whole exception" handler will log connection strings when a database connection fails.

**6. Liveness and readiness are different.** Liveness asks whether *this process* is healthy. If it checks the database, a slow database restarts every instance repeatedly and fixes nothing.

**7. Your container must exit cleanly on `SIGTERM`.** Use exec-form `ENTRYPOINT`. Shell form means the signal never reaches your application, and it is killed mid-work at the stop timeout.

**8. Never use a request ID, user ID, or full URL as a metric or log label.** Each distinct value creates a time series or a log stream. This is the standard way monitoring is destroyed by one well-meant change.

**9. After a release fix, the merge back to `develop` is not optional.** A fix that reaches `main` and not `develop` is reverted by the next release, a full cycle later, and you will believe it is fixed.

**10. A database migration usually means rollback is unavailable.** Say so in the pull request and the release notes, before merge. Redeploying the previous image does not undo a schema change.

---

## 4. Access

`TBD` — the request process and approving role.

| System | Typical developer access |
| --- | --- |
| GitHub | Write on your team's repositories |
| Jenkins | View builds; trigger non-production |
| SonarQube | View your projects |
| Harbor | Pull from your team's projects |
| Dashboards and metrics | Read — should be broad |
| Logs | `TBD` — likely scoped to your services |
| Production hosts | **None** |

Production host access is not a developer capability. Diagnosis is expected to be possible from dashboards and logs; where it is not, that is a gap in observability rather than a reason to grant host access.

---

## 5. Local Setup

`TBD` — required tooling and versions.

Expect to need: Git, Docker, Docker Compose, and your language toolchain at the version the project pins.

Two local practices worth adopting immediately:

- **Build the image locally before pushing.** Most pipeline failures at the container stage are reproducible in one command.
- **Never put real credentials in your local `.env`.** A local `.env` and a missing `.dockerignore` is how production credentials end up inside an image.

---

## 6. Your First Change

```text
1. Branch from develop: feature/<ticket>-<short-description>
2. Make one logical change
3. Build and test locally, including the container build
4. Open a pull request; state what, why, what you tested, and any risk
5. Wait for checks; fix rather than re-run
6. Address review comments; approvals reset when you push
7. Squash merge to develop
8. Confirm it deployed to DEV and behaves as expected
```

Step 5 is a habit worth forming early. A flaky check re-run until it passes is a check nobody trusts afterwards, including for the failure that was real.

Step 8 is yours. Merging is not delivering.

---

## 7. Where to Get Help

| Question | Source |
| --- | --- |
| How does the platform work? | [Architecture](../01-architecture/) |
| Why did my pipeline fail? | Pipeline output first; then [CI/CD](../05-ci-cd/) |
| Is my service healthy? | Dashboards |
| Something is broken in production | Escalate — see [governance](../10-governance/) |
| The standard seems wrong for my case | Say so. It may be wrong — see below |

`TBD` — team channels and contacts by role.

A standard that does not fit your case is useful information. Standards are written against the general case and reality produces cases they did not anticipate. The options are to improve the standard or to record an exception; the option that is not available is to ignore it silently.

---

## 8. What Is Expected of You

| Expectation | Reason |
| --- | --- |
| Your service is observable | Otherwise it cannot be safely deployed or diagnosed |
| Your pull requests are readable in one sitting | Review quality falls sharply with size |
| Your testing claims are accurate | Reviewers calibrate against them; the record is permanent |
| You state rollback limitations before merge | The approver needs them before approving |
| You do not bypass a control for convenience | Where a control genuinely does not fit, request an exception |
| You verify your change reached DEV and works | Merging is not delivering |

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — access request process and approving role | Day one |
| `TBD` — required local tooling and versions | Local setup |
| `TBD` — team channels and contacts by role | Getting help |
| `TBD` — whether an onboarding buddy is assigned | Time to productivity |
| `TBD` — expected time to first merged change | Onboarding effectiveness |

---

## Security Considerations

Item 4 in section 3 is the one that causes real harm. A committed secret is in history permanently, in every clone and CI cache, and deleting the file is not remediation. Reporting it immediately is; the credential is rotated, and nobody is in trouble for reporting quickly.

Item 5 is the quieter version of the same problem. Logs are centralized, retained for months, and readable by more people than the systems that produced them.

## Operational Considerations

The five-document reading list exists because a 39-document onboarding path is not read. Concentrating on what a developer needs on day one, with the rest available as reference, is what makes the standards usable rather than merely present.

Section 3 is the highest-value page in this document. Those ten constraints account for most of the friction a new developer encounters, and none of them is obvious from the code.

---

## Related

- [New project onboarding](new-project-onboarding.md)
- [DevOps team onboarding](devops-team-onboarding.md)
- [Source control standards](../04-source-control/)
- [Container standards](../06-container/)
- [Observability standards](../08-observability/)
