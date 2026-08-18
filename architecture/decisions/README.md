# Decision Support

## Purpose

Holds the analysis behind an architecture decision when that analysis is too long to sit inside the ADR itself.

## Scope

Option comparisons, evaluation matrices, benchmark notes, cost or capacity analysis, and proof-of-concept findings.

## Status

**Skeleton.** No material published yet.

---

## Important: This Is Not Where ADRs Live

Canonical Architecture Decision Records live in [adr/](../../adr/) and are numbered sequentially. This directory holds only supporting analysis, referenced from an ADR.

The repository structure defined in [AGENTS.md](../../AGENTS.md) contains both `architecture/decisions/` and `adr/`. To avoid two competing locations for decision content, the split is defined as:

| Location | Role |
| --- | --- |
| [adr/](../../adr/) | Canonical, numbered decision records — the authoritative source |
| `architecture/decisions/` | Long-form analysis supporting an ADR, when it does not fit inside it |

An ADR must be readable on its own. Move material here only when it would otherwise bury the decision — for example a multi-page tool comparison or a capacity model. Never record the decision itself here.

---

## Naming Convention

```text
adr-0002-harbor-registry-comparison.md
adr-0005-runtime-platform-options.md
```

Prefix with the ADR number the analysis supports, so the link between record and analysis is obvious.

---

## Related

- [Architecture Decision Records](../../adr/)
- [Architecture assets](../README.md)
- [Contribution process](../../CONTRIBUTING.md)
