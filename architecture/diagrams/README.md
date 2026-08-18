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
| [platform-overview.md](platform-overview.md) | End-to-end toolchain from developer to production, including control paths | Draft |
| [environment-promotion.md](environment-promotion.md) | Artifact promotion across DEV, UAT, PROD with stop points and rollback paths | Draft |
| `ci-pipeline` | CI stages and gate behaviour | Planned with [docs/05-ci-cd/](../../docs/05-ci-cd/) |
| `cd-pipeline` | Deployment, approval, verification, and rollback flow | Planned with [docs/05-ci-cd/](../../docs/05-ci-cd/) |
| `network-flows` | Required traffic between components | Planned with [docs/03-network/](../../docs/03-network/) |
| `observability-flow` | Metric and log collection paths | Planned with [docs/08-observability/](../../docs/08-observability/) |

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
