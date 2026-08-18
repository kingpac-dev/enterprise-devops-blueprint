# Dockerfile Standard

## Purpose

Defines how container images are built: structure, base image policy, caching, metadata, and the per-application-type requirements for Angular, .NET Web API, and .NET Worker Service.

## Scope

Build-time requirements. Runtime behaviour is in [docker-standard.md](docker-standard.md); deployment configuration is in [docker-compose-standard.md](docker-compose-standard.md).

## Audience

Developers writing Dockerfiles, and reviewers of them.

## Status

**Draft for review.** Base image selections and versions are undecided.

---

## 1. Multi-Stage Builds

Images must separate build from runtime using multi-stage builds where the application requires a build step.

The runtime stage contains the application and its runtime dependencies. It must not contain compilers, SDKs, package managers, source code, or test artifacts.

This is a security requirement as much as a size one. A runtime image containing a package manager and a compiler gives an attacker who achieves code execution the tools to build and install whatever they need next.

```dockerfile
# Build stage — full SDK, source, dependencies
FROM <sdk-image> AS build
WORKDIR /src
# ... restore, build, publish

# Runtime stage — minimal, no build tooling
FROM <runtime-image> AS final
WORKDIR /app
COPY --from=build /app/publish .
```

---

## 2. Base Image Policy

| Requirement | Detail |
| --- | --- |
| Source | Approved registry only |
| Pinning | Pinned to a specific version; digest pinning preferred for production |
| Currency | Updated on a defined cadence, and on disclosure of a relevant vulnerability |
| Scope | Minimal — no distribution image where a runtime-specific image exists |

### Why pinning matters

