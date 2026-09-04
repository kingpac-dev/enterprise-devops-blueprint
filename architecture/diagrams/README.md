# Diagrams

## Purpose

Diagram sources referenced by the architecture and standards documentation.

## Scope

Platform, environment, network, pipeline, and deployment diagrams.

## Status

**Two diagrams published as drafts.** The remainder are planned alongside their owning documentation area.

---

## Diagram Index

| Diagram | Shows | Status |
| --- | --- | --- |
| [platform-overview.md](platform-overview.md) | End-to-end toolchain from developer to production, including control paths | **Published** |
| [environment-promotion.md](environment-promotion.md) | Artifact promotion across DEV, UAT, PROD with stop points and rollback paths | **Published** |
| [ci-pipeline.md](ci-pipeline.md) | Standard CI stages, fail-fast gates, and Harbor image publishing | **Published** |
| [cd-pipeline.md](cd-pipeline.md) | Deployment, approval, verification, and automated rollback flow | **Published** |
| [network-flows.md](network-flows.md) | Required network traffic, firewall zones, and protocol ports | **Published** |
| [observability-flow.md](observability-flow.md) | Metric scraping, log streaming, dashboards, and alerting telemetry paths | **Published** |

Diagrams specific to one document are kept inline in that document rather than here. The architecture documents in [docs/01-architecture/](../../docs/01-architecture/) contain several such diagrams.

---

## Conventions

- Use Mermaid where practical, so diagrams are diffable and reviewable in pull requests.
- Keep the diagram source in the document that uses it when it is small and used once.
- Place a diagram here when it is shared by more than one document, or is too large to read inline.
- Do not include real hostnames, IP addresses, or credentials in any diagram.
- Validate Mermaid syntax before merge, and state in the pull request whether validation was actually run.

Exported images may accompany a source file, but the source is authoritative.

---

## Related

- [Architecture assets](../README.md)
- [Architecture documentation](../../docs/01-architecture/)
