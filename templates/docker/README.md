# Docker Templates

## Purpose

Reusable `Dockerfile` and `.dockerignore` templates implementing the container standard.

## Scope

Image build definitions per application type. The rules they implement are defined in [docs/06-container/](../../docs/06-container/).

## Status

**Draft for review.** Templates are written. Base image versions are placeholders requiring confirmation, and the images have **not been built** — see Validation below.

---

## Templates

| File | Target | Status |
| --- | --- | --- |
| [Dockerfile.angular](Dockerfile.angular) | Angular build served by unprivileged nginx | Draft |
| [nginx.angular.conf](nginx.angular.conf) | SPA routing, cache policy, health endpoint, security headers | Draft |
| [runtime-config.angular.sh](runtime-config.angular.sh) | Writes `assets/config.json` at container start | Draft |
| [Dockerfile.dotnet-api](Dockerfile.dotnet-api) | .NET Web API with a liveness health check | Draft |
| [Dockerfile.dotnet-worker](Dockerfile.dotnet-worker) | .NET Worker Service, no HTTP surface, file-based liveness | Draft |
| [.dockerignore.angular](.dockerignore.angular) | Excludes `node_modules`, build output, `.env`, `.git` | Draft |
| [.dockerignore.dotnet](.dockerignore.dotnet) | Excludes `bin`, `obj`, test output, `.env`, `.git` | Draft |

## The Angular Runtime Configuration Mechanism

These templates resolve a `TBD` that several standards deferred: how an Angular application satisfies build-once promotion.

A naive Angular build substitutes environment values at **compile** time, producing a different artifact per environment — which breaks the model the whole delivery design rests on.

The mechanism here: [runtime-config.angular.sh](runtime-config.angular.sh) runs from nginx's `/docker-entrypoint.d/` before nginx starts, writes `assets/config.json` from environment variables, and the application fetches it during bootstrap. The same image is then promoted unchanged to DEV, UAT, and PROD.

Two details make it work, and both fail silently if omitted:

- The script is `chmod +x` in the Dockerfile. nginx's entrypoint runs only executable files in that directory and skips the rest with a log line that is easy to miss. A build context created on Windows carries no executable bit, so without the explicit `chmod` the configuration is never written.
- `assets/config.json` is served with `no-store`. Cached, a promoted container serves the previous environment's configuration.

## Deliberate Exception: `curl` in the .NET API Image

The .NET runtime image contains no HTTP client, and a container health check needs one inside the container. [Dockerfile.dotnet-api](Dockerfile.dotnet-api) installs `curl`, which is a documented exception to "no unnecessary tools in the runtime stage".

The alternatives are a purpose-built health-check binary, or no container health check and external probing — which Docker Compose does not provide. If the platform gains external probing, remove both the package and the `HEALTHCHECK`.

## Validation Performed

| Check | Result |
| --- | --- |
| Shell script syntax (`sh -n`) | Pass |
| Script behaviour: missing required value | Fails with the documented message |
| Script behaviour: generated `config.json` | Valid JSON, correct values |
| Anti-pattern scan: floating base tag, shell-form `ENTRYPOINT`, secret in `ARG`, SDK in runtime stage, missing `USER` | Pass on all three Dockerfiles |
| **`docker build`** | **Not run — no Docker daemon available in this environment** |
| **`nginx -t` on the configuration** | **Not run — nginx not available** |

The last two matter. These Dockerfiles have not been built, and the nginx configuration has not been parsed by nginx. Build them once before adopting them.

---

## Requirements

---

## Requirements

- multi-stage builds where appropriate
- minimal runtime images
- non-root execution where practical
- `.dockerignore` present and effective
- no embedded secrets, build arguments carrying secrets, or credential files
- controlled and pinned base-image strategy
- explicit runtime ports where useful
- correct signal handling, so the container stops cleanly
- health checks only where technically appropriate

A health check on a worker with no HTTP surface is not appropriate. Do not add one for symmetry.

---

## Base Image Policy

Base images must come from an approved, controlled source and be pinned to a specific version or digest. Floating tags make builds non-reproducible and silently pull in changes.

`TBD` — approved base image list, source registry, and update cadence.

---

## Related

- [Templates index](../README.md)
- [Container standards](../../docs/06-container/)
- [Compose templates](../compose/)
- [Jenkins templates](../jenkins/)
