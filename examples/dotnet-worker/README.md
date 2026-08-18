# Example — .NET Worker Service

> **This is an educational example.** It is not production-ready as-is and makes no security or performance guarantees.

## Purpose

Demonstrates how a .NET Worker Service — a background processor with no HTTP surface — adopts the blueprint.

## Status

**Draft for review. Compiles and its tests pass** — see Validation below.

---

## What It Demonstrates

| Aspect | Where |
| --- | --- |
| Fail-fast configuration validation | [WorkerOptions.cs](src/Orders.Worker/WorkerOptions.cs) |
| Liveness that reflects **work**, not process existence | [LivenessSignal.cs](src/Orders.Worker/LivenessSignal.cs) |
| Graceful shutdown between items, never mid-item | [QueueProcessor.cs](src/Orders.Worker/QueueProcessor.cs) |
| Deliberate shutdown timeout, tied to the container stop period | [Program.cs](src/Orders.Worker/Program.cs) |
| Structured logging with stable `event` names | Throughout |
| Runtime image without the ASP.NET stack; non-root; file-based health check | [Dockerfile](Dockerfile) |

## The Two Ideas Worth Taking

### Liveness is recorded only after a **successful** cycle

```csharp
await ProcessOneCycleAsync(stoppingToken);
_liveness.RecordSuccess();   // AFTER, not before
```

Recording it at the top of the loop would report liveness for a worker that is looping and failing — which is the exact failure this signal exists to detect.

A worker that starts, fails to connect to its queue, and retries silently is a **running process**. Process liveness reports success; the container is healthy; nothing is being done. Only a signal tied to completed work distinguishes the two.

The container health check reads the file's **age**, so a stalled worker fails it. See [Dockerfile](Dockerfile).

### Shutdown is checked between items, not within one

```csharp
foreach (var item in items)
{
    if (stoppingToken.IsCancellationRequested) return;   // between items
    await _source.ProcessAsync(item, CancellationToken.None);   // not cancelled
}
```

An item that has started is finished. Abandoning it mid-way can leave a partial write or an unacknowledged message — the difference between a clean deployment and a data-integrity incident.

This is why `ShutdownTimeout` must exceed `MaxItemDuration`, and why [WorkerOptions.Validate()](src/Orders.Worker/WorkerOptions.cs) refuses to start a configuration where it does not. The chain must hold end to end:

```text
MaxItemDuration  <  Worker ShutdownTimeout  <  container stop_grace_period
```

Break it anywhere and a deployment terminates work in progress.

## Build and Test

```bash
dotnet build src/Orders.Worker/Orders.Worker.csproj
dotnet test  tests/Orders.Worker.Tests/Orders.Worker.Tests.csproj
```

## Validation Performed

| Check | Result |
| --- | --- |
| `dotnet build` — application | **Succeeded**, 0 warnings (warnings are errors) |
| `dotnet build` — tests | **Succeeded**, 0 warnings |
| `dotnet test` | **9 passed, 0 failed** |
| `docker build` | **Not run — no Docker daemon available in the authoring environment** |

The tests cover the failure paths deliberately: liveness **not** recorded when a cycle fails, an item finished despite shutdown, and each configuration validation rule. Those are the behaviours that would otherwise fail silently in production.

## What It Is Not

The queue is a stub. This example demonstrates the delivery pattern, not a message broker integration — and it is not production-ready as-is.

---

## Graceful Shutdown

When the container is stopped, the runtime sends a termination signal. The worker must:

1. stop accepting new work
2. finish or safely abandon in-flight work
3. release resources and connections
4. exit within the shutdown timeout

A worker killed mid-transaction can leave partial writes or unacknowledged messages. This is the difference between a clean deployment and a data-integrity incident, which is why the container standard requires correct signal handling.

---

## Monitoring a Worker

A worker has no request rate. Useful signals instead include:

- items processed per interval
- processing failures
- queue depth or backlog age
- time since last successful processing cycle
- restart count

An HTTP health check is often not appropriate here. The container standard requires health checks only where technically appropriate — do not add one for symmetry with the API example.

---

## Open Items

- `TBD` — the organization's .NET version. This example targets `net8.0` to match the templates
- `TBD` — the actual shutdown timeout per service. The **relationship** is settled: `MaxItemDuration < ShutdownTimeout < stop_grace_period`, and [WorkerOptions.Validate()](src/Orders.Worker/WorkerOptions.cs) enforces the first inequality at startup
- `TBD` — whether metrics are exposed by a listener or pushed. The liveness **health** signal is settled as file-based; scraping metrics from a worker still requires either a metrics-only listener or a push gateway — see [monitoring-standard.md](../../docs/08-observability/monitoring-standard.md)

---

## Related

- [Examples index](../README.md)
- [Docker templates](../../templates/docker/)
- [Observability standards](../../docs/08-observability/)
- [Container standards](../../docs/06-container/)
