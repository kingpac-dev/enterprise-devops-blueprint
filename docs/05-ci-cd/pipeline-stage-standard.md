# Pipeline Stage Standard

## Purpose

Defines each pipeline stage precisely: its inputs, its outputs, what makes it fail, and what that failure means.

## Scope

Stage-level contracts. The overall flow is in [ci-standard.md](ci-standard.md) and [cd-standard.md](cd-standard.md).

## Audience

Platform engineers implementing pipelines, and developers diagnosing a failed one.

## Status

**Draft for review.** Thresholds are `TBD`.

---

## How to Read This

Each stage states inputs, outputs, failure conditions, and **what a failure means** — because the last is what a developer needs at 17:00 on a Friday and is what a stage name alone never conveys.

`Blocks` means the pipeline stops. No later stage runs, and no artifact is published.

---

## Checkout

| | |
| --- | --- |
| Inputs | Repository, branch or commit reference |
| Outputs | Working tree; resolved commit SHA |
| Fails when | Source control unreachable; reference not found |
| Blocks | Yes |
| Means | Nothing to do with your change. Usually GitHub is unavailable or the credential expired |

The resolved commit SHA computed here is used for the image identity. Everything downstream references it.

---

## Restore Dependencies

| | |
| --- | --- |
| Inputs | Committed lockfile, package feeds |
| Outputs | Resolved dependency tree |
| Fails when | Lockfile disagrees with the project file; a feed is unreachable; a package version no longer exists |
| Blocks | Yes |
| Means | Usually a lockfile not regenerated after a dependency change |

Restored in **locked mode** (`npm ci`, `dotnet restore --locked-mode`). Without it the same commit resolves different versions on different days, and "what is in this artifact" has no fixed answer.

A package removed from a public feed fails here, not at build. That is a supply-chain event worth noticing rather than working around.

---

## Lint

| | |
| --- | --- |
| Inputs | Source |
| Outputs | Findings |
| Fails when | Rule violations at the configured level |
| Blocks | `TBD` |
| Means | Style or correctness rules not met |

Lint should be fast and run early, so a formatting mistake is not discovered after eight minutes of build and test.

---

## Build

| | |
| --- | --- |
| Inputs | Source, restored dependencies |
| Outputs | Compiled output |
| Fails when | Compilation error |
| Blocks | Yes |
| Means | The code does not compile. Almost always your change |

