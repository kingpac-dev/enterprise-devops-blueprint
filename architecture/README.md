# Architecture Assets

## Purpose

Holds architecture **artifacts** — diagram sources and decision-support material — that support the narrative documentation in [docs/01-architecture/](../docs/01-architecture/).

## Scope

| Subdirectory | Contents |
| --- | --- |
| [diagrams/](diagrams/) | Diagram sources, primarily Mermaid, referenced by documentation |
| [decisions/](decisions/) | Decision-support material: option analyses, evaluation matrices, comparison notes |

## Status

**Skeleton.** No assets published yet.

---

## Relationship to Other Directories

| Directory | Holds |
| --- | --- |
| [docs/01-architecture/](../docs/01-architecture/) | The architecture **narrative** — what the design is and why |
| `architecture/diagrams/` | The diagram **sources** that documentation embeds or links |
| `architecture/decisions/` | The **analysis** behind a decision |
| [adr/](../adr/) | The **decision record itself** — canonical, numbered, immutable once accepted |

Accepted decisions are recorded as ADRs in [adr/](../adr/). This directory does not duplicate them. See [decisions/README.md](decisions/README.md) for the boundary between an ADR and its supporting analysis.

---

## Related

- [Documentation index](../docs/README.md)
- [Architecture documentation](../docs/01-architecture/)
- [Architecture Decision Records](../adr/)
