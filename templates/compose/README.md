# Docker Compose Templates

## Purpose

Environment-specific Docker Compose templates for deploying application containers to DEV, UAT, and PROD.

## Scope

Runtime composition per environment, plus a placeholder environment file. The rules they implement are defined in [docs/06-container/](../../docs/06-container/).

## Status

**Draft for review.** All four are written and validated against the real Docker Compose parser. Resource limits and ports are placeholders requiring confirmation.

---

## Templates

| File | Target | Status |
| --- | --- | --- |
| [compose.dev.yml](compose.dev.yml) | DEV runtime | Draft |
| [compose.uat.yml](compose.uat.yml) | UAT runtime | Draft |
| [compose.prod.yml](compose.prod.yml) | PROD runtime, strictest settings | Draft |
| [.env.example](.env.example) | Placeholders only | Draft |

Each file defines the same three services — `web`, `api`, `worker` — so the differences between environments are visible by diffing them.

## Separate Files, Not Overrides

Three complete files, rather than a base plus overrides. Overrides are more elegant and less readable: determining what production will actually run requires mentally merging two or three files, and that merge happens under time pressure during an incident.

The cost is duplication that must be kept consistent. That is the smaller risk.

## Required Values Fail the Deployment

Required values use `${VAR:?message}`, so a missing value stops the deployment with a named error rather than starting with a default that might point at the wrong environment.

Verified — removing `JWT_SIGNING_KEY` produces:

```text
error while interpolating services.api.environment.Jwt__SigningKey:
required variable JWT_SIGNING_KEY is missing a value: JWT_SIGNING_KEY is required
```

## Settings That Prevent Host-Wide Outages

Two are omitted by default and both fail at the **host** level rather than the service level:

| Setting | Without it |
| --- | --- |
| `logging` size and rotation limits | The default driver has no size limit. A service logging steadily fills the host disk, stopping every container on the host |
| `deploy.resources.limits` | One leaking container causes the kernel to kill something — not necessarily the container at fault |

Both are a few lines. Both are in the PROD and UAT templates and deliberately absent from DEV.

## Two Details Worth Keeping

**Ports are bound to loopback.** `127.0.0.1:8080:8080`, not `8080:8080`. The default binds to every host interface, and Docker's packet-filter rules commonly take effect before the host firewall's — so a host that appears firewalled can still be serving the port.

**The backend network is `internal: true`.** One line, and the components most worth isolating lose their route out.

## Validation Performed

| Check | Result |
| --- | --- |
| `docker compose -f compose.dev.yml config --quiet` | **VALID** |
| `docker compose -f compose.uat.yml config --quiet` | **VALID** |
| `docker compose -f compose.prod.yml config --quiet` | **VALID** |
| Fail-fast on a missing required value | Confirmed, with the documented error |
| **`docker compose up`** | **Not run — no Docker daemon available, and the referenced images do not exist** |

Syntax and interpolation are verified. Runtime behaviour is not.

---

## Production Requirements

---

## Production Requirements

`compose.prod.yml` must demonstrate:

- an explicit, immutable image version — never `latest`
- restart policy
- health checks
- environment variables sourced from outside the file
- secrets kept separate from the Compose definition
- persistent volumes where required
- explicit networks
- resource considerations
- logging considerations

The same image is promoted across environments. Only configuration differs between these files.

---

## Environment File Rules

`.env.example` contains placeholders only:

```text
APP_IMAGE=harbor.example.internal/team/app:1.4.2
APP_PORT=8080
DB_CONNECTION_STRING=<set-per-environment>
JWT_SIGNING_KEY=<set-via-jenkins-credentials>
```

Never place real passwords, tokens, or connection strings in `.env.example`. Generated `.env` files must not be committed — see [.gitignore](../../.gitignore) and [SECURITY.md](../../SECURITY.md).

---

## Validation

Validate Compose syntax before merge:

```bash
docker compose -f compose.prod.yml config --quiet
```

State in the pull request whether this was actually run.

---

## Related

- [Templates index](../README.md)
- [Container standards](../../docs/06-container/)
- [Docker templates](../docker/)
- [CI/CD standards](../../docs/05-ci-cd/)
