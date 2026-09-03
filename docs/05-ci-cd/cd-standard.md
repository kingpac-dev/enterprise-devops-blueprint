# CD Standard

## Purpose

Defines how a published artifact reaches production: what must happen, in what order, who authorizes it, and what stops it.

## Scope

From a published image to a verified deployment. Artifact production is in [ci-standard.md](ci-standard.md); promotion mechanics are in [environment-promotion.md](environment-promotion.md); failure handling is in [rollback-strategy.md](rollback-strategy.md).

## Audience

Platform engineers, release approvers, and developers.

## Status

**Draft for review.** The deployment mechanism is **decided and implemented** — pull-based via Portainer GitOps, [ADR-0010](../../adr/0010-portainer-gitops-deployment.md), executed by [deploy-gitops.sh](../../templates/jenkins/deploy-gitops.sh). Section 8 records what that changed.

---

## 1. The Flow

```text
Select immutable image
Record known-good version        <- BEFORE deploying
Deploy DEV
Health check
Deploy UAT                       <- SAME image
Health check
UAT verification
Approval
Deploy PROD                      <- SAME image
Health check
Smoke test
Record evidence
Rollback on failure, where technically safe
```

Three properties define this flow and are worth stating separately from the steps.

**The same image throughout.** Nothing is rebuilt between DEV and production. UAT verification is evidence about production only if production runs what UAT ran.

**The known-good version is recorded before deploying**, not after. Determining the rollback target afterwards, from a system that may already be failing, is how rollbacks get stuck.

**Production requires explicit approval.** Not a configuration flag — a recorded human decision.

---

## 2. What CD Is Not Allowed to Do

| Prohibited | Why |
| --- | --- |
| Rebuild for an environment | Discards the evidence UAT provided |
| Deploy `latest` | No deterministic answer to what is running |
| Deploy an image that did not pass through UAT | The approval gate then approves something unverified |
| Deploy without recording the previous version | Removes the rollback target |
| Retag an image during promotion | Retroactively invalidates every record naming that tag |
| Proceed past a failed health check | The deployment has not succeeded |

---

## 3. Deployment by Environment

| | DEV | UAT | PROD |
| --- | --- | --- | --- |
| Trigger | Automatic on merge to `develop` | On `release/*` — `TBD` automatic or on request | **Manual, after approval** |
| Approval | None | `TBD` | **Required, recorded** |
| Health check | Yes | Yes | Yes |
| Smoke test | No | Yes | **Yes** |
| Rollback on failure | Automatic | Automatic | Automatic where technically safe |
| Evidence recorded | Minimal | Yes | **Full** |
| Change class | Standard | Standard | **Normal** |

---

## 4. Production Approval

```text
Release Candidate -> Quality Gate -> Security Gate -> UAT Verification
                  -> Production Approval -> Deployment
```

The approver decides **before** deployment, informed by the release notes — which state breaking changes, migrations, configuration changes required before deployment, and **rollback availability**.

| Recorded | |
| --- | --- |
| Approver role and identity | |
| Version and image digest | |
| Timestamp | |
| Change or ticket reference | |

**The approver is not the change author.** Approval by the person who wrote the change records a decision without providing independent review.

`TBD` — the approver role. See [ADR-0008](../../adr/0008-production-manual-approval.md).

---

## 5. Health Verification

**Readiness, not liveness.** Liveness answers a question about the process; readiness answers whether it can serve traffic, which is what a deployment needs to know.

| Application type | Verification |
| --- | --- |
| .NET API | Poll `/health/ready` until healthy or timeout |
| Angular | Poll the served health endpoint |
| **.NET Worker** | Behavioural — see below |

A worker has no readiness endpoint. "Deployed successfully" is established from behaviour:

- the container is running
- **the liveness file has been touched since the deployment started** — at least one cycle has completed
- the backlog is not growing

**Container-running alone is not verification.** A worker that starts, fails to connect to its queue, and retries silently is running and processing nothing — and every check that only asks "is it up?" reports success.

`TBD` — timeout per application type. Too short fails healthy slow-starting services; too long delays every rollback.

---

## 6. Smoke Test

Runs after health verification in UAT and PROD. It exercises a **real path end to end** rather than repeating the health check.

| Should | Should not |
| --- | --- |
| Exercise one genuine user-facing path | Repeat the health endpoint |
| Be fast — seconds, not minutes | Be a full regression suite |
| Be safe to run against production | Create real records without cleanup |
| Fail clearly | Be flaky |

