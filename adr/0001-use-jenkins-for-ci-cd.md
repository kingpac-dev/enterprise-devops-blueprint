# ADR-0001 — Use Jenkins for CI/CD

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> This ADR records a blueprint decision made when this repository was established. It does not record a historical evaluation exercise: alternatives were assessed analytically against stated constraints, not through proofs of concept or benchmarking.

---

## Context

The organization needs a CI/CD execution platform for Angular frontends, .NET Web APIs, and .NET Worker Services delivered as containers.

Constraints in force:

- Build execution must run on organization-controlled infrastructure. GitHub-hosted runners are excluded as primary CI/CD execution infrastructure.
- The platform must orchestrate build, test, analysis, scanning, image publication, deployment, health verification, and rollback.
- Initial runtime is Linux hosts with Docker and Docker Compose.
- The team operating it is small; a single platform team serves multiple application teams.

Assumptions: hosts are available inside a controlled network; no existing CI/CD investment constrains the choice.

---

## Decision

Self-hosted Jenkins is the primary CI/CD execution platform.

In practice this means:

- Jenkins runs on organization-controlled infrastructure, not as a managed service.
- Pipelines are defined as code in each application repository as a `Jenkinsfile`, reviewed like any other change.
- Shared logic is factored into a Jenkins Shared Library rather than duplicated per repository.
- Jenkins holds the credentials required to publish artifacts and change each environment.

---

## Consequences

### Positive

- Build execution stays inside the controlled network, satisfying the primary constraint.
- Mature ecosystem; integrations exist for GitHub, SonarQube, Harbor, and container tooling.
- Pipelines as code are reviewable and version-controlled.
- No per-minute execution cost; capacity is bounded by owned hardware.
- Shared libraries make one improvement apply to every pipeline.

### Negative

- **Single point of failure.** No builds, deployments, or orchestrated rollback while it is down. See risk R-01.
- **Credential concentration.** Jenkins holds credentials for every environment and is authorized to change production. Its compromise is compromise of the delivery chain, undetectable by any downstream control. See risk R-07.
- **Operational burden.** Controller patching, plugin management, agent capacity, backup, and restore are ongoing platform-team work.
- **Plugin ecosystem risk.** Capability depends on third-party plugins with varying maintenance and security quality.
- **Groovy pipeline syntax** is a learning cost for developers, and its failure modes are frequently unhelpful.
- **No high availability** at this deployment tier without significant additional work.

### Neutral

- Jenkins is unfashionable relative to newer tools. That is not a technical property, and it does correlate with a smaller pool of engineers who want to work on it.
- Configuration-as-code for the controller itself is possible and not currently adopted — see the review trigger.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **GitHub Actions with self-hosted runners** | Genuinely close. Self-hosted runners execute on organization infrastructure, so the literal constraint is satisfied. Rejected because the control plane, workflow scheduling, and secret storage remain with GitHub — the organization would depend on an external service for its ability to deploy, and secrets would sit outside its infrastructure. This trade-off was judged, not measured, and is the alternative most worth revisiting |
| GitLab CI | Requires adopting GitLab. Source control is already GitHub; migrating it was out of scope |
| TeamCity | Capable and well-regarded. Licensing cost, and no advantage identified over Jenkins for these requirements |
| Drone, Woodpecker | Lighter and more modern. Smaller ecosystem; fewer existing integrations for Harbor and SonarQube |
| Argo Workflows, Tekton | Kubernetes-native. Kubernetes is deliberately not adopted at this stage — see [ADR-0005](0005-use-docker-compose-for-initial-runtime.md) |
| Shell scripts on a schedule | No audit trail, no gating, no credential management. Rejected without further analysis |

---

## Security Considerations

This decision creates the architecture's principal security concentration. Jenkins holds credentials for every environment, is authorized to publish artifacts, and is authorized to change production. An attacker with controller access can deploy arbitrary code through a legitimate path, and every subsequent record will be accurate and misleading.

The mitigations are constraints rather than removals: credential scoping per job and environment, restricted administrative access, ephemeral build agents so a compromise does not persist between builds, controller backup, and audit logging. None is implemented.

Plugin supply chain is a secondary concern. Plugins run with controller privileges, and their maintenance quality varies widely. A plugin inventory with a review process is `TBD`.

## Operational Considerations

Jenkins unavailable stops delivery entirely; it does not stop production, which keeps running. That distinction determines incident urgency — see [disaster-recovery-plan.md](../docs/11-disaster-recovery/disaster-recovery-plan.md).

Controller backup and **tested** restore are the load-bearing operational requirements. The credential store must be backed up with its master key, or the restore produces a system whose every credential is unusable. Neither backup nor restore testing currently exists.

Agent model — ephemeral versus persistent — is undecided and materially affects both build integrity and capacity planning.

---

## Review Trigger

Revisit if any of these hold:

- Jenkins downtime becomes materially expensive, making high availability or a managed alternative worth its cost.
- Plugin maintenance burden or a plugin security incident exceeds the value of the ecosystem.
- Kubernetes is adopted, making Kubernetes-native CI/CD tooling a natural fit.
- The organization becomes comfortable with the control plane residing at GitHub, which would make self-hosted Actions runners a simpler platform to operate.

---

## References

- [Enterprise DevOps architecture](../docs/01-architecture/enterprise-devops-architecture.md)
- [Logical architecture](../docs/01-architecture/logical-architecture.md)
- [Security baseline](../docs/07-security/security-baseline.md)
- [Risk register](../docs/00-executive/risk-register.md)
- [ADR-0009 — deployment mechanism](0009-deployment-mechanism-to-runtime-hosts.md)
