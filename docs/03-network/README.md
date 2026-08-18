# 03 — Network

## Purpose

Defines network architecture, required traffic flows, and the network security baseline for the delivery platform.

## Scope

Segmentation, allowed flows, ports, exposure rules, and TLS expectations. Host configuration belongs in [02-infrastructure/](../02-infrastructure/).

## Audience

Network engineers, platform engineers, and security engineers.

## Status

**Draft for review.** All three documents are written. One flow — the deployment path to runtime hosts — cannot be specified until [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) is decided, and is written as a per-option table.

---

## Documents

| File | Intent | Status |
| --- | --- | --- |
| [network-architecture.md](network-architecture.md) | Zones, placement, required outbound access, environment isolation, TLS | Draft |
| [firewall-and-port-matrix.md](firewall-and-port-matrix.md) | Every flow, traced to its interaction identifier; explicit denials; verification | Draft |
| [network-security-baseline.md](network-security-baseline.md) | Controls and the failure modes each prevents | Draft |

## The Property This Design Is Built Around

**Exactly one interaction is inbound to the platform from outside it: the GitHub webhook.**

Everything else is initiated from within the controlled network. That asymmetry is the whole external attack surface — one authenticated endpoint — and it is preserved only if new inbound rules are resisted.

`TBD` — whether even that rule is needed. Jenkins can poll GitHub instead, removing the platform's only inbound path at the cost of latency between push and build.

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **Docker manipulates the packet filter directly, and its rules are commonly evaluated before the host firewall's.** A published port can be reachable on a host whose firewall configuration says otherwise — so connectivity must be verified by **testing**, not by reading configuration | [network-security-baseline.md](network-security-baseline.md#4-docker-bypasses-the-host-firewall) |
| **A blocked vulnerability-database update fails silently.** The scan still runs and returns a clean report against stale data. Every other blocked egress produces a visible failure; this one produces false assurance | [network-architecture.md](network-architecture.md#4-required-outbound-access) |
| **Egress must be enumerated before it is restricted.** A blanket outbound block stops builds in ways that present as tooling failures — GitHub, package feeds, base images, and the vulnerability database are all required | [firewall-and-port-matrix.md](firewall-and-port-matrix.md#4-outbound-to-external) |
| **Environment isolation is half of the secret boundary.** Distinct credentials stop authentication; network isolation stops reachability. Either alone fails to a single mistake in the other | [network-security-baseline.md](network-security-baseline.md#7-environment-isolation-is-half-of-the-secret-boundary) |
| Docker's default bridge range can **collide with a corporate internal range**, and the resulting failure looks like a firewall problem. Settle addressing and `default-address-pools` together, before any network exists | [network-architecture.md](network-architecture.md#10-open-items) |

## The One Rule That Cannot Be Written Yet

Interaction I-06 — how the pipeline reaches runtime hosts. **Direction is what a firewall rule is**, and each option in [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) points it differently:

| Option | Inbound to runtime hosts |
| --- | --- |
| A — Jenkins agent on host | **None** |
| B — SSH over internal network | SSH, from the toolchain zone only |
| C — Pull-based agent | **None** |
| D — Portainer API | Portainer API |

Options A and C preserve the no-inbound property that the `AGENTS.md` constraint was written to protect. Option B satisfies the constraint literally — internal rather than public exposure — and whether that satisfies its **intent** is a question for the security owner to answer and record.

---

## Flows to Document

```text
Developer          -> GitHub
GitHub             -> Jenkins webhook
Jenkins            -> GitHub
Jenkins            -> SonarQube
Jenkins            -> Harbor
Jenkins            -> deployment targets
Runtime            -> Harbor
Runtime            -> monitoring
Monitoring         -> runtime
```

---

## Constraints

- Apply least privilege, network segmentation, firewall allow-listing, and TLS for sensitive traffic.
- Restrict inbound access; control outbound access.
- No unnecessary public exposure.
- Production administrative interfaces must not be publicly exposed without explicit justification and compensating controls.
- Production must not depend on publicly exposed SSH solely for CI/CD.

## Documentation Caution

Do not commit real IP addresses, internal DNS names, or production firewall rules to this repository. Use `TBD` or clearly fictional example values, and keep the authoritative rule set in the controlled network configuration system.

---

## Related

- [Documentation index](../README.md)
- [Infrastructure](../02-infrastructure/)
- [Security](../07-security/)
- [Repository security policy](../../SECURITY.md)
