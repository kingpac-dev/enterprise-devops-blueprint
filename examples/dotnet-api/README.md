# Example — .NET Web API

> **This is an educational example.** It is not production-ready as-is and makes no security or performance guarantees.

## Purpose

Demonstrates how a .NET Web API adopts the blueprint.

## Status

**Draft for review. Compiles and its tests pass** — see Validation below.

---

## What It Demonstrates

| Aspect | Where |
| --- | --- |
| Liveness and readiness kept **separate**, with different consequences | [HealthChecks.cs](src/Orders.Api/HealthChecks.cs) |
| Health responses that expose **nothing** | [HealthChecks.cs](src/Orders.Api/HealthChecks.cs), [Program.cs](src/Orders.Api/Program.cs) |
| Fail-fast configuration, naming settings and never values | [ApiOptions.cs](src/Orders.Api/ApiOptions.cs) |
| Safe defaults; required values with **no** default | [appsettings.json](src/Orders.Api/appsettings.json) |
| Non-root, port above 1024, **liveness** health check | [Dockerfile](Dockerfile) |

## The Two Ideas Worth Taking

### Liveness must not check dependencies

```csharp
public const string Live  = "live";   // this process only. NO dependency checks
public const string Ready = "ready";  // may check dependencies
```

If liveness queries the database, a slow database fails **every instance's** liveness probe — so every container restarts, repeatedly, adding connection churn to a dependency already under strain, and resolving nothing. **The outage is amplified by the mechanism meant to protect against it.**

Liveness answers a question about *this process*. If it is running and not deadlocked, it is live — even when everything it depends on is broken.

The two are consumed by different things:

| Signal | Consumer | On failure |
| --- | --- | --- |
| `/health/live` | The **container** health check | Restart |
| `/health/ready` | The **deployment**, and traffic routing | Stop routing; do **not** restart |

### Health responses say nothing

Both endpoints return `ok` or `unhealthy`. No component list, no versions, no dependency names, no exception text.

The `DependencyHealthCheck` catches the exception and **discards it deliberately** — exception messages routinely carry connection strings and internal hostnames, and a health endpoint is frequently the least protected route in a service.

There is a test for exactly that, using an exception containing a connection string, asserting none of it reaches the response.

## Build and Test

```bash
dotnet build src/Orders.Api/Orders.Api.csproj
dotnet test  tests/Orders.Api.Tests/Orders.Api.Tests.csproj
```

## Validation Performed

| Check | Result |
| --- | --- |
| `dotnet build` | **Succeeded**, 0 warnings (warnings are errors) |
| `dotnet test` | **9 passed, 0 failed** |
| `docker build` | **Not run — no Docker daemon available in the authoring environment** |
| Application started and endpoints called | **Not run** |

The tests target the failure paths: liveness healthy while a dependency is down, readiness unhealthy when it throws, no dependency detail in the response, and no configuration **values** in the startup error message.

## What It Is Not

The dependency probe is a stub returning `true`. This example demonstrates the health and configuration patterns, not data access — and it is not production-ready as-is.

---

## Health Endpoint Design

The example keeps three concerns separate:

| Endpoint | Answers | Failure means |
| --- | --- | --- |
| Liveness | Is the process healthy enough to keep running? | Restart the container |
| Readiness | Can it accept traffic right now? | Stop routing traffic, do not restart |
| Dependency health | Are downstream dependencies reachable? | Diagnostic signal, used carefully |

Conflating liveness with dependency health causes restart storms when a downstream dependency is slow — the container restarts, fixing nothing.

Health responses must not expose connection strings, internal hostnames, versions of internal components, or stack traces.

---

## Open Items

- `TBD` — the organization's .NET version. This example targets `net8.0` to match the templates
- `TBD` — coverage tooling and report format for the pipeline
- **Settled here:** readiness *does* include a dependency check; liveness does **not**. The probe itself is a stub — a real one performs a cheap connectivity check, not a full query, because an endpoint polled every few seconds becomes load on the dependency it checks

---

## Related

- [Examples index](../README.md)
- [Docker templates](../../templates/docker/)
- [Jenkins templates](../../templates/jenkins/)
- [Observability standards](../../docs/08-observability/)
