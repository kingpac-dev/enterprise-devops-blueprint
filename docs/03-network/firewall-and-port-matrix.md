# Firewall and Port Matrix

## Purpose

The rule set: every flow the platform requires, with source, destination, port, direction, and the reason it exists.

## Scope

Derived directly from the interaction catalogue in [service-interaction.md](../01-architecture/service-interaction.md#1-interaction-catalogue). Interaction identifiers are preserved so a rule can be traced back to the reason it exists.

## Audience

Network engineers implementing rules, and security engineers reviewing them.

## Status

**Draft for review.** Ports are defaults requiring confirmation. **Addresses are deliberately absent** — see below.

---

## No Real Addresses in This Repository

This document defines **flows**, not addresses. Real IP addresses, internal DNS names, and production firewall rules must not be committed here — they carry reconnaissance value and this repository is more widely readable than the systems it describes.

The authoritative rule set lives in the controlled network configuration system. This is the specification it is built from.

`TBD` — where the authoritative rule set is held.

---

## 1. Default Posture

| | |
| --- | --- |
| Inbound | **Default deny.** Allow-list only |
| Outbound | **Controlled.** Allow-list per section 4 |
| Between zones | Default deny; allow-list per section 3 |
| Between runtime environments | **Deny, with no exception** |

---

## 2. Inbound From Outside the Platform

**One rule.**

| ID | Source | Destination | Port | Protocol | Purpose |
| --- | --- | --- | --- | --- | --- |
| I-02 | GitHub webhook addresses | Jenkins controller | 443 | HTTPS | Notify that a change occurred |

| Requirement | |
| --- | --- |
| Source restriction | GitHub's published webhook address ranges — `TBD`, and they change; the list needs maintenance |
| Authentication | Webhook secret — `TBD` |
| TLS | Required |

**This is the platform's entire external attack surface.** It is one authenticated endpoint, and that is worth defending against additions.

`TBD` — whether this rule is needed at all. Jenkins can poll GitHub instead, which removes the platform's only inbound path at the cost of latency between push and build.

---

## 3. Internal Flows

Direction is stated from the initiator, because that is what determines the rule.

### Toolchain zone, outbound

| ID | Source | Destination | Port | Protocol | Purpose |
| --- | --- | --- | --- | --- | --- |
| I-03 | Jenkins controller, agents | GitHub | 443 | HTTPS | Checkout; status reporting |
| I-04 | Jenkins agents | SonarQube | 443 | HTTPS | Submit analysis; read gate |
| I-05 | Jenkins agents | Harbor | 443 | HTTPS | Push and pull images |
| I-06 | Jenkins | Runtime hosts | **`TBD`** | **`TBD`** | Deploy, verify, roll back — see section 6 |

### Runtime zones, outbound

| ID | Source | Destination | Port | Protocol | Purpose |
| --- | --- | --- | --- | --- | --- |
| I-07 | DEV, UAT, PROD hosts | Harbor | 443 | HTTPS | **Pull only** |
| I-09 | Runtime hosts | Loki | 3100 | HTTP | Ship logs |

I-07 is initiated by the runtime host. **Harbor needs no access to runtime hosts at all.**

### Observability zone, outbound

| ID | Source | Destination | Port | Protocol | Purpose |
| --- | --- | --- | --- | --- | --- |
| I-08 | Prometheus | Application containers | 8080 | HTTP | Scrape metrics |
| I-08 | Prometheus | Container and host exporters | 8081, 9100 | HTTP | Scrape infrastructure metrics |
| I-08 | Prometheus | Platform components | `TBD` | HTTP | Scrape Jenkins, Harbor, SonarQube |
| I-10 | Grafana | Prometheus | 9090 | HTTP | Query |
| I-10 | Grafana | Loki | 3100 | HTTP | Query |
| I-11 | Prometheus or Alertmanager | Alert destination | `TBD` | `TBD` | Deliver alerts |

**Prometheus initiates into the runtime zones.** That is a deliberate access decision, not an implementation detail: monitoring reaches inward, so the rule permits the observability zone to reach runtime ports that nothing else may.

### Client zone

| ID | Source | Destination | Port | Protocol | Purpose |
| --- | --- | --- | --- | --- | --- |
| — | Developers, operators | Jenkins, SonarQube, Harbor, Grafana web | 443 | HTTPS | Use the platform |
| I-12 | Operators | Portainer | 9443 | HTTPS | Inspect and troubleshoot — restricted per environment |
| — | Operators | Runtime host SSH | 22 | SSH | Tier 3–4 access only; restricted source |

Portainer and SSH follow the access tiers in [production-access-policy.md](../10-governance/production-access-policy.md). The network rule is the outer bound; the tier model is what decides who is inside it.

---

## 4. Outbound to External

Required. A blanket egress block stops delivery.

| ID | Source | Destination | Port | Purpose | If blocked |
| --- | --- | --- | --- | --- | --- |
| I-03 | Jenkins, agents | GitHub | 443 | Checkout, status | No builds |
| — | Build agents | npm registry | 443 | Dependency restore | No frontend builds |
| — | Build agents | NuGet | 443 | Dependency restore | No .NET builds |
| — | Build agents | Base image registry | 443 | Docker build | No image builds |
| I-14 | Trivy | Vulnerability database | 443 | Scanner currency | **Silent failure — see below** |

**I-14 is the row to get right.** A blocked database update does not fail the scan. It produces a clean report against a stale database, indistinguishable from a genuinely clean scan.

`TBD` — permitted egress, or internal mirrors. A mirror removes the external dependency and adds a component to operate; permitted egress is simpler and depends on destination addresses that change.

---

## 5. Denied, Explicitly

| Flow | Reason |
| --- | --- |
| DEV → UAT, DEV → PROD | DEV is the natural pivot: widest access, weakest controls |
| UAT → PROD | Same, one step up |
| Any runtime host → any other environment's services or database | Environment separation is a boundary |
| Harbor → runtime hosts | Harbor never initiates. Hosts pull |
| Runtime hosts → GitHub, package feeds | Runtime hosts do not build |
| Internet → any administrative interface | Not without explicit justification and compensating controls |
| Internet → any runtime host | |

The second-to-last row is the one that erodes. Each administrative interface has a plausible reason to be reachable "just from the office", and each such rule is a permanent addition to the external surface.

---

## 6. I-06: The Undecided Rule

**The deployment flow's direction depends on [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md), and direction is what a firewall rule is.**

| Option | Rule required | Inbound to runtime hosts |
| --- | --- | --- |
| **A** — Jenkins agent on host | Runtime host → Jenkins controller, `TBD` port (JNLP or HTTPS) | **None** |
| **B** — SSH over internal network | Jenkins controller → runtime host, 22/SSH, **source-restricted to the toolchain zone** | SSH |
| **C** — Pull-based agent | Runtime host → desired-state source, `TBD` | **None** |
| **D** — Portainer API | Jenkins controller → Portainer, 9443/HTTPS | Portainer API |

Options **A** and **C** preserve the property that runtime hosts accept **no inbound connections** — which is the strongest position available and the one the constraint in `AGENTS.md` was written to protect.

Option **B** requires SSH inbound from the toolchain zone. It satisfies the constraint literally, since the exposure is internal rather than public. Whether that satisfies its **intent** is question 6 in ADR-0009 and should be answered by the security owner explicitly and recorded — whichever option is chosen.

This is the only rule in this document that cannot be written today.

---

## 7. Verification

A firewall configuration that reads correctly and behaves otherwise is common here, because **Docker manipulates the packet filter directly and its rules are commonly evaluated before the host firewall's**.

Verify by testing, not by reading configuration:

- [ ] From outside the platform: only the webhook endpoint is reachable
- [ ] From the DEV zone: UAT and PROD are unreachable
- [ ] From a runtime host: Harbor is reachable, GitHub is not
- [ ] From a runtime host: a **push** to Harbor fails (pull-only credential)
- [ ] From the observability zone: scrape targets are reachable
- [ ] From the client zone: administrative interfaces reachable, runtime ports not
- [ ] After any container change: published ports are not reachable from outside the host unless intended

The last check is the one that catches the Docker behaviour. Re-run it whenever a Compose file changes a `ports:` entry.

`TBD` — whether this verification is automated and run on a schedule. Firewall rules drift, and drift is silent.

---

## 8. Open Items

| Item |
| --- |
| `TBD` — **I-06 rule** ([ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)) |
| `TBD` — whether the GitHub webhook is used at all |
| `TBD` — GitHub webhook source ranges, and how the list is maintained |
| `TBD` — permitted egress versus internal mirrors |
| `TBD` — platform component metrics ports |
| `TBD` — alert destination and its port |
| `TBD` — where the authoritative rule set is held |
| `TBD` — whether connectivity verification is automated |

---

## Security Considerations

Section 2 contains one rule. That number is the design's principal security property, and every future addition should be justified against it.

Section 5's explicit denials matter as much as the allowances. A rule set that only lists what is permitted leaves the reader unable to tell whether a flow was considered and denied, or simply never considered.

Pull-only registry credentials (I-07) and the absence of a Harbor → host flow are what prevent a compromised runtime host from becoming a supply-chain compromise. The network rule and the credential scope reinforce each other; neither alone is sufficient.

## Operational Considerations

Section 4 prevents the class of incident where egress restrictions break builds in ways that look like tooling failures. Enumerate the platform's real outbound needs before restricting, and treat I-14 as special because it degrades into false assurance rather than failing.

Section 7's verification is the only way to know the rules do what they read as doing, given Docker's packet-filter behaviour.

---

## Related

- [Network architecture](network-architecture.md)
- [Network security baseline](network-security-baseline.md)
- [Service interaction](../01-architecture/service-interaction.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
- [Production access policy](../10-governance/production-access-policy.md)
