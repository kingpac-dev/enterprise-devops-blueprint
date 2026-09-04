# Documentation Index

## Purpose

Entry point for all Enterprise DevOps Blueprint standards and reference documentation.

## Scope

This index lists documentation areas and their intent. It contains no standards itself. Each area holds its own index and documents.

## Status

**Published.** Complete documentation baseline covering 13 operational, governance, and architectural areas.

---

## Areas

| Area | Directory | Intent |
| --- | --- | --- |
| Executive | [00-executive/](00-executive/) | Business value, roadmap, KPIs, risk register |
| Architecture | [01-architecture/](01-architecture/) | Enterprise, logical, environment, and service-interaction architecture |
| Infrastructure | [02-infrastructure/](02-infrastructure/) | Server standards, sizing, platform installation, HA roadmap |
| Network | [03-network/](03-network/) | Network architecture, port matrix, network security baseline |
| Source control | [04-source-control/](04-source-control/) | Git standard, branching, pull requests, release and tagging |
| CI/CD | [05-ci-cd/](05-ci-cd/) | CI standard, CD standard, Jenkins architecture, promotion, rollback |
| Container | [06-container/](06-container/) | Docker, Dockerfile, Compose, Harbor, versioning, retention |
| Security | [07-security/](07-security/) | Security baseline, secrets, vulnerabilities, supply chain, SBOM, signing, access |
| Observability | [08-observability/](08-observability/) | Observability, monitoring, logging, alerting, dashboards |
| Operations | [09-operations/](09-operations/) | Deployment, rollback, incident, troubleshooting, certificate runbooks |
| Governance | [10-governance/](10-governance/) | DevOps governance, change management, production access, exceptions, audit evidence |
| Disaster recovery | [11-disaster-recovery/](11-disaster-recovery/) | Backup standard, DR plan, restore testing |
| Onboarding | [12-onboarding/](12-onboarding/) | Developer, project, and DevOps team onboarding |

---

## Reading Order for New Adopters

1. [01-architecture/](01-architecture/) — how the platform fits together
2. [04-source-control/](04-source-control/) — branching and pull-request rules
3. [05-ci-cd/](05-ci-cd/) — what the pipeline must do
4. [06-container/](06-container/) — how images are built, tagged, and stored
5. [07-security/](07-security/) — non-negotiable security controls
6. [08-observability/](08-observability/) — what must be observable
7. [09-operations/](09-operations/) — what to do when something breaks
8. [12-onboarding/](12-onboarding/) — how to onboard a new project

---

## Related

- [Repository overview](../README.md)
- [Engineering and AI-governance policy](../AGENTS.md)
- [Architecture Decision Records](../adr/)
- [Templates](../templates/)
- [Runbooks](../runbooks/)
