# Examples

## Purpose

Minimal reference implementations that demonstrate how the blueprint's templates and standards fit together in a working project.

## Scope

One small example per supported application type. Educational only.

## Status

**Draft for review.** All three are written. **The .NET examples compile and their tests pass; the Angular example type-checks and its tests pass.** No image has been built — no Docker daemon was available in the authoring environment.

---

## Contents

| Directory | Demonstrates | Validated |
| --- | --- | --- |
| [dotnet-worker/](dotnet-worker/) | Liveness that reflects **work**; graceful shutdown between items; fail-fast configuration | `dotnet build` + **9 tests pass** |
| [dotnet-api/](dotnet-api/) | Liveness and readiness **separated**; health responses that expose nothing | `dotnet build` + **9 tests pass** |
| [angular/](angular/) | Runtime configuration, so one image is promoted to all environments | `tsc --strict` + **7 tests pass** |

## Each Solves One Problem

These are not tutorials for Angular or .NET. Each contains the files that address the one thing teams get wrong when adopting this blueprint, and nothing else.

| Example | The problem |
| --- | --- |
| Worker | A worker that starts, fails to connect to its queue, and retries silently is a **running process**. Process liveness reports success while nothing is processed |
| API | If liveness checks the database, a slow database restarts **every** container repeatedly — amplifying the outage with the mechanism meant to prevent it |
| Angular | A compile-time-configured build produces **a different artifact per environment**, so the bundle in production is not the bundle UAT verified |

## The Tests Target Failure Paths

Deliberately. Each test represents a configuration or behaviour that would otherwise start successfully and misbehave later:

- Liveness **not** recorded when a cycle fails
- An item finished despite a shutdown request
- `ShutdownTimeout` shorter than one item's processing time — rejected at startup
- Liveness healthy while a dependency is down
- **No connection string in a health response**, from an exception that contains one
- **No configuration values in a startup error message**
- Runtime configuration failing rather than falling back to a default

---

## Rules

- **Examples are examples.** Every example must state clearly that it is educational and not production-ready as-is.
- Keep them minimal. An example that grows into a real application stops being readable and stops being maintained.
- No real credentials, hostnames, or IP addresses.
- Do not build unrelated sample applications. Each example exists to demonstrate the blueprint, not to showcase framework features.
- Keep examples consistent with the current templates. An out-of-date example is worse than no example, because teams copy it.

---

## Difference From `templates/`

| Directory | Purpose |
| --- | --- |
| [templates/](../templates/) | Artifacts intended to be **copied** into a real project |
| `examples/` | Working illustrations intended to be **read and understood** |

---

## Related

- [Templates](../templates/)
- [Documentation index](../docs/README.md)
- [Onboarding](../docs/12-onboarding/)