A floating tag makes builds non-reproducible. Two builds of the same commit, a week apart, can produce different images with different vulnerabilities. The traceability chain in [enterprise-devops-architecture.md](../01-architecture/enterprise-devops-architecture.md#5-the-traceability-chain) assumes an image identifier resolves to known content — a floating base tag breaks that assumption at the base layer.

```dockerfile
# Non-reproducible: content changes without notice
FROM mcr.microsoft.com/dotnet/aspnet:latest

# Version-pinned: acceptable
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Digest-pinned: reproducible, and what production should use
FROM mcr.microsoft.com/dotnet/aspnet:8.0@sha256:<digest>
```

Digest pinning has a cost: security patches require an explicit update. That is a feature — it makes base image updates a visible, reviewable change rather than something that happens silently between builds. It requires an update process to exist.

`TBD` — approved base image list, source registry, pinning level per environment, and update cadence.

---

## 3. Layer Ordering and Caching

Order instructions from least to most frequently changing. Dependency restore must happen before source is copied, otherwise every source change invalidates the dependency cache.

```dockerfile
# Correct: dependency manifests first, then restore, then source
COPY ["MyApi/MyApi.csproj", "MyApi/"]
RUN dotnet restore "MyApi/MyApi.csproj"
COPY . .
RUN dotnet publish -c Release -o /app/publish
```

```dockerfile
# Wrong: any source change re-runs restore
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish
```

This is a build-time cost, not a correctness issue — but it compounds. A pipeline that rebuilds dependencies on every commit is slower on every commit, and slow pipelines change behaviour: people batch changes, and batched changes are harder to diagnose when they fail.

---

## 4. `.dockerignore`

Every application repository must contain a `.dockerignore`.

Without one, the entire build context is sent to the daemon — including `.git`, `node_modules`, build output, local configuration, and any `.env` file present in the working directory. Anything that reaches the build context can end up in the image.

Minimum exclusions:

```text
.git
.gitignore
.env
.env.*
**/node_modules
**/bin
**/obj
**/dist
**/coverage
**/TestResults
**/*.user
Dockerfile*
docker-compose*.yml
README.md
```

`.env` exclusion is the important line. A developer with a local `.env` and no `.dockerignore` will build production credentials into the image without any signal that it happened.

---

## 5. Non-Root Execution

The runtime stage must create and switch to a non-root user where the application permits it.

```dockerfile
RUN addgroup --system --gid 1001 appgroup \
 && adduser --system --uid 1001 --ingroup appgroup appuser
USER appuser
```

Consequences to design for:

- The application cannot bind to ports below 1024. Use a port above 1024 inside the container and map it externally.
- Any path the application writes to must be writable by that user, and its ownership must be set during the build.

Where a non-root user is genuinely not possible, the reason is recorded in the Dockerfile as a comment and in the application's documentation. "It was easier" is not a reason.

---

## 6. Entrypoint

Use exec form. Shell form prevents `SIGTERM` from reaching the application — see [docker-standard.md](docker-standard.md#2-process-and-signal-handling).

```dockerfile
ENTRYPOINT ["dotnet", "MyApi.dll"]
```

Avoid wrapper shell scripts that perform startup work unless they `exec` the application as their final action:

```bash
#!/bin/sh
set -e
# startup work here
exec dotnet MyApi.dll   # exec replaces the shell, so the app becomes PID 1
```

Without `exec`, the shell remains PID 1 and signals stop at it.

---

## 7. Build Arguments and Secrets

**`ARG` values are recorded in image history and are readable by anyone who can pull the image.** They are not a secret mechanism.

```dockerfile
# Never do this — the token is permanently in image history
ARG NUGET_TOKEN
RUN dotnet restore --source https://user:${NUGET_TOKEN}@feed.internal/v3/index.json
```

Where a build genuinely requires a credential — a private package feed, for example — use BuildKit build secrets, which are mounted for the duration of a single instruction and are not persisted into any layer:

```dockerfile
RUN --mount=type=secret,id=nugetconfig,target=/root/.nuget/NuGet/NuGet.Config \
    dotnet restore
```

`TBD` — whether private package feeds are used, and the credential mechanism if so.

---

## 8. Image Metadata

Images must carry OCI standard labels linking them back to their source. This metadata is what allows a running container to be traced without consulting a separate system.

```dockerfile
LABEL org.opencontainers.image.title="my-api" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_TIMESTAMP}" \
      org.opencontainers.image.source="${REPOSITORY_URL}" \
      org.opencontainers.image.vendor="TBD"
```

Values are supplied by the pipeline as build arguments. These are not secrets, so `ARG` is appropriate here.

See [image-versioning.md](image-versioning.md) for how these fields relate to the tag scheme.

---

## 9. Per Application Type

### 9.1 Angular

| Aspect | Requirement |
| --- | --- |
| Build stage | Node image; `npm ci` rather than `npm install`, so the lockfile is authoritative |
| Runtime stage | Minimal web server image serving static output |
| Configuration | Supplied at container start, **not** compiled into the bundle |
| User | Non-root; server configured to listen above port 1024 |
| Caching | `package.json` and lockfile copied and installed before source |

The configuration requirement is the one that determines whether build-once promotion is possible at all. An Angular build that substitutes environment values at compile time produces a different artifact per environment, which breaks the principle the entire delivery model rests on — see [environment-architecture.md](../01-architecture/environment-architecture.md#7-configuration-and-secret-model).

The resolution is that the container writes or serves a configuration file at startup, which the application reads at run time.

`TBD` — the chosen runtime configuration mechanism and the serving image.

### 9.2 .NET Web API

| Aspect | Requirement |
| --- | --- |
| Build stage | .NET SDK image; restore before source copy |
| Runtime stage | ASP.NET runtime image, not the SDK |
| Publish | Release configuration |
| User | Non-root |
| Port | Above 1024 inside the container; configured explicitly, not assumed |
| Health | Liveness and readiness endpoints, kept distinct |
| Culture | Invariant globalization where the application does not need ICU, which reduces image size — verify it does not break formatting first |

`TBD` — .NET version and whether trimming or ahead-of-time compilation is used.

### 9.3 .NET Worker Service

| Aspect | Requirement |
| --- | --- |
| Build stage | .NET SDK image |
| Runtime stage | .NET runtime image, not ASP.NET, unless an HTTP surface is genuinely required |
| User | Non-root |
| Shutdown | Graceful shutdown honouring `SIGTERM`, within the configured host shutdown timeout |
| Health | HTTP health check only if an HTTP surface already exists for another reason |
| Ports | None exposed unless genuinely required |

A worker's shutdown timeout must be configured deliberately. The .NET Generic Host default is short, and a worker processing longer items will be terminated mid-work at that default — see [docker-standard.md](docker-standard.md#2-process-and-signal-handling).

---

## 10. Anti-Patterns

| Anti-pattern | Consequence |
| --- | --- |
| `FROM <image>:latest` | Non-reproducible builds; silent base changes |
| Secrets in `ARG` or `ENV` | Permanently readable in image history |
| `COPY . .` before dependency restore | Cache invalidated on every source change |
| Missing `.dockerignore` | `.git`, `.env`, and build output shipped into the image |
| Shell-form `ENTRYPOINT` | `SIGTERM` never reaches the application |
| SDK image as the runtime stage | Compilers and package managers available to an attacker |
| `RUN` installing debugging tools "temporarily" | Additive layers; the tools remain in the image |
| Running as root | Container escape becomes host compromise |
| Environment values baked in at build time | Build-once promotion becomes impossible |
| `apt-get upgrade` in the Dockerfile | Non-reproducible; patch the base image instead |

---

## 11. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — approved base images, registry source, and update cadence | Every image built |
| `TBD` — pinning level: version tag or digest, per environment | Build reproducibility |
| `TBD` — Angular runtime configuration mechanism and serving image | Build-once for frontends |
| `TBD` — .NET version and publish options | .NET images |
| `TBD` — private package feed usage and credential mechanism | Build secrets |
| `TBD` — whether base image currency is enforced in the pipeline | Vulnerability exposure |

---

## Security Considerations

Three requirements here carry most of the security value: the runtime stage excludes build tooling, `ARG` is never used for secrets, and `.dockerignore` prevents `.env` and `.git` from entering the build context.

The `ARG` case is worth emphasizing because it looks safe. The value does not appear in the final filesystem, so a casual inspection finds nothing — but `docker history` returns it to anyone who can pull the image.

Base image currency is the ongoing obligation. An image pinned to a digest and never updated accumulates known vulnerabilities in its base layers indefinitely, and pinning is what makes that accumulation invisible unless an update process exists.

## Operational Considerations

Layer ordering determines build time, and build time determines how the pipeline is used. Base image pinning determines how base updates happen: deliberately and reviewably, or silently between builds. Choosing digest pinning without an accompanying update process trades a reproducibility problem for a patching one.

---

## Related

- [Docker standard](docker-standard.md)
- [Docker Compose standard](docker-compose-standard.md)
- [Image versioning](image-versioning.md)
- [Docker templates](../../templates/docker/)
- [Security standards](../07-security/)
