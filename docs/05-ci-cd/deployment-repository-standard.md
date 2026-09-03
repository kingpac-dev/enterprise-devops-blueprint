# Deployment Repository Standard

## Purpose

Defines the repository that holds the desired state of every environment: its structure, its protection, and what may change it.

## Scope

The deployment repository under the pull-based model in [ADR-0010](../../adr/0010-portainer-gitops-deployment.md). Application repositories are covered by [04-source-control/](../04-source-control/).

## Audience

Platform engineers, release approvers, and anyone with write access to it.

## Status

**Draft for review.** The repository does not exist yet. The deploy script that operates on it is written and tested — [deploy-gitops.sh](../../templates/jenkins/deploy-gitops.sh).

---

## 1. This Repository Controls Production

Under pull-based deployment, **what is in this repository is what runs**. Portainer synchronizes to it and overwrites anything changed by hand.

That makes it a production control with the same weight as the pipeline, and it needs stating plainly because a repository containing only YAML and a few key-value pairs does not look like one:

| Property | Consequence |
| --- | --- |
| A commit here **is** a deployment | Write access is production deployment access |
| Its Git history **is** the deployment record | The audit trail is the log |
| Reverting a commit **is** a rollback | Recovery is a Git operation |
| A mistake here reaches production | Without passing any pipeline gate |

**Nothing in this repository is a secret.** Image tags, ports, and non-sensitive configuration only. Credentials live in Portainer — see section 5.

---

## 2. Structure

```text
deployment-repo/
├── dev/
│   ├── docker-compose.yml     stable; rarely changes
│   └── stack.env              image tags; CHANGED BY THE PIPELINE
├── uat/
│   ├── docker-compose.yml
│   └── stack.env
├── prod/
│   ├── docker-compose.yml
│   └── stack.env
├── README.md
└── CODEOWNERS
```

One Portainer stack per environment, each pointing at its directory.

### Why the tag lives in `stack.env`, not in the compose file

[ADR-0010](../../adr/0010-portainer-gitops-deployment.md) requires the image tag to be in Git, because it is the deployment trigger. Both files are in Git, so either satisfies that. `stack.env` is chosen for three practical reasons:

| Reason | |
| --- | --- |
| **The change is a one-line key-value edit** | An anchored, verifiable replacement. Editing YAML programmatically needs a YAML parser, and a `sed` on YAML is fragile |
| **The compose file stops changing** | It is reviewed once and then stable. Every subsequent diff is purely "which version is deployed" |
| **The diff is the deployment record, and it is readable** | `ORDERS_API_VERSION=1.4.2-a82f912 → 1.5.0-b91c332` needs no interpretation |

```ini
# prod/stack.env
# Image versions. Non-secret and committed deliberately — they are the
# deployment trigger. Credentials are in Portainer, never here.
ORDERS_API_VERSION=1.4.2-a82f912
MES_WEB_VERSION=2.1.0-c04d551
ORDERS_WORKER_VERSION=1.4.2-a82f912
```

```yaml
# prod/docker-compose.yml — stable
services:
  api:
    image: harbor.example.internal/team/orders-api:${ORDERS_API_VERSION}
```

`TBD` — **verify once** that Portainer substitutes from the repository's `stack.env`, and what happens when a key is set both there and in Portainer's own environment variables. Precedence between the two is not documented in the interface and it determines whether this structure works as intended.

### The key naming convention

The deploy script derives the key from the service name: uppercase, hyphens to underscores, `_VERSION` suffix.

```text
orders-api     ->  ORDERS_API_VERSION
mes-web        ->  MES_WEB_VERSION
orders-worker  ->  ORDERS_WORKER_VERSION
```

Deterministic, so no mapping table is needed and no service can be deployed under the wrong key by a typo — the script fails if the derived key is absent.

---

## 3. Protection

This repository deploys to production. It is protected accordingly.

