# Server Sizing Guideline

## Purpose

Guidance for sizing hosts per role, and — more usefully — what actually drives growth in each.

## Scope

CPU, memory, and storage per host role. Host configuration is in [infrastructure-standard.md](infrastructure-standard.md).

## Audience

Platform engineers and whoever approves infrastructure spend.

## Status

**Draft for review.** The figures below are **starting points, not requirements.** No workload has been measured, because nothing is running.

---

## 1. Read the Growth Drivers, Not the Numbers

Sizing figures for a workload nobody has measured are guesses. The growth drivers are not — they are properties of the architecture and they hold regardless of scale.

Use the drivers to decide what to monitor from day one, and revise the figures once there is data.

---

## 2. Growth Drivers by Component

| Component | Grows with | Bounded by |
| --- | --- | --- |
| **Harbor storage** | Builds per day × unique layer size × retention days | Retention policy and garbage collection |
| Harbor database | Artifact count, scan results | Retention |
| Jenkins | Build history, workspaces, artifacts | Build retention, workspace cleanup |
| SonarQube database | Analyses × history depth | Analysis retention |
| Prometheus | **Series count** × scrape frequency × retention | Cardinality discipline and retention |
| Loki | Log volume × retention; plus stream count | Log volume and label cardinality |
| Runtime hosts | Images, container logs, volumes | Log rotation, image pruning |

Two of these fail suddenly rather than gradually.

**Prometheus** is driven by series count, not by the number of services. One label carrying an unbounded value multiplies it without warning — see [monitoring-standard.md](../08-observability/monitoring-standard.md#5-labels-and-cardinality).

**Harbor** does not shrink when tags are deleted. Space is reclaimed only by garbage collection, and only for layers nothing references — so reclaimed space is routinely far less than the size of what was deleted.

---

## 3. Starting Points

**`TBD` throughout.** These are shapes for a first conversation, sized for a small number of application teams.

| Role | CPU | Memory | Storage | Dominant driver |
| --- | --- | --- | --- | --- |
| Jenkins controller | 4 | 8 GB | 100 GB | Build history and artifacts |
| Jenkins agent | 4–8 | 8–16 GB | 100 GB | Concurrent builds; container build cache |
| Harbor | 4 | 8 GB | **500 GB+, and growing** | Image layers |
| SonarQube | 4 | 8 GB (JVM heap sized deliberately) | 100 GB | Database |
| Observability | 4 | 16 GB | 200 GB+ | Prometheus series; Loki volume |
| DEV runtime | 4 | 8 GB | 100 GB | Containers, images, logs |
| UAT runtime | 4 | 8 GB | 100 GB | As above |
| PROD runtime | `TBD` — from workload | `TBD` | `TBD` | Application requirements |

Production sizing must come from the workload, not from this table. Copying DEV's figures to production is how a service meets its first real traffic on hardware sized for nobody.

---

## 4. Jenkins Agents Are the Variable

The controller is comparatively stable. Agents are where capacity is consumed and where sizing is most likely to be wrong.

| Driver | Effect |
| --- | --- |
| Concurrent builds | The main determinant. Agent count × capacity per agent |
| Container builds | Disk-heavy; the build cache grows quickly |
| .NET builds | Memory-heavy during compilation |
| Node builds | `node_modules` is large and is written per workspace |
| Workspace retention | Multiplies disk by the number of retained workspaces |

`TBD` — agent count and whether agents are ephemeral. Ephemeral agents cost more to provision per build and remove both the disk accumulation problem and the security concern of a compromise persisting between builds.

---

## 5. Harbor Storage Deserves Its Own Forecast

It is the storage that grows fastest and the one whose exhaustion has the widest consequence: publication fails, and depending on configuration, pulls fail — which blocks deployment **and rollback**.

```text
storage ≈ builds per day × average unique layer size × retention days
```

Two properties make naive estimates wrong in opposite directions:

- Layers are **shared**, so total consumption is much less than the sum of image sizes. Many images differ only in their application layer.
- Deleting an image frees only layers nothing else references, so **reclaimed space is also much less than expected**.

`TBD` — measured build volume and image size, once the platform exists. Until then, over-provision and monitor: running out is a platform-wide outage, and adding storage later is cheaper than the incident.

Alert well before exhaustion, with enough margin to run garbage collection — which itself requires a maintenance window.

---

## 6. Runtime Host Sizing

Sum of the container resource limits on that host, plus headroom.

| Consideration | Note |
| --- | --- |
| Sum of limits may exceed physical memory | Docker allows overcommit. It works until every container uses its limit at once |
| Headroom for the OS and Docker | Do not allocate every byte |
| Disk: images, logs, volumes | Log rotation and image pruning are what keep this bounded |
| Blast radius | Every container on a host shares its fate, across team boundaries |

The last is a sizing decision as much as an availability one. Packing more services onto one host is cheaper and widens what a single host failure takes down.

---

## 7. What to Monitor From Day One

Sizing is revised from data. These are the series that produce it:

| Metric | Answers |
| --- | --- |
| Filesystem usage per mount, per host | When storage runs out — with lead time |
| Harbor storage used, and growth rate | The forecast in section 5 |
| Prometheus series count | Whether cardinality is under control |
| Loki stream count and ingest volume | The same, for logs |
| Jenkins queue depth and build duration | Whether agent capacity is sufficient |
| Container memory against limit | Whether limits are right |
| Host CPU and memory | Whether the host is right |

The first is the one that must have an alert with genuine lead time. A full disk stops every container on the host and often the host's own recovery.

---

## 8. Scaling Path

| Signal | Response |
| --- | --- |
| Jenkins queue depth grows | Add agents before enlarging the controller |
| Harbor storage growth outpaces retention | Revisit retention against required rollback depth — **not** the other way round |
| Prometheus memory growth | Investigate series count first; it is usually cardinality, not scale |
| Runtime host saturation | Separate services across hosts, which also reduces blast radius |
| Toolchain host contention | Separate Harbor, then SonarQube, then observability |

The Harbor row states the direction deliberately. Retention determines how far back a rollback can reach; tuning it down to fit storage silently shortens the recovery window, and the consequence appears only at a rollback attempt.

---

## 9. Open Items

| Item |
| --- |
| `TBD` — every figure in section 3, once measured |
| `TBD` — topology: which components share which hosts |
| `TBD` — Jenkins agent count, and ephemeral versus persistent |
| `TBD` — Harbor storage allocation and growth forecast |
| `TBD` — production sizing from actual workload |
| `TBD` — storage alert thresholds, with lead time for garbage collection |
| `TBD` — whether virtualization or physical, and what that constrains |

---

## Security Considerations

Blast radius is a sizing decision. Packing services onto fewer hosts is cheaper and means a container escape or a host compromise reaches more, across team boundaries.

Storage exhaustion is an availability failure with a security dimension: when Harbor is full nothing can be published, and the pressure to disable a control to get a release out arrives immediately.

## Operational Considerations

Under-provisioned storage is the most likely first capacity incident, and Harbor is the most likely place. It grows continuously, does not shrink on tag deletion, and its exhaustion blocks both deployment and rollback.

The figures in this document are guesses and are labelled as such. The value is in sections 2 and 7: knowing what drives growth, and measuring it from the first day the platform runs.

---

## Related

- [Infrastructure standard](infrastructure-standard.md)
- [Platform installation strategy](platform-installation-strategy.md)
- [Image retention policy](../06-container/image-retention-policy.md)
- [Monitoring standard](../08-observability/monitoring-standard.md)
- [Harbor standard](../06-container/harbor-standard.md)
