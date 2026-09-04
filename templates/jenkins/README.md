# Jenkins Templates

## Purpose

Reusable `Jenkinsfile` templates implementing the CI/CD standard for each supported application type.

## Scope

Pipeline definitions and shared-library usage patterns. The rules these pipelines enforce are defined in [docs/05-ci-cd/](../../docs/05-ci-cd/).

## Status

**Draft for review.** Six templates, covering five application types. Stages from checkout through publication are complete.

**Deployment is implemented.** Pull-based via Portainer GitOps — [ADR-0010](../../adr/0010-portainer-gitops-deployment.md). Every pipeline calls [deploy-gitops.sh](deploy-gitops.sh), which updates the desired state, triggers Portainer, **waits for convergence**, and rolls back on timeout.

---

## Templates

| File | Target | Stages | Status |
| --- | --- | --- | --- |
| [deploy-gitops.sh](deploy-gitops.sh) | **The deploy step.** Shared by every pipeline | — | Published, **tested** |
| [Jenkinsfile.template](Jenkinsfile.template) | Generic reference, heavily commented | 15 | Published |
| [Jenkinsfile.angular](Jenkinsfile.angular) | Angular applications | 14 | Published |
| [Jenkinsfile.react-vite](Jenkinsfile.react-vite) | React + TypeScript + Vite | 14 | Published |
| [Jenkinsfile.go-fiber](Jenkinsfile.go-fiber) | Go Fiber APIs | 15 | Published |
| [Jenkinsfile.dotnet-api](Jenkinsfile.dotnet-api) | .NET Web APIs | 15 | Published |
| [Jenkinsfile.dotnet-worker](Jenkinsfile.dotnet-worker) | .NET Worker Services | 14 | Published |
| [shared-library/](shared-library/) | Enterprise Shared Library with reusable steps and pipeline wrapper | — | Published |

Each is complete and runnable on its own. Two stages remain deliberately disabled with `when { expression { return false } }` so the gap stays visible in the stage view rather than absent and forgotten: **image signing** (Phase 3, not adopted) and **database migration** (tooling undecided).

## The Deploy Step

[deploy-gitops.sh](deploy-gitops.sh) is the one piece of real logic shared by every pipeline, and the reason it exists is the property that separates pull-based deployment from push-based:

> **"The pipeline finished" and "the host converged" are different moments.**

Without waiting for convergence there is nothing to verify and automatic rollback has no trigger — the pipeline would report on its own actions rather than on the system.

```text
1. Clone the deployment repository
2. Read the CURRENT version        <- this is the rollback target, captured first
3. Update the tag; verify the write did exactly what was intended
4. Commit  <- the commit message IS the deployment record
5. Push, with rebase-and-retry on conflict
6. Call the Portainer webhook
7. POLL until the RUNNING version matches, or time out
8. On timeout: revert, push, trigger again  <- this is the rollback
```

| Exit | Meaning | Pipeline response |
| --- | --- | --- |
| 0 | Deployed and converged | Continue |
| 1 | Precondition failure — **nothing changed** | Fail |
| 2 | Push failed — **nothing deployed** | Fail; retry is safe |
| 3 | Did not converge; **rolled back** | Fail. Recovery not yet verified |
| **4** | Did not converge; **rollback also failed** | **Page someone** |

Three behaviours are worth knowing before adopting it:

**It refuses `latest`.** Portainer Community Edition cannot force an image re-pull, so a moving tag redeploys the **old** image and reports success. The script fails rather than allowing it.

**Without `VERSION_PROBE` it warns and succeeds.** Convergence is then unverified and the outcome unknown — acceptable while bootstrapping, not for production.

**It captures the rollback target before changing anything.** Determining it afterwards, from a system that may already be failing, is how rollbacks get stuck.

## Duplication Is Deliberate and Temporary

The per-type files share most of their content, which the CI/CD standard warns against. A Jenkins Shared Library is the resolution and it is **Phase 5** work — a library written before several services have run through this pipeline encodes patterns that were predicted rather than used.

The stages marked `[LIBRARY CANDIDATE]` in [Jenkinsfile.template](Jenkinsfile.template) are the ones to factor out when that time comes.

## The .NET Stage Order Differs, and It Matters

The .NET Sonar scanner must **wrap** build and test:

```text
sonarscanner begin  ->  build  ->  test  ->  sonarscanner end
```

It hooks the compiler to collect analysis during compilation. Running it after the build — as the generic stage list implies — produces an analysis with no results, and **the Quality Gate then passes on nothing**. That is a gate that appears to work and checks nothing, which is worse than no gate.

`--no-incremental` is required for the same reason: an incremental build skips compilation of unchanged projects, and the scanner only sees what is actually compiled.

