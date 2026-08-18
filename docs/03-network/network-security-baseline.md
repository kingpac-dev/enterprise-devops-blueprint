# Network Security Baseline

## Purpose

The network controls that apply regardless of topology, and the failure modes each prevents.

## Scope

Controls and their rationale. The zones are in [network-architecture.md](network-architecture.md); the rules are in [firewall-and-port-matrix.md](firewall-and-port-matrix.md).

## Audience

Network engineers, platform engineers, and security engineers.

## Status

**Draft for review.** Not implemented.

---

## 1. Controls

| Control | Requirement | Status |
| --- | --- | --- |
| Default deny inbound | Allow-list only | Not implemented |
| Controlled outbound | Enumerated, not blanket-permitted | Not implemented |
| Network segmentation | Zones per [network-architecture.md](network-architecture.md) | Not implemented |
| Environment isolation | DEV, UAT, PROD mutually unreachable | Not implemented |
| TLS across zone boundaries | Required | Not implemented |
| Administrative interfaces not publicly exposed | Without explicit justification and compensating controls | Not implemented |
| Source-restricted rules | Not "any" on the source side | Not implemented |
| Connectivity verified by testing | Not by reading configuration | Not implemented |

Every row reads "not implemented" because nothing has been built. That is the accurate state, and stating it is more useful than a table that reads as though the network were protected.

---

## 2. Least Privilege Applied to Flows

A rule permits a specific source to reach a specific destination on a specific port for a stated reason.

| Anti-pattern | Consequence |
| --- | --- |
| Source `any` | The rule protects nothing on the source side |
| A port range where one port is needed | Everything else in the range is reachable too |
| A rule with no recorded reason | Nobody can ever safely remove it |
| A rule added "temporarily" | It is permanent, because removing it risks breaking something unknown |

The last two compound. Rules accumulate, each individually defensible, and the set becomes something nobody will touch — at which point the firewall documents history rather than intent.

`TBD` — periodic rule review, which is the only thing that reverses this.

---

## 3. Egress Is a Control, Not an Obstacle

Controlled outbound access limits what a compromised component can reach and exfiltrate to. It is also the control most likely to break delivery if applied without understanding what the platform genuinely needs.

**Enumerate before restricting** — see [firewall-and-port-matrix.md](firewall-and-port-matrix.md#4-outbound-to-external).

Two cases deserve separate treatment:

**Backend container networks** are marked `internal: true`, which removes their route out entirely. One line, and the components most worth isolating cannot reach the internet.

**The vulnerability database** fails silently when blocked. The scan still runs and returns a clean report against stale data — indistinguishable from a genuinely clean scan. Every other blocked egress produces a visible failure; this one produces false assurance.

---

## 4. Docker Bypasses the Host Firewall

Docker inserts its own packet-filter rules, and they are commonly evaluated **before** the host firewall's. **A published port can be reachable on a host whose firewall configuration says otherwise.**

| Mitigation | |
| --- | --- |
| Bind published ports to a specific address | `127.0.0.1:8080:8080`, never `8080:8080` |
| Reach services through a reverse proxy | Rather than publishing them directly |
| Use `internal: true` for backend networks | Removes the outbound route |
| **Verify reachability by testing** | The only way to know, given the above |

This is the most likely cause of an unintended exposure in this architecture, precisely because the configuration will look correct.

`TBD` — confirm the interaction between Docker and the chosen host firewall, by testing.

---

## 5. TLS

| Requirement | |
| --- | --- |
| Zone boundaries | Required |
| Registry push and pull | **Required** — credentials cross on every operation |
| Analysis submission | Required — the token crosses |
| Web interfaces | Required |
| Certificate expiry | **Monitored and alerted** |

Certificate expiry is on the alert list because it is a predictable, preventable outage with ample lead time — one of the few cases where alerting on a cause rather than a symptom is correct.

`TBD` — certificate management: internal certificate authority or external issuer, and the renewal procedure.

---

## 6. Administrative Interfaces

Jenkins, Harbor, SonarQube, Grafana, Portainer, and host SSH are **internal only**.

Public exposure requires explicit justification and compensating controls, recorded as an exception. "Convenient for remote work" is a reason, not a justification, and the compensating controls — authentication strength, source restriction, session recording — need naming rather than assuming.

Portainer is restricted further per environment, because its modification capability is what would turn it into an ungoverned deployment path.

---

## 7. Environment Isolation Is Half of the Secret Boundary

Distinct credentials per environment prevent a compromise from **authenticating**. Network isolation prevents it from **reaching**.

Both are required, because either alone fails to a single mistake in the other: a credential accidentally reused is contained by the network; a firewall rule accidentally widened is contained by the credentials.

DEV is the environment to reason about. It has the widest access, the least sensitive data, and the weakest controls — which makes it the natural first target and the natural pivot point.

---

## 8. What This Baseline Does Not Cover

| Not covered | Where it belongs |
| --- | --- |
| Application-level authentication and authorization | Application design |
| Data encryption at rest | `TBD` — not addressed in this blueprint |
| Intrusion detection | `TBD` — organizational security tooling |
| DDoS protection | Not applicable; nothing is publicly exposed |
| VPN and remote access | `TBD` — organizational, and it governs how the client zone is reached |

The last is worth noting: this baseline assumes the client zone is inside the controlled network. How people get there is an organizational control that this document depends on and does not define.

---

## 9. Open Items

| Item |
| --- |
| `TBD` — segmentation implementation |
| `TBD` — addressing plan, checked against Docker's `default-address-pools` |
| `TBD` — permitted egress versus internal mirrors |
| `TBD` — certificate management and renewal |
| `TBD` — Docker and host firewall interaction, **verified by testing** |
| `TBD` — periodic firewall rule review |
| `TBD` — whether connectivity verification is automated |
| `TBD` — remote access model for the client zone |
| `TBD` — **deployment mechanism** ([ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md)) |

---

## Security Considerations

The controls that carry the most weight here are default-deny inbound, environment isolation, and administrative interfaces kept internal. None is novel; all three are the ones that erode through individually reasonable exceptions.

Docker's packet-filter behaviour is the specific technical hazard in this architecture. It produces exposures that survive configuration review because the configuration is correct — only testing finds them.

Egress control is genuinely dual-purpose: it limits a compromised component and it breaks builds when applied without enumeration. The vulnerability database case degrades into false assurance rather than failure, which makes it the one to handle first.

## Operational Considerations

Rule accumulation is the slow failure. Rules are added under time pressure and removed almost never, because removing one risks breaking something nobody can identify. Periodic review is the only counter, and it needs an owner and a schedule to happen at all.

Connectivity verification by testing should be automated and scheduled. Firewall drift is silent, and the moment it is discovered is usually an incident.

---

## Related

- [Network architecture](network-architecture.md)
- [Firewall and port matrix](firewall-and-port-matrix.md)
- [Security baseline](../07-security/security-baseline.md)
- [Infrastructure standard](../02-infrastructure/infrastructure-standard.md)
- [Docker Compose standard](../06-container/docker-compose-standard.md)