| Setting | `prod/` | `dev/`, `uat/` |
| --- | --- | --- |
| Direct push to the protected branch | **Blocked** | `TBD` — see below |
| Pull request required | **Yes** | `TBD` |
| Approving review required | **Yes — this is the production approval gate** | `TBD` |
| Force push | **Blocked** | Blocked |
| Branch deletion | **Blocked** | Blocked |
| `CODEOWNERS` on `prod/` | **Yes** | — |

### The pull request is the production approval gate

Under this model, [ADR-0008](../../adr/0008-production-manual-approval.md)'s approval requirement is satisfied naturally: the pipeline opens a pull request against `prod/stack.env`, and merging it is the approval.

| Property | Effect |
| --- | --- |
| The approver sees the exact diff | Old version → new version, unambiguous |
| Approval is recorded by GitHub | With who, when, and on what |
| The author cannot approve their own | Separation of duties, enforced by the platform |
| Merging **is** deployment | No separate step to forget |

This is a better approval mechanism than a button in a pipeline: it produces a reviewable artifact rather than a click, and the review platform enforces the separation.

`TBD` — whether DEV and UAT allow direct push. Requiring review for a DEV deployment adds friction to the environment that most needs to be fast. A reasonable split is direct push for DEV, review for UAT and PROD.

---

## 4. Who and What May Write

| Identity | Access |
| --- | --- |
| Pipeline service account | Write, **scoped to this repository only** |
| Release approver role | Merge pull requests against `prod/` |
| Platform engineer | Write, for compose file changes |
| Everyone else | Read |

The pipeline's token is the credential that can change production. It is scoped to this repository, expiring, and rotated on schedule — see [credential-rotation.md](../../sop/credential-rotation.md).

**Jenkins no longer holds a credential that deploys.** It holds one that proposes a change to a repository, which is reviewable and revertible. That is the security improvement this deployment model provides, and scoping the token narrowly is what preserves it.

---

## 5. Secrets Are Not Here

| Value | Where |
| --- | --- |
| Image tags | **This repository**, in `stack.env` |
| Ports, non-sensitive configuration | This repository |
| **Connection strings, signing keys, tokens** | **Portainer environment variables** |

Portainer substitutes its own environment variables into the compose file. They are stored in Portainer rather than in Git.

`TBD` — confirm how Portainer stores them at rest and who can read them through the interface. They are production credentials, and Portainer's access model is now what protects them.

Secret scanning runs on this repository like any other. A credential committed here is compromised the moment it is pushed — rotate it, following [SECURITY.md](../../SECURITY.md).

---

## 6. Convergence Verification

The pipeline must confirm the deployment took effect. **This is the step a push-based model does not need**, and without it the pipeline cannot answer "did it deploy?" and automatic rollback has no trigger.

The deploy script takes a `VERSION_PROBE` — a command printing the version **currently running**. Which probe to use is a real decision:

| Probe | How | Verifies | Depends on |
| --- | --- | --- | --- |
| **Prometheus** *(recommended)* | Query the `version` label already required on every service's metrics | The **running process** reported it | Prometheus being up |
| Application endpoint | A restricted endpoint returning the version | The running process | A new endpoint, and its exposure |
| Portainer API, read-only | Ask which image the stack is running | What Portainer believes | Portainer's API shape |

