# Example — Angular Application

> **This is an educational example.** It is not production-ready as-is and makes no security or performance guarantees.

## Purpose

Demonstrates how an Angular frontend application adopts the blueprint.

## Status

**Draft for review. Type-checks under `strict` and its tests pass** — see Validation below.

---

## Scope: The Runtime Configuration Problem Only

This is **not a full Angular application**. It contains the files that solve the one problem the blueprint has with frontends, and nothing else.

The Angular-specific wiring — `bootstrapApplication`, providers, injection tokens, components — is deliberately absent. It is well documented elsewhere and it is not what teams get wrong here.

| File | Purpose |
| --- | --- |
| [runtime-config.ts](src/app/runtime-config.ts) | Fetch and **validate** configuration at run time |
| [main.ts](src/main.ts) | Fetch before bootstrap; fail visibly if it cannot |
| [runtime-config.spec.ts](src/app/runtime-config.spec.ts) | Tests, covering the failure paths |

The container side is in [templates/docker/](../../templates/docker/): the entrypoint script that writes `config.json`, and the nginx configuration that serves it uncached.

## The Problem

A naive Angular build substitutes environment values at **compile** time, through `environment.ts` and a file replacement in `angular.json`.

That produces **a different artifact per environment** — so the bundle deployed to production is not the bundle UAT verified, and build-once promotion, which the entire delivery model rests on, is impossible.

## The Resolution

```text
Container starts
  -> /docker-entrypoint.d/10-runtime-config.sh writes assets/config.json
     from environment variables
  -> Application fetches config.json BEFORE bootstrapping
  -> One image, promoted unchanged to DEV, UAT, and PROD
```

Three details make it work, and each fails silently if omitted:

| Detail | If omitted |
| --- | --- |
| The entrypoint script is `chmod +x` in the Dockerfile | nginx skips non-executable files in `/docker-entrypoint.d` with a log line that is easy to miss. **The config is never written.** A build context created on Windows carries no executable bit |
| `config.json` served with `no-store`, **and** fetched with `cache: 'no-store'` | A promoted container serves the previous environment's configuration from cache. Both are needed, because either alone can be bypassed |
| Loading **fails** rather than falling back to a default | A default pointing at a real environment starts successfully and is discovered later, as incorrect behaviour |

## Required Versus Optional Configuration

The distinction is deliberate, and it is the one judgement call in the loader:

| Field | Missing or invalid | Why |
| --- | --- | --- |
| `apiBaseUrl` | **Fails startup** | A wrong value points the application at another environment |
| `environment` | **Fails startup** | Same |
| `logLevel` | Falls back to `warn` | A wrong log level is a nuisance |
| `featureFlags` | Fails if malformed | A non-boolean flag is a bug, not a preference |

## Build and Test

```bash
npm install
npm run typecheck
```

## Validation Performed

| Check | Result |
| --- | --- |
| `tsc --noEmit` under `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` | **Passed** |
| Spec executed | **7 passed, 0 failed** |
| `docker build` | **Not run — no Docker daemon available in the authoring environment** |
| Full Angular build (`ng build`) | **Not run** — this is not a full Angular project |

The tests cover the failure paths: missing `apiBaseUrl`, unknown `environment`, non-object payload, non-boolean feature flag, safe fallback for `logLevel`, and **no configuration values in the error message** — that message can reach a browser console and an error report.

## What It Is Not

Not a full application, not production-ready, and not a substitute for reading the Angular documentation on application bootstrap.

---

## Open Items

- `TBD` — the organization's Node and Angular versions
- **Settled here:** the serving image is `nginxinc/nginx-unprivileged`, which runs as uid 101 and listens on 8080 by default — satisfying non-root and above-1024 without further work. See [templates/docker/Dockerfile.angular](../../templates/docker/Dockerfile.angular)
- **Settled here:** the runtime configuration mechanism is `assets/config.json`, written by the container entrypoint and fetched before bootstrap

---

## Related

- [Examples index](../README.md)
- [Docker templates](../../templates/docker/)
- [Jenkins templates](../../templates/jenkins/)
- [Container standards](../../docs/06-container/)
