# Infrastructure Standard

## Purpose

Defines the baseline configuration for every Linux host running platform components or application containers.

## Scope

Host operating system, Docker Engine, filesystem layout, and hardening. Sizing is in [server-sizing-guideline.md](server-sizing-guideline.md); installation sequence is in [platform-installation-strategy.md](platform-installation-strategy.md); network rules are in [03-network/](../03-network/).

## Audience

Platform engineers building and operating hosts.

## Status

**Draft for review.** No host has been built. OS distribution and versions are undecided.

---

## 1. Host Roles

| Role | Runs | Notes |
| --- | --- | --- |
| Toolchain host | Jenkins, SonarQube, Harbor | `TBD` — whether these share one host or are separated |
| Observability host | Prometheus, Grafana, Loki | `TBD` — whether separated from the toolchain host |
| DEV runtime | Application containers, Portainer | |
| UAT runtime | Application containers, Portainer | |
| PROD runtime | Application containers, Portainer | Strictest access |

`TBD` — the actual topology. Separating Harbor from Jenkins is worth doing early: they have different storage profiles and different failure consequences, and separating them later means moving image storage.

---

## 2. Operating System

| Item | Requirement |
| --- | --- |
| Distribution | `TBD` — a long-term-support release the team can actually support |
| Installation | Minimal. No desktop, no unnecessary services |
| Timezone | **UTC** on every host |
| Time synchronization | **Required**, and monitored |
| Locale | `TBD` |
| Swap | See section 5 |

Time synchronization is not housekeeping. Log correlation across services depends on clocks agreeing, and clock drift produces an incident where events appear in the wrong order — which is worst exactly when the order matters.

`TBD` — NTP source, and alerting on drift.

---

## 3. Filesystem Layout

**`/var/lib/docker` must be on its own filesystem.**

Container images, layers, volumes, and logs all accumulate there. On a shared root filesystem, growth in any of them fills `/` — which stops every container *and* removes the operating system's own ability to recover, because it cannot write logs, temporary files, or package state.

On a separate filesystem, the same growth fills that filesystem and leaves the host usable enough to diagnose and clean up.

| Mount | Purpose | Sizing driver |
| --- | --- | --- |
| `/` | OS | Small, fixed |
| `/var/lib/docker` | Images, layers, containers, volumes, logs | **Grows continuously** |
| `/var/log` | Host logs | Bounded by rotation |
| Harbor storage | Image layers, on the registry host | Grows continuously |

`TBD` — sizes; see [server-sizing-guideline.md](server-sizing-guideline.md).

---

## 4. Docker Engine

### Daemon configuration