**Prometheus is recommended** because the `version` label is already required by [observability-standard.md](../08-observability/observability-standard.md#2-the-service-contract), so no new surface is added — and it works identically for APIs and for workers, which have no HTTP endpoint to poll.

```sh
# Prometheus probe
VERSION_PROBE='curl -sf "http://prometheus:9090/api/v1/query?query=up{service=\"orders-api\",environment=\"prod\"}" | jq -r ".data.result[0].metric.version"'
```

Note the read-only Portainer option is **not** the thing [ADR-0010](../../adr/0010-portainer-gitops-deployment.md) rejected. Rejecting the API as a *deployment* path does not rule out reading status from it; what was rejected was one interface serving both the governed and ungoverned paths.

`TBD` — the probe, per environment.

### Without a probe, the outcome is unknown

If `VERSION_PROBE` is unset the script warns and exits successfully. That is deliberate and it is a gap: **the deployment's outcome is unknown and will be recorded as success.**

Acceptable while bootstrapping. Not acceptable for production once observability exists.

---

## 7. Rollback

Reverting the desired state. The deploy script does it automatically when convergence times out; a human does the same thing by reverting the commit.

```sh
git revert <deployment-commit>
git push
# Portainer converges back
```

Two dependencies remain from [rollback-strategy.md](rollback-strategy.md):

- **The previous image must still exist in Harbor.** Retention still bounds rollback depth
- **The change must be reversible.** A migration is not undone by reverting a tag — see [database-migration-standard.md](database-migration-standard.md)

What this model adds is that the rollback target is **visible in Git history** rather than recorded separately, and reverting is an operation with an audit trail by construction.

---

## 8. Exit Codes the Pipeline Must Handle

From [deploy-gitops.sh](../../templates/jenkins/deploy-gitops.sh):

| Code | Meaning | Pipeline response |
| --- | --- | --- |
| 0 | Deployed and converged | Continue |
| 1 | Precondition failure — **nothing changed** | Fail the build |
| 2 | Push failed — **nothing deployed** | Fail the build; retry is safe |
| 3 | Did not converge; **rolled back** | Fail the build. Recovery is not yet verified |
| **4** | Did not converge; **rollback also failed** | **Page someone.** The desired state names a version that does not work |

Code 4 is the one that needs a human. The desired state is wrong, the pipeline could not correct it, and Portainer will keep trying to converge to a version that does not come up.

---

## 9. Open Items

| Item |
| --- |
| `TBD` — **verify** that Portainer reads `stack.env` from the repository, and its precedence against Portainer's own variables |
| `TBD` — the `VERSION_PROBE` per environment |
| `TBD` — whether DEV and UAT allow direct push, or require review |
| `TBD` — repository name and location |
| `TBD` — `CODEOWNERS` content and the approver role |
| `TBD` — pipeline token scope, expiry, and rotation schedule |
| `TBD` — convergence timeout per service; a slow-starting service needs longer than the default |
| `TBD` — whether a stale desired state alerts. A version committed but never converged is currently silent after the pipeline ends |

The last is worth doing. The script waits for its own timeout and then rolls back, but nothing watches for a desired state that has drifted from what is running for other reasons — a host that came back with an old image, for instance.

---

## Security Considerations

Write access to this repository is production deployment access. It should be granted, reviewed, and revoked with the same care as tier 3 access in [production-access-policy.md](../10-governance/production-access-policy.md), and it is easy to under-protect because the repository contains no secrets and looks harmless.

The pipeline's token is the one credential in the system that can change production. Scoping it to this repository is what keeps a Jenkins compromise from being a direct production compromise — the improvement this model provides is lost if the token is broadly scoped.

Portainer overwrites manual changes, which enforces the no-manual-change rule mechanically. It also means a bad commit here is applied without any gate, so branch protection is the only thing standing between a typo and production.

## Operational Considerations

The pull-request-as-approval mechanism is the strongest part of this model. It produces a reviewable diff, records the approval on the platform, and enforces that the author is not the approver — all without a separate approval step to forget.

Convergence verification is the part that must not be skipped. Without a probe, every deployment is recorded as successful regardless of outcome, and the pipeline is reporting on its own actions rather than on the system.

---

## Related

- [ADR-0010 — Portainer GitOps deployment](../../adr/0010-portainer-gitops-deployment.md)
- [deploy-gitops.sh](../../templates/jenkins/deploy-gitops.sh)
- [CD standard](cd-standard.md)
- [Rollback strategy](rollback-strategy.md)
- [Database migration standard](database-migration-standard.md)
- [Git standard](../04-source-control/git-standard.md)
