# ADR-0005 — Use Docker Compose for the Initial Runtime

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established. Alternatives were assessed analytically against stated constraints.

---

## Context

Applications are delivered as containers and must run in DEV, UAT, and PROD on Linux hosts. A runtime is needed that starts containers with the correct configuration, restarts them on failure, and can be operated by a small platform team.

Constraints:

- Linux hosts with Docker Engine
- One platform team serving several application teams
- Portainer for operational visibility
- The architecture must remain compatible with a later move to Kubernetes without redesign

The relevant question is not which runtime is most capable. It is which is capable enough, at the lowest operational cost, for the current workload — while leaving the upgrade path open.

---

## Decision

Docker Compose is the initial runtime platform.

In practice:

- Each environment has its own Compose file, with values supplied from outside Git.
- Production Compose files declare an explicit immutable image tag, restart policy, health checks, resource limits, log rotation, and explicit networks.
- Kubernetes is **not** adopted at this stage.

---

## Consequences

### Positive

- Low operational complexity. A small team can operate it without dedicated platform expertise.
- The deployment definition is a readable file, reviewable in a pull request.
- Local development uses the same tool, so what runs on a developer machine resembles what runs on a host.
- Compatible with the promotion model: the same image, different configuration per environment.
- No control plane to install, secure, upgrade, or back up.

### Negative

- **No orchestration.** A lost host takes its environment down with no automatic rescheduling. See risk R-04.
- **No rolling update primitive.** Compose stops and starts containers; achieving zero-downtime deployment requires additional work — a reverse proxy with health-aware routing, or accepting brief downtime. This is the most underestimated limitation of this decision.
- **Manual placement.** Which service runs on which host is decided and maintained by people.
- **Limited scaling.** Horizontal scaling across hosts is not a Compose concept.
- **No built-in secret management.** Secrets arrive through environment files or environment variables, both of which are visible via container inspection.
- Blast radius per host: every container on a host shares its fate, including services belonging to other teams.

### Neutral

- Portainer provides visibility, and must not become a deployment path — a governance boundary enforced by permissions rather than by the runtime.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Kubernetes** | Solves rescheduling, rolling updates, scaling, and secret handling. Rejected for now: it introduces a control plane to install, secure, upgrade, back up, and recover, plus a substantial learning cost — a permanent operational burden accepted before the pain it addresses exists. It remains the intended destination if the triggers below are met |
| Docker Swarm | Closest to Compose in syntax and adds rescheduling and rolling updates at low complexity. Genuinely the strongest alternative on capability-per-effort. Rejected because its long-term maintenance direction is uncertain, and adopting a runtime whose future is unclear risks a second migration |
| HashiCorp Nomad | Simpler than Kubernetes and provides scheduling. Rejected as another platform to learn and operate for a workload that does not yet need scheduling; smaller ecosystem |
| `systemd` with `docker run` | Fewer moving parts than Compose. Rejected: multi-container definitions become unreadable, and the deployment definition stops being a reviewable artifact |
| Managed container services | External dependency, cloud relationship not otherwise required, and the constraint is on-premises infrastructure |

---

## Security Considerations

Compose has no secret management. Values reach containers as environment variables, which are visible to anyone with container inspection access and inherited by every child process. This is why container inspection is treated as closer to credential access than to observation — see [production-access-policy.md](../docs/10-governance/production-access-policy.md).

Docker Compose supports file-based secrets, which avoid both properties. Whether to adopt them is `TBD` and would materially reduce this exposure.

Shared host fate is a security property as well as an availability one: a container escape reaches every other container on the host, across team boundaries.

## Operational Considerations

Two Compose settings are omitted by default and both fail at the host level rather than the service level:

- **Log rotation.** The default driver has no size limit; a service logging steadily fills the host disk and stops every container on it.
- **Resource limits.** Without a memory limit, one leaking container causes the kernel to kill something — not necessarily the container at fault.

Both are one-line settings and both prevent host-wide outages.

The rolling update gap deserves planning before the first production deployment rather than discovery during it. `TBD` — whether brief downtime is acceptable per service, or whether a health-aware reverse proxy is required.

Host configuration as code would make host rebuild fast, which is the mitigation available for the absence of rescheduling. It is `TBD`.

---

## Review Trigger

Adopt orchestration when any of these hold — not before:

- Single-host failure becomes operationally unacceptable for a production service.
- The number of services makes manual placement impractical or error-prone.
- Zero-downtime deployment becomes a requirement the reverse-proxy approach cannot satisfy.
- Horizontal scaling across hosts becomes necessary.
- Secret handling through environment variables becomes unacceptable and file-based secrets are insufficient.

Any of these justifies revisiting. None of them is currently true, and adopting Kubernetes before one is true adds permanent complexity for no return.

---

## References

- [Docker Compose standard](../docs/06-container/docker-compose-standard.md)
- [Environment architecture](../docs/01-architecture/environment-architecture.md)
- [Logical architecture](../docs/01-architecture/logical-architecture.md) — extension points
- [DevOps roadmap](../docs/00-executive/devops-roadmap.md)