The `default-address-pools` value below is a **placeholder**. Do not copy it without checking it against the organization's internal addressing — see the note under the block.

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "live-restore": true,
  "default-address-pools": [
    { "base": "10.200.0.0/16", "size": 24 }
  ],
  "userland-proxy": false,
  "no-new-privileges": true
}
```

Each line is there for a reason.

**`log-opts` at the daemon level.** The default json-file driver has **no size limit**. Setting it per service in Compose is required by the Compose standard; setting it here as well means a service that omits it is still bounded. Defence in depth against a one-line omission with host-wide consequences.

**`default-address-pools`.** Docker allocates bridge networks from `172.17.0.0/16` onwards by default. If the organization uses any of that range internally — and `172.16.0.0/12` is a common corporate range — containers will be unable to reach those internal addresses, because the host routes them to a Docker bridge instead. The failure looks like a firewall problem and is not. **Set this before creating any network**, because changing it later means recreating them.

`TBD` — the pool range, confirmed against the organization's internal addressing.

**`live-restore`.** Containers keep running across a daemon restart. Without it, restarting or upgrading Docker stops every container on the host.

**`no-new-privileges`.** Prevents processes gaining privileges through setuid binaries.

### Version and upgrades

| Item | Requirement |
| --- | --- |
| Version | `TBD` — pinned, upgraded deliberately |
| Compose | v2 plugin |
| Upgrade | A change under [change-management.md](../10-governance/change-management.md); see [scheduled-maintenance.md](../../sop/scheduled-maintenance.md) |

---

## 5. Memory and Swap

Container memory limits and swap interact in a way that surprises people.

With swap enabled, a container exceeding its memory limit may swap rather than be killed. The container survives and becomes extremely slow — which is often worse operationally than being killed and restarted, because a slow service fails its consumers' timeouts while continuing to report itself healthy.

`TBD` — whether swap is disabled on runtime hosts. Disabling it makes limit violations fail fast and visibly. Keeping it provides headroom against transient spikes.

.NET applications need the runtime configured to respect the container limit. A runtime unaware of its limit sizes its heap against total host memory and is killed at a threshold it never anticipated.

---

## 6. Users and Access

| Requirement | Reason |
| --- | --- |
| No direct root login | Attribution |
| A dedicated non-root account for deployment | Its credentials are what the pipeline holds |
| Docker group membership is **effectively root** | Anyone in it can mount the host filesystem into a container. Grant it as you would grant root |
| SSH key authentication only, no passwords | |
| Host access follows the tier model | See [production-access-policy.md](../10-governance/production-access-policy.md) |

The Docker group point is the one most often underestimated. "Add the user to the docker group" reads as a convenience and is a grant of root-equivalent access to that host.

---

## 7. Hardening Baseline

`TBD` — confirm against the organization's server baseline, which takes precedence if one exists.

| Control | Requirement |
| --- | --- |
| Firewall | Default deny inbound; allow-list per [03-network/](../03-network/) |
| Unused services | Removed or disabled |
| Automatic security updates | `TBD` — see below |
| SSH | Key-only; no root login; restricted source addresses |
| Audit logging | `TBD` |
| File integrity monitoring | `TBD` |

Automatic updates need a decision rather than a default. Applied automatically, they close vulnerabilities quickly and can restart services without warning. Applied manually, they are controlled and get deferred. A common resolution is automatic for security patches only, with reboots scheduled — but that is a decision, not an obvious answer.

---

## 8. What Must Not Run on a Runtime Host

- Application build tooling — builds happen on build agents
- Anything that pulls source and compiles it
- Development or debugging tooling beyond what operations genuinely needs
- A second, ungoverned deployment path

The last is the one that appears gradually: a script, a cron job, a helpful automation that changes production outside the pipeline. Each is reasonable alone; together they mean the audit trail stops describing reality.

---

## 9. Blocked by ADR-0009

**What must be installed on a runtime host depends on the undecided deployment mechanism.**

| Option | Additional software on runtime hosts |
| --- | --- |
| A — Jenkins agent | Agent plus a JVM, on every host including production |
| B — SSH over internal network | None; SSH key configuration only |
| C — Pull-based agent | Agent, plus a desired-state source as a new platform component |
| D — Portainer API | None beyond Portainer — not recommended, see [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) |

Everything else in this document is independent of that decision.

---

## 10. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — OS distribution and version | Everything |
| `TBD` — topology: which components share which hosts | Sizing, failure isolation |
| `TBD` — `default-address-pools` range, checked against internal addressing | Container connectivity to internal systems |
| `TBD` — Docker Engine version and upgrade cadence | Stability |
| `TBD` — swap on runtime hosts | Failure behaviour under memory pressure |
| `TBD` — automatic security updates | Patch currency versus control |
| `TBD` — NTP source and drift alerting | Log correlation |
| `TBD` — organizational server hardening baseline, if one exists | This document defers to it |
| `TBD` — host configuration as code | Rebuild speed, which is the mitigation for having no rescheduling |

The last is the highest-value item. With no orchestration, host loss is recovered by rebuilding — and rebuild speed is entirely determined by whether the configuration exists anywhere other than on the lost host.

---

## Security Considerations

Docker group membership is root-equivalent on that host. Treat it as such when granting.

The `default-address-pools` setting has a security dimension as well as a connectivity one: a container network overlapping an internal range can shadow internal services, so traffic intended for an internal system reaches a container instead.

Runtime hosts hold pull-only registry credentials and the environment files containing application secrets. Their file permissions and the host's access model are what protect those.

## Operational Considerations

Two settings prevent host-wide outages and both are omitted by default: daemon-level log limits, and `/var/lib/docker` on its own filesystem. Together they mean unbounded growth fills something recoverable rather than the root filesystem.

`live-restore` is what makes a Docker upgrade something other than an outage for every container on the host.

---

## Related

- [Server sizing guideline](server-sizing-guideline.md)
- [Platform installation strategy](platform-installation-strategy.md)
- [High availability roadmap](high-availability-roadmap.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
- [Production access policy](../10-governance/production-access-policy.md)
