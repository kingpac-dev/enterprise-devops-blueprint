# Jenkins Templates

## Purpose

Reusable `Jenkinsfile` templates implementing the CI/CD standard for each supported application type.

## Scope

Pipeline definitions and shared-library usage patterns. The rules these pipelines enforce are defined in [docs/05-ci-cd/](../../docs/05-ci-cd/).

## Status

**Draft for review.** All four are written. Stages from checkout through publication are complete; **deploy, health verification, and rollback are blocked by [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)** and are present as explicit stubs.

---

## Templates

| File | Target | Stages | Status |
| --- | --- | --- | --- |
| [Jenkinsfile.template](Jenkinsfile.template) | Generic reference, heavily commented | 17 | Draft |
| [Jenkinsfile.angular](Jenkinsfile.angular) | Angular applications | 14 | Draft |
| [Jenkinsfile.dotnet-api](Jenkinsfile.dotnet-api) | .NET Web APIs | 15 | Draft |
| [Jenkinsfile.dotnet-worker](Jenkinsfile.dotnet-worker) | .NET Worker Services | 14 | Draft |

Each is complete and runnable on its own. The blocked stages use `when { expression { return false } }` so the pipeline runs while the gap stays visible in the stage view rather than being absent and forgotten.

## Duplication Is Deliberate and Temporary

The four files share most of their content, which the CI/CD standard warns against. A Jenkins Shared Library is the resolution and it is **Phase 5** work — a library written before several services have run through this pipeline encodes patterns that were predicted rather than used.

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
| Balanced braces, parentheses, and triple-quoted blocks | Pass, all four |
| Exactly one `pipeline {}` block per file | Pass |
| Every `withCredentials` block has a matching `set +x` | Pass |
| No plaintext credential — all referenced by credential id | Pass |
| **Groovy parse** | **Not run — no Groovy or Jenkins available in this environment** |
| **`Declarative Linter` against a Jenkins instance** | **Not run** |
| **A pipeline executed end to end** | **Not run** |

The structural check is not a parse. **These pipelines have never run.** Validate each against a real Jenkins with `jenkins-cli declarative-linter` before adopting.

---

## Stages Each Template Should Demonstrate

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

Runtime hosts use **separate, pull-only** credentials that this pipeline never holds. A host that can push turns a host compromise into a supply-chain compromise.

## Open Items

- `TBD` — **[ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md): the deployment mechanism.** Blocks deploy, health verification, and rollback in all four templates
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
