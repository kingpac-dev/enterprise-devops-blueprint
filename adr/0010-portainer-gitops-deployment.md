# ADR-0010 — Portainer GitOps as the Deployment Mechanism

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-18 |
| Deciding role | `TBD` — platform owner |
| Supersedes | [ADR-0009](0009-deployment-mechanism-to-runtime-hosts.md) |
| Superseded by | None |

> Records the decision that [ADR-0009](0009-deployment-mechanism-to-runtime-hosts.md) set out the options for. ADR-0009 recorded no decision; this one does.

---

## Context

[ADR-0009](0009-deployment-mechanism-to-runtime-hosts.md) presented five options for how the pipeline reaches runtime hosts, under the constraint that production must not depend on publicly exposed SSH solely for CI/CD.

An existing deployment already answers it: Portainer Community Edition is in use, with **GitOps updates enabled** on a stack sourced from a Git repository, triggered by webhook.

This is option **C — pull-based**, not option **D — Portainer API push**. The distinction is the reason this is acceptable where option D was not.

### Observed configuration

| Item | Value |
| --- | --- |
| Portainer edition | **Community Edition 2.33.5** |
| GitOps updates | Enabled |
| Repository reference | `refs/heads/main` |
| Trigger | Webhook; polling also available |
| Authentication | Git service account with a personal access token |
| Re-pull image | **Business Edition feature — unavailable** |
| Force redeployment | **Business Edition feature — unavailable** |

---

## Decision

**Deployment is pull-based. Portainer Stacks synchronize from a Git repository; nothing pushes to runtime hosts.**

| Element | |
| --- | --- |
| Desired state | `docker-compose.yml` in a Git repository, per environment |
| Trigger | Portainer webhook, called after the desired state changes |
| What the pipeline does | Build, verify, publish to Harbor, then **commit the new image tag** to the deployment repository and call the webhook |
| What the pipeline does **not** do | Connect to any runtime host |
| Inbound access to runtime hosts | **None** |

### Why this is option C, not option D

Option D was rejected because routing pipeline deployments through the Portainer **API** would make one interface serve both governed and ungoverned paths, dissolving the boundary that says Portainer is not a deployment path.

GitOps synchronization does the opposite. Portainer's own warning states it:

> Any changes to this stack or application that have been made locally via Portainer or directly in the cluster will be overwritten by the git repository content.

**Manual changes are automatically reverted.** The boundary in `AGENTS.md` §13 stops depending on permissions and intent and becomes a property of the mechanism. That is a stronger position than any of the other four options reach.

---

## The Community Edition Constraint Makes Immutable Tags Mandatory

**Without "Re-pull image", Portainer CE does not force `docker pull` on redeployment.**

| Compose reference | On redeploy | Result |
| --- | --- | --- |
| `app:latest` | The tag already exists locally; Docker does not pull | **The stack redeploys the OLD image and reports success** |
| `app:1.4.2-a82f912` | The tag does not exist locally; Docker must pull | Correct image deployed |

Using `latest` here does not merely break traceability, as [ADR-0007](0007-use-immutable-container-versioning.md) already states. **It silently deploys stale code while reporting success** — the deployment record says one thing and the runtime does another, with nothing indicating the divergence.

Immutable tags were already required. On this platform they are also the only thing that makes deployment function at all.

`TBD` — **verify this behaviour deliberately before first production use.** Deploy a tag, change the image content behind that same tag, redeploy, and confirm the stale image is served. Knowing it firsthand is worth more than inferring it from a feature matrix, and the failure mode is silent.

---

## The Image Version Must Live in Git

GitOps triggers on repository content, so the image tag must be **in the repository** — not in a Portainer environment variable. Changing a Portainer variable is a manual UI change, which is what this model exists to avoid.

The implemented form puts the tag in a committed `stack.env` rather than inline in the compose file. Both are in Git and both trigger synchronization; `stack.env` is chosen because the change is then a one-line key-value edit that can be made and **verified** without a YAML parser, and because the compose file stops changing so every subsequent diff is purely "which version is deployed". See [deployment-repository-standard.md](../docs/05-ci-cd/deployment-repository-standard.md).

```ini
# prod/stack.env — CHANGED BY THE PIPELINE
ORDERS_API_VERSION=1.4.2-a82f912
```

```yaml
# prod/docker-compose.yml — stable
services:
  api:
    image: harbor.example.internal/team/orders-api:${ORDERS_API_VERSION}
```

**The pipeline's deployment step becomes a commit.** Consequences worth stating plainly:

| Property | Consequence |
| --- | --- |
| The deployment record is the **Git history** of the deployment repository | Who changed what, when, to which version — auditable by construction |
| Rollback is a **commit** | Revert, or commit the previous tag. The rollback target is visible in history |
| Approval can be a **pull request** on the deployment repository | The approval gate becomes a review, with the same audit properties as any other change |
| A deployment repository is a new thing to protect | It now controls production; its branch protection is a production control |

---

## Secrets Do Not Go in the Repository

Portainer states that when deploying via Repository, a `stack.env` file must already reside in the Git repo. **That path must not be used for secrets.**

Environment variable values configured in Portainer are used as substitutions in the compose file and are stored in Portainer rather than in Git.

| Value | Where |
| --- | --- |
| Image tag | **Compose file in Git** — it is the deployment trigger |
| Non-sensitive configuration | Compose file in Git, or Portainer variables |
| **Connection strings, signing keys, tokens** | **Portainer environment variables only. Never in the repository** |

