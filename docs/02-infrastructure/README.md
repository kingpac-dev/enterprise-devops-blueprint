# 02 — Infrastructure

## Purpose

Defines the server and platform infrastructure that hosts the delivery toolchain and application runtimes.

## Scope

Host standards, sizing guidance, platform installation strategy, and the high-availability roadmap. Network flows and firewall rules belong in [03-network/](../03-network/).

## Audience

Platform engineers, infrastructure engineers, and operations.

## Status

**Draft for review.** All four documents are written. No host has been built; sizing figures are unmeasured starting points.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [infrastructure-standard.md](infrastructure-standard.md) | Host OS baseline, filesystem layout, Docker daemon configuration, users, hardening | Draft |
| [server-sizing-guideline.md](server-sizing-guideline.md) | Growth drivers per component, starting figures, what to monitor from day one | Draft |
| [platform-installation-strategy.md](platform-installation-strategy.md) | Install order with per-step verification | Draft |
| [high-availability-roadmap.md](high-availability-roadmap.md) | Current single points of failure, what removes each, cost, and what justifies it | Draft |
| [database-standard.md](database-standard.md) | PostgreSQL on a dedicated host: separation, credentials, connections, backup, monitoring, access | Draft |

## Reading Order

1. [infrastructure-standard.md](infrastructure-standard.md) — how a host is configured
2. [server-sizing-guideline.md](server-sizing-guideline.md) — how big, and what makes it grow
3. [platform-installation-strategy.md](platform-installation-strategy.md) — the order things go in
4. [high-availability-roadmap.md](high-availability-roadmap.md) — what is knowingly accepted, and what would change it
5. [database-standard.md](database-standard.md) — the component whose loss is least recoverable

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **`/var/lib/docker` must be its own filesystem.** On a shared root, growth in images, volumes, or logs fills `/` — which stops every container *and* removes the OS's own ability to recover | [infrastructure-standard.md](infrastructure-standard.md#3-filesystem-layout) |
| **`default-address-pools` must be checked against internal addressing before any network is created.** Docker's default `172.17.0.0/16` onward can collide with a corporate range, and the resulting failure looks like a firewall problem. Changing it later means recreating every network | [infrastructure-standard.md](infrastructure-standard.md#4-docker-engine) |
| **Docker group membership is root-equivalent** on that host. "Add the user to the docker group" reads as a convenience and grants the ability to mount the host filesystem into a container | [infrastructure-standard.md](infrastructure-standard.md#6-users-and-access) |
| **Install Harbor before Jenkins**, and **back up before the first pipeline.** Backing up an empty platform is the only time the first restore test is cheap | [platform-installation-strategy.md](platform-installation-strategy.md#2-order-and-why) |
| Two installation checks are **negative tests**: a runtime credential must fail to push, and an existing tag must fail to be overwritten. Both confirm a control is real rather than intended | [platform-installation-strategy.md](platform-installation-strategy.md#4-step-2--harbor) |
| The four cheapest availability improvements — restore testing, heartbeat, backups, a host-local image cache — **add no components** and none requires the platform to be complete | [high-availability-roadmap.md](high-availability-roadmap.md#4-order-by-value-per-cost) |
| **The application database is the one thing not reproducible from source.** The blueprint's recovery mechanism — redeploy the previous image — does not reach it, and its backup does not yet exist | [database-standard.md](database-standard.md#1-the-database-is-not-a-container) |
| The account the application runs as should not hold `CREATE`, `ALTER`, or `DROP`. A separate migration account costs a grant statement and means an application defect cannot drop a table | [database-standard.md](database-standard.md#3-credentials) |

---

## Baseline Topology (Starting Point, Not a Sizing Model)

```text
Server 1   Supporting source-control integration services as required
Server 2   Jenkins, SonarQube, Trivy tooling, Harbor, observability where practical
Server 3   DEV runtime
Server 4   UAT runtime
Server 5   PROD runtime
```

For larger environments, recommend separating Jenkins, Harbor, SonarQube, and monitoring when justified by workload.

Production sizing must consider workload, storage, redundancy, availability, backup, and recovery requirements.

---

## Open Items

- `TBD` — server inventory, hostnames, and addresses
- `TBD` — storage capacity and growth assumptions for Harbor
- `TBD` — OS baseline and patching cadence
- `TBD` — whether observability shares Server 2 or is separated
- `TBD` — **application database backup, retention, and WAL archiving.** It does not exist, and it is the one thing not reproducible from source
- `TBD` — data classification, which sets the requirements above it

---

## Related

- [Documentation index](../README.md)
- [Architecture](../01-architecture/)
- [Network](../03-network/)
- [Disaster recovery](../11-disaster-recovery/)
