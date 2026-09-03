# Project Template

## Purpose

A complete starting layout for a new application repository, assembled from the individual templates in this directory tree.

## Scope

Repository structure, required root files, and the deployment configuration layout. Onboarding steps are in [docs/12-onboarding/](../../docs/12-onboarding/).

## Status

**Draft for review.** Eight files written. Together with [docker/](../docker/), [compose/](../compose/), [jenkins/](../jenkins/), [sonar/](../sonar/), and [security/](../security/), a new repository can be assembled today for any of the five supported application types. Deployment configuration now has a decided mechanism — [ADR-0010](../../adr/0010-portainer-gitops-deployment.md) — which is not yet implemented in the pipeline templates.

---

## Target Application Repository Layout

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
├── README.md
└── AGENTS.md
```

Do not force directories a project does not need. A worker service without a public API does not need the same structure as a frontend.

---

## Contents

| File | Intent | Status |
| --- | --- | --- |
| [README.template.md](README.template.md) | Application README: identity, dependencies, configuration reference, observability, rollback | Draft |
| [AGENTS.template.md](AGENTS.template.md) | Project policy that inherits the blueprint and records only what is service-specific | Draft |
| [RELEASE-NOTES.template.md](RELEASE-NOTES.template.md) | Per-release notes the approver reads **before** approving | Draft |
| [VERSION](VERSION) | The version the pipeline reads to build the image tag | Draft |
| [.gitignore.angular](.gitignore.angular) | Angular ignore rules | Draft |
| [.gitignore.react-vite](.gitignore.react-vite) | React + Vite ignore rules | Draft |
| [.gitignore.go](.gitignore.go) | Go ignore rules; `go.sum` and `vendor/` deliberately **not** ignored | Draft |
| [.gitignore.dotnet](.gitignore.dotnet) | .NET ignore rules; `packages.lock.json` deliberately **not** ignored | Draft |

Deployment configuration comes from [templates/compose/](../compose/), which already provides `compose.dev.yml`, `compose.uat.yml`, `compose.prod.yml`, and `.env.example`.

## Assembling a New Repository

```text
project/
├── src/                     your code
├── tests/                   your tests
├── deployment/
│   ├── dev/compose.yml      <- templates/compose/compose.dev.yml
│   ├── uat/compose.yml      <- templates/compose/compose.uat.yml
│   ├── prod/compose.yml     <- templates/compose/compose.prod.yml
│   └── .env.example         <- templates/compose/.env.example
├── Jenkinsfile              <- templates/jenkins/Jenkinsfile.<type>
├── Dockerfile               <- templates/docker/Dockerfile.<type>
├── .dockerignore            <- templates/docker/.dockerignore.<type>
├── .gitignore               <- .gitignore.<type>
├── .gitattributes           <- see docs/04-source-control/git-standard.md
├── sonar-project.properties <- templates/sonar/sonar-project.properties.<type>
├── trivy.yaml               <- templates/security/trivy.yaml
├── VERSION                  <- VERSION
├── README.md                <- README.template.md
└── AGENTS.md                <- AGENTS.template.md
```

The ordered checklist, with what is currently blocked, is in [new-project-onboarding.md](../../docs/12-onboarding/new-project-onboarding.md).

## Three Sections That Prevent Specific Failures

| Section | Failure it prevents |
| --- | --- |
| README **Configuration** table | A release requiring a new value deploys successfully and then fails at run time, in production, on the values nobody set |
| README **Rollback**, including "last verified" | Rollback designed but never executed is an assumption. The date is the row that matters |
| RELEASE-NOTES **Configuration Changes**, stated even when "None" | Same as the first, caught at approval rather than at deployment |

## The `VERSION` File

The Jenkins templates read it: `readFile('VERSION').trim()`.

It is the concrete default. Alternatives — deriving the version from the Git tag, or from commit messages under a structured convention — remain open in [release-and-tagging-standard.md](../../docs/04-source-control/release-and-tagging-standard.md). Whichever is chosen, the pipeline and this file must agree; two sources of truth that disagree is worse than one.

## `packages.lock.json` Is Not Ignored

[.gitignore.dotnet](.gitignore.dotnet) deliberately does not ignore it, with a comment saying so.

Without a committed lockfile, the same commit resolves different dependency versions on different days — and `dotnet restore --locked-mode` in the pipeline fails outright. The default .NET `.gitignore` circulating widely does not include it, so this is easy to get wrong by copying.

---

## A Note on Link Checking

`*.template.md` files contain `<placeholder>` links and relative links such as `AGENTS.md` that resolve in the **destination** repository, not in this one. A repository-wide link check must exclude them, or it will report them as broken on every run — and a checker that always reports failures is a checker nobody reads.

## Inheritance Rule

A project-level `AGENTS.md` may add stricter requirements than the blueprint. It must not silently weaken them. Where policies overlap, the stricter requirement applies.

---

## Related

- [Templates index](../README.md)
- [Onboarding](../../docs/12-onboarding/)
- [Source control standards](../../docs/04-source-control/)
- [Examples](../../examples/)