`TBD` — confirm how Portainer stores these values at rest, and who can read them through the UI. They are production credentials, and Portainer's access model now protects them.

---

## Consequences

### Positive

- **No inbound access to runtime hosts** — the strongest available position, and what the `AGENTS.md` constraint was written to protect.
- **No production-changing credentials on Jenkins.** A Jenkins compromise cannot deploy directly; it can only propose a change to a repository, which is reviewable and revertible.
- **Manual drift is reverted by the mechanism**, not by policy.
- The deployment repository's Git history **is** a deployment audit trail, closing part of the evidence gap in [audit-evidence.md](../docs/10-governance/audit-evidence.md).
- Already in operation here, so the approach is proven in this environment rather than theoretical.

### Negative

- **Deployment is asynchronous.** "The pipeline finished" and "the host converged" are different moments. Health verification and automatic rollback need an explicit feedback path — exactly what [cd-standard.md](../docs/05-ci-cd/cd-standard.md#8-the-deployment-mechanism-and-what-it-changed) anticipated for option C.
- **The pipeline cannot report deployment success** without polling for convergence.
- **`latest` becomes catastrophic rather than merely bad**, per the constraint above.
- **A second repository to govern.** It controls production and needs protection, review, and access control to match.
- **Portainer joins the critical path.** If it is down, nothing deploys — a single point of failure absent from options A and B.
- Community Edition lacks the redeployment controls that would otherwise provide a safety net.

### Neutral

- Rollback stops being a pipeline action and becomes a Git operation. Simpler in some respects; the runbook needs rewriting around it.

---

## Alternatives Considered

Set out in full in [ADR-0009](0009-deployment-mechanism-to-runtime-hosts.md).

| Option | Why not chosen |
| --- | --- |
| A — Jenkins agent on each host | Viable and satisfies the constraint. Rejected: an agent and a JVM on every host including production, and GitOps already works here |
| B — SSH over internal network | Viable. Rejected: requires inbound access to runtime hosts, which the chosen option avoids entirely |
| **D — Portainer API push** | **Rejected.** Would dissolve the governance boundary. The chosen option uses the same product and strengthens it |
| E — Orchestrator API | Not available; Kubernetes deliberately deferred — [ADR-0005](0005-use-docker-compose-for-initial-runtime.md) |

---

## Security Considerations

This decision **reduces** the platform's principal security concentration. Under options A, B, and D, Jenkins holds credentials that change production directly. Here it holds credentials that change a Git repository — a reviewable, revertible action with an audit trail — and Portainer performs the change.

Three new obligations follow:

**The deployment repository is a production control.** Write access to it is production deployment access, and it needs the branch protection and access tiers that implies.

**Portainer's environment variables hold production secrets.** Its access model now protects the database credentials, which makes "who can view them in the UI" a production access question.

**The Git service account's token can change production.** Scope it to the deployment repository, set an expiry, and rotate it on schedule.

## Operational Considerations

Asynchrony is the operational cost. Without a feedback path the pipeline cannot answer "did it deploy?", and automatic rollback on failed health verification cannot trigger. Designing that path is the first piece of work this decision creates.

The webhook makes deployment prompt rather than bounded by a polling interval, which removes most of the latency objection to pull-based deployment.

Portainer is now on the critical path and currently has no backup, monitoring, or recovery procedure — unlike Jenkins and Harbor, which at least have documented ones.

---

## Review Trigger

Revisit if:

- The asynchronous feedback path proves impractical and synchronous deployment becomes necessary.
- A Community Edition limitation blocks a needed capability and the Business Edition cost is justified.
- Kubernetes is adopted, at which point Argo CD or Flux replaces this with the same pull-based shape.
- Portainer availability becomes a material constraint on deployment frequency.

---

## Follow-Up Work

| Work | Where |
| --- | --- |
| ~~Design the convergence feedback path~~ **done** — [deploy-gitops.sh](../templates/jenkins/deploy-gitops.sh), tested | [cd-standard.md](../docs/05-ci-cd/cd-standard.md) |
| Rewrite deploy and rollback around a Git commit | [production-deployment-runbook.md](../docs/09-operations/production-deployment-runbook.md), [rollback-runbook.md](../docs/09-operations/rollback-runbook.md) |
| ~~Define the deployment repository structure and its protection~~ **done** | [deployment-repository-standard.md](../docs/05-ci-cd/deployment-repository-standard.md) |
| Add the webhook flow to the interaction catalogue and firewall matrix | [service-interaction.md](../docs/01-architecture/service-interaction.md), [firewall-and-port-matrix.md](../docs/03-network/firewall-and-port-matrix.md) |
| Add Portainer to backup, monitoring, and recovery | [backup-standard.md](../docs/11-disaster-recovery/backup-standard.md), [runbooks/](../runbooks/) |
| **Verify the CE re-pull behaviour deliberately** | Before first production use |

---

## References

- [ADR-0009 — the options this decides](0009-deployment-mechanism-to-runtime-hosts.md)
- [ADR-0007 — immutable container versioning](0007-use-immutable-container-versioning.md)
- [ADR-0005 — Docker Compose as the initial runtime](0005-use-docker-compose-for-initial-runtime.md)
- [CD standard](../docs/05-ci-cd/cd-standard.md)
- [Change management](../docs/10-governance/change-management.md)