For .NET, `--no-incremental` is required so the Sonar scanner sees every project — see [ci-standard.md](ci-standard.md#the-net-ordering-exception).

---

## Unit Test

| | |
| --- | --- |
| Inputs | Build output |
| Outputs | Test results |
| Fails when | Any test fails |
| Blocks | Yes |
| Means | Behaviour changed, or a test is flaky |

**A flaky test is a defect, not an inconvenience.** Re-running until green trains people to re-run, and the habit applies to the failure that was real. Quarantine it explicitly with a ticket rather than tolerating it silently.

---

## Coverage

| | |
| --- | --- |
| Inputs | Test execution |
| Outputs | Coverage report at the path the analysis stage expects |
| Fails when | Below threshold, on **new code** |
| Blocks | `TBD` |
| Means | New code lacks tests |

A wrong report path produces **zero** coverage, which looks like a coverage problem rather than a configuration one — and gets "fixed" by lowering the threshold.

Coverage measures which lines executed, not whether anything was asserted about them.

---

## Static Analysis

| | |
| --- | --- |
| Inputs | Source, coverage report, analysis token |
| Outputs | Analysis submitted to SonarQube |
| Fails when | Submission fails; SonarQube unreachable |
| Blocks | Yes |
| Means | Usually the analysis server or the token, not your change |

For .NET this is **two** stages wrapping build and test. Placed after the build, it collects nothing.

The token is supplied by Jenkins Credentials and must never be echoed. Jenkins runs `sh` with `-x` in many configurations, which would place it in a build log that is widely readable and long-lived.

---

## Quality Gate

| | |
| --- | --- |
| Inputs | The submitted analysis |
| Outputs | Pass or fail verdict |
| Fails when | Gate conditions not met, **or the verdict cannot be obtained** |
| Blocks | **Yes** |
| Means | Quality conditions not met on new code — or SonarQube is unavailable |

**Unavailable is not a pass.** Waiting has a timeout, and the timeout fails.

---

## Security Scan — dependencies and secrets

| | |
| --- | --- |
| Inputs | Working tree, current vulnerability database |
| Outputs | Findings; a machine-readable report |
| Fails when | Finding at or above threshold; **a secret is detected**; database stale beyond threshold |
| Blocks | **Yes** |
| Means | A vulnerable dependency, or a credential in the tree |

**A detected secret is not a finding to triage.** It is a credential to treat as compromised: rotate first, following [credential-rotation.md](../../sop/credential-rotation.md). Do not remove the line and re-run.

Runs **before** the image is built, so a vulnerable dependency does not consume a build.

---

## Docker Build

| | |
| --- | --- |
| Inputs | Working tree, Dockerfile, build metadata |
| Outputs | A local image tagged with its immutable identity |
| Fails when | Dockerfile error; base image unavailable; build context problem |
| Blocks | Yes |
| Means | Usually the Dockerfile or a missing `.dockerignore` |

Build arguments carry version, commit, timestamp, and source. **Never a credential** — `ARG` values are readable in image history by anyone who can pull the image.

---

## Container Scan

| | |
| --- | --- |
| Inputs | The built image |
| Outputs | Findings; a machine-readable report |
| Fails when | Finding at or above threshold |
| Blocks | **Yes — before publication** |
| Means | Vulnerabilities in the image, usually from the base image |

Blocking here rather than before deployment is deliberate: an image that fails policy should never enter the registry, because once it exists it is deployable.

Most findings at this stage come from the base image, so the fix is usually a base image update rather than an application change.

---

## Generate SBOM

| | |
| --- | --- |
| Inputs | The built image |
| Outputs | Component inventory, linked to the image **digest** |
| Fails when | Generation fails |
| Blocks | `TBD` — recommended yes |
| Means | The inventory could not be produced |

Generated from the image, not the build context — otherwise it inventories what was intended rather than what shipped.

Retained **independently of image retention**. Stored as an image artifact, the inventory disappears with the image, and the supply-chain question outlives it.

---

## Sign Image

| | |
| --- | --- |
| Status | **Not adopted.** Phase 3 |

Signing attests that an artifact came from the expected pipeline. Its value is realized only at **verification**, and verification must not be performed by this pipeline — a compromised Jenkins would sign its own artifact and verify it successfully.

The verification point depends on the deployment mechanism. See [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md).

---

## Push to Harbor

| | |
| --- | --- |
| Inputs | The built image, push credential |
| Outputs | Published image; **recorded digest** |
| Fails when | Harbor unreachable; credential invalid; **tag already exists** and is immutable |
| Blocks | Yes |
| Means | Registry problem — or an attempt to republish an existing identity |

The last failure mode is the immutability rule working. An existing tag is never repointed; retagging retroactively invalidates every deployment record referencing it.

Only from protected branches.

---

## Record Known-Good Version

| | |
| --- | --- |
| Inputs | Current deployment state for the target environment |
| Outputs | The rollback target, recorded |
| Fails when | Current state cannot be determined; the recorded image is **no longer present in Harbor** |
| Blocks | **Yes** |
| Means | Rollback capability cannot be established, so deployment must not proceed |

Runs **before** deployment. Determining the rollback target afterwards, from a system that may already be failing, is how rollbacks get stuck.

The second failure condition catches a retention rule that evicted the rollback target — silent until this check exists.

---

## Deploy

| | |
| --- | --- |
| Inputs | Published image identity, environment configuration |
| Outputs | Running containers |
| Blocks | Yes |
| Mechanism | **`TBD` — [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)** |

Deploys the **published** image. Nothing is rebuilt.

---

## Health Verification

| | |
| --- | --- |
| Inputs | Deployed service |
| Outputs | Healthy or not |
| Fails when | **Readiness** not reached within timeout |
| Blocks | Yes — and triggers rollback |
| Means | The service started and cannot serve traffic |

**Readiness, not liveness.** Liveness answers a question about the process; readiness answers whether it can serve traffic, which is what a deployment needs to know.

A worker has no readiness endpoint. Verification is behavioural: the container is running, the liveness file has been touched since the deployment started, and the backlog is not growing. **Container-running alone is not verification** — a worker that starts, fails to connect to its queue, and retries silently is running and processing nothing.

---

## Smoke Test

| | |
| --- | --- |
| Inputs | Deployed, healthy service |
| Outputs | Pass or fail |
| Fails when | Core functionality does not work |
| Blocks | Yes — and triggers rollback |
| Means | It is healthy and it does not work |

`TBD` — definition per application type. It should exercise a real path end to end, not repeat the health check.

---

## Rollback

| | |
| --- | --- |
| Inputs | The recorded known-good version |
| Outputs | Previous version running; failure evidence |
| Fails when | The target image is unavailable; **the change is not reversible** |
| Blocks | N/A — this is the failure path |
| Means | Either recovery, or a situation needing forward fix |

The second failure condition is the one that must have been anticipated. A release containing an irreversible migration cannot be rolled back by redeploying the previous image; that limitation is recorded in the release notes **before approval**.

---

## Open Items

| Item |
| --- |
| `TBD` — every threshold referenced above |
| `TBD` — whether lint, coverage, and SBOM generation block |
| `TBD` — smoke test definition per application type |
| `TBD` — health verification timeout per application type |
| `TBD` — deployment mechanism, [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) |

---

## Related

- [CI standard](ci-standard.md)
- [CD standard](cd-standard.md)
- [Rollback strategy](rollback-strategy.md)
- [Jenkins templates](../../templates/jenkins/)
- [Observability standard](../08-observability/observability-standard.md)