## Credential Handling: `set +x`

Jenkins runs `sh` steps with `-x` in many configurations, which echoes each command — **including any credential in it** — into a build log that is widely readable and long-lived.

Every `withCredentials` block in these templates opens with `set +x`. Removing it turns a correct pipeline into one that publishes its own registry password on every run.

## What Blocks and What Does Not

| Stage | Behaviour |
| --- | --- |
| Quality Gate | `abortPipeline: true`. An unavailable SonarQube throws — an unevaluated gate is not a pass |
| Dependency and secret scan | `--exit-code 1`. Runs before the image is built |
| Container scan | `--exit-code 1`. Runs **before publication**, so a failing image never enters the registry |
| SBOM generation | Should block publication — `TBD`, confirm |
| Push to Harbor | Only from protected branches. Feature branches verify but do not publish |

Blocking before publication rather than before deployment is deliberate. Once an image exists in the registry it is deployable, and only a configuration change stands between it and production.

## Validation Performed

| Check | Result |
| --- | --- |
| Balanced braces, parentheses, and triple-quoted blocks | Pass, all six |
| Exactly one `pipeline {}` block per file | Pass |
| Every `withCredentials` block has a matching `set +x` | Pass |
| No plaintext credential — all referenced by credential id | Pass |
| **`deploy-gitops.sh` — `sh -n` and `dash -n`** | **Pass** (POSIX) |
| **`deploy-gitops.sh` — executed against a real git repository** | **Pass.** Deploy, idempotent re-deploy, `latest` refused, missing environment, missing service, and **automatic rollback on non-convergence** all behave as specified, with the documented exit codes |
| **Groovy parse** | **Not run — no Groovy or Jenkins available in this environment** |
| **`Declarative Linter` against a Jenkins instance** | **Not run** |
| **A pipeline executed end to end** | **Not run** |

The structural check is not a parse. **These pipelines have never run.** Validate each against a real Jenkins with `jenkins-cli declarative-linter` before adopting.

---

## Stages Each Template Should Demonstrate

```text
Checkout
Restore Dependencies
Lint
Build
Unit Test
Coverage
Static Analysis
SonarQube Quality Gate
Security Scan
Docker Build
Container Scan
Generate SBOM
Sign Image
Push to Harbor
Deploy
Health Verification
Rollback Handling
```

A mandatory gate failure must stop the pipeline before promotion.

---

## Credential Rules

Never embed credentials. Reference Jenkins Credentials by ID:

```groovy
withCredentials([usernamePassword(
    credentialsId: 'harbor-registry',
    usernameVariable: 'HARBOR_USER',
    passwordVariable: 'HARBOR_PASSWORD'
)]) {
    // use the credential here
}
```

Do not echo credential values, and do not pass them as plain build parameters.

---

## Credential IDs Referenced

These must exist in Jenkins before any template runs. `TBD` — confirm naming.

| Credential id | Type | Scope |
| --- | --- | --- |
| `sonarqube-token` | Secret text | Analysis submission and gate read |
| `harbor-push` | Username/password | Push and pull, limited to the projects it builds for |
| `deploy-repo-token` | Secret text | Write to the **deployment repository only**. This is the credential that can change production |
| `portainer-webhook-dev` | Secret text | Stack webhook, one per environment |

Runtime hosts use **separate, pull-only** credentials that this pipeline never holds. A host that can push turns a host compromise into a supply-chain compromise.

## Open Items

- `TBD` — the **deployment repository** itself. Structure and protection are defined in [deployment-repository-standard.md](../../docs/05-ci-cd/deployment-repository-standard.md); it does not exist yet
- `TBD` — **`VERSION_PROBE`** per environment. Without it, convergence is unverified and every deployment records as success
- `TBD` — **verify** that Portainer reads `stack.env` from the repository, and its precedence against Portainer's own variables
- `TBD` — UAT and PROD deploy stages. PROD approval under this model is the pull request against `prod/`
- `TBD` — migration tooling, before the migration stage can be enabled
- `TBD` — agent labels, and whether agents are ephemeral. An ephemeral agent means a compromised build does not persist to the next one
- `TBD` — credential id naming convention
- `TBD` — where the version comes from: a `VERSION` file, the Git tag, or derived from commit messages
- `TBD` — whether SBOM generation failure blocks publication
- `TBD` — build log retention, which must match the evidence retention period rather than a convenient default
- `TBD` — Jenkins Shared Library name and repository, Phase 5
- `TBD` — notification on failure

---

## Related

- [Templates index](../README.md)
- [CI/CD standards](../../docs/05-ci-cd/)
- [Docker templates](../docker/)