The third constraint is the hard one and needs deciding per service. `TBD` — definition per application type.

---

## 7. Evidence

Every production deployment produces a record, generated automatically. A record a human enters is a record that is sometimes not entered, and the occasions it is missed are the busy ones — which correlate with the occasions it is later needed.

| Field | Source |
| --- | --- |
| Service, environment, version | Pipeline |
| Image identifier **and digest** | Pipeline |
| Git commit and tag | Pipeline |
| Pipeline execution reference; gate verdicts | Pipeline |
| Approver role and identity; approval timestamp | Approval step |
| Deployment timestamp | Pipeline |
| **Previous version** | Recorded before deployment |
| Outcome | Post-deployment verification |
| Change reference | Change record |

See [audit-evidence.md](../10-governance/audit-evidence.md). The deployment record is the **join** — without it, every other evidence source is a fragment describing one stage.

---

## 8. The Deployment Mechanism, and What It Changed

**Decided: pull-based via Portainer GitOps** — [ADR-0010](../../adr/0010-portainer-gitops-deployment.md). Everything above is independent of that choice; the execution of the Deploy step is not.

The pipeline **never connects to a runtime host**. It commits the new tag to the deployment repository, calls the Portainer webhook, and waits — see [deployment-repository-standard.md](deployment-repository-standard.md).

The options considered are in [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md). The one chosen — pull-based — is the only one that materially changed this standard, and the change is below.

### Deployment is asynchronous, and that changes this standard

The pipeline updates the desired state; the host converges at its own pace.

Consequences that must be designed rather than discovered:

| Property | Push model | **Pull model, in use** |
| --- | --- | --- |
| Pipeline knows the deployment happened | Immediately | **Needs an explicit feedback path** |
| Health verification | Runs after deploy | **Must wait for convergence first** |
| Automatic rollback on failed verification | The pipeline reverts the deployment | The pipeline reverts the **desired state**; the host converges back |
| "Deploy now" | Direct | Prompt via webhook; otherwise bounded by the polling interval |

Without a feedback path, health verification has nothing to verify and automatic rollback cannot trigger. **That path is now implemented**: [deploy-gitops.sh](../../templates/jenkins/deploy-gitops.sh) polls until the running version matches the desired one, and reverts the desired state on timeout.

The probe it uses queries the `version` label already required on every service's metrics, so it verifies the **running process** rather than what Portainer believes, and works identically for workers, which have no HTTP endpoint to poll.

`TBD` — the probe per environment. **Without it the script warns and exits successfully, so the deployment's outcome is unknown and records as success.**

---

## 9. Open Items

| Item | Blocks |
| --- | --- |
| ~~deployment mechanism~~ **decided and implemented** ([ADR-0010](../../adr/0010-portainer-gitops-deployment.md)) | — |
| `TBD` — `VERSION_PROBE` per environment | Whether convergence is verified at all |
| `TBD` — the deployment repository itself | Every deploy step |
| `TBD` — production approver role | Approval |
| `TBD` — UAT trigger and approval | Section 3 |
| `TBD` — health verification timeout per application type | Section 5 |
| `TBD` — smoke test definition per application type | Section 6 |
| `TBD` — post-deployment observation window before a change is complete | Evidence, change closure |
| `TBD` — deployment record storage | Section 7 |

---

## Security Considerations

The approval boundary is the only control in the chain that applies human judgement to whether a specific change should go live. Its integrity depends on separation of duties: where the author can approve, the boundary is decorative.

Deployment credentials are **per environment**. One credential that can deploy anywhere makes the approval boundary decorative in a different way — the control exists and can be routed around.

The deployment record is what makes production auditable. Deployments that happen without one — manually, or through an ungoverned path — leave an audit trail that has stopped describing reality, with no indication that it has.

## Operational Considerations

Health verification and the recorded known-good version are what make automatic rollback possible. Both are cheap and both are omitted by pipelines that "deploy and hope".

The post-deployment observation window deserves a deliberate value. Some failures appear immediately; others appear under load, at a scheduled job, or at the next hourly batch. A change marked successful at deployment plus two minutes has been verified against a narrow slice of its behaviour.

---

## Related

- [CI standard](ci-standard.md)
- [Environment promotion](environment-promotion.md)
- [Rollback strategy](rollback-strategy.md)
- [Pipeline stage standard](pipeline-stage-standard.md)
- [Audit evidence](../10-governance/audit-evidence.md)
- [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)
