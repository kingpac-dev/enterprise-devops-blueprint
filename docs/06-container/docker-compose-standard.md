# Docker Compose Standard

## Purpose

Defines how Docker Compose files are structured and what a production Compose file must declare.

## Scope

Deployment composition for DEV, UAT, and PROD. Image build requirements are in [dockerfile-standard.md](dockerfile-standard.md); runtime behaviour is in [docker-standard.md](docker-standard.md).

## Audience

Developers and platform engineers who define how an application is deployed.

## Status

**Draft for review.** The mechanism that applies these files to runtime hosts is undecided — see [service-interaction.md](../01-architecture/service-interaction.md#2-interaction-i-06-the-open-question).

---

## 1. File Layout

One file per environment, with values supplied from outside the file.

```text
deployment/
├── dev/
│   ├── compose.yml
│   └── .env            # not in Git
├── uat/
│   ├── compose.yml
│   └── .env            # not in Git
├── prod/
│   ├── compose.yml
│   └── .env            # not in Git
└── .env.example        # placeholders only, in Git
```

Separate files per environment are preferred over a base file plus overrides. Overrides are more elegant and less readable: determining what production will actually run requires mentally merging two or three files, and that merge happens under time pressure during an incident.

The cost is duplication between the three files, which must be kept consistent. That is a smaller risk than a production configuration nobody can read directly.

---

## 2. Required Elements

A production Compose file must declare each of the following. DEV may relax items marked as PROD-only.

| Element | Requirement | PROD only |
| --- | --- | --- |
| `image` | Explicit immutable tag from Harbor. Never `latest`, never a local build | No |
| `restart` | Explicit policy | No |
| `healthcheck` | Where technically appropriate | No |
| `deploy.resources.limits` | CPU and memory limits | Yes |
| `networks` | Explicit; no reliance on the default network | No |
| `volumes` | Named volumes for anything durable | No |
| `logging` | Driver with size and rotation limits | Yes |
| `env_file` | Environment values from a file held outside Git | No |
| `stop_grace_period` | Longer than the application's shutdown timeout | No |

```yaml
services:
  api:
    image: harbor.example.internal/team/my-api:1.4.2
    restart: unless-stopped
    env_file:
      - .env
    networks:
      - frontend
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 30s
    stop_grace_period: 45s
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  frontend:
  backend:
    internal: true
```

The example uses placeholder values. Actual limits and endpoints are `TBD`.

---

## 3. Image Reference

The `image` value is the production release identity. It must be an explicit tag or digest from Harbor.

```yaml
image: harbor.example.internal/team/my-api:1.4.2        # acceptable
image: harbor.example.internal/team/my-api@sha256:...    # strongest
image: harbor.example.internal/team/my-api:latest        # prohibited
build: .                                                 # prohibited in UAT and PROD
```

A `build:` directive in a deployed Compose file means the host builds its own image. That is a different artifact from the one UAT verified, produced by different tooling on a different machine — which discards the entire build-once model. `build:` belongs only in local development.

---

## 4. Environment Values and Secrets

| Value type | Mechanism | In Git |
| --- | --- | --- |
| Non-sensitive configuration | `env_file` pointing at an environment-specific file | No |
| Credentials, tokens, connection strings | `env_file` held outside Git with restricted permissions, or a host-managed secret mechanism | Never |
| Placeholders for documentation | `.env.example` | Yes |

Never inline a secret in the Compose file:

```yaml
# Prohibited
environment:
  - DB_PASSWORD=RealPasswordHere
```

Environment files must be readable only by the account that runs the deployment. `TBD` — file ownership and permission requirements per host.

Two properties of environment variables are worth knowing before relying on them for secrets. They are visible to anyone who can run `docker inspect` on the host, and they are inherited by child processes. Docker Compose supports file-based secrets, which avoid both; whether to adopt them is `TBD` in [07-security/](../07-security/).

`.env.example` contains placeholders only:

```text
APP_IMAGE=harbor.example.internal/team/my-api:1.4.2
APP_PORT=8080
DB_CONNECTION_STRING=<set-per-environment>
JWT_SIGNING_KEY=<set-via-jenkins-credentials>
LOG_LEVEL=Information
```

---

## 5. Networks

Declare networks explicitly. Do not rely on the implicit default network, which places every service on the host in the same flat network — including services from unrelated applications.

Separate frontend from backend, and mark backend networks `internal: true` so they have no route out. A database that cannot reach the internet cannot exfiltrate to it.

Publish only the ports genuinely required:

```yaml
ports:
  - "127.0.0.1:8080:8080"   # bound to loopback, reached through a reverse proxy
```

Binding to `0.0.0.0` — the default when no address is given — exposes the port on every host interface. On a host with a public interface, `"8080:8080"` publishes the service to the internet, and it does so without appearing to. Host firewall rules do not necessarily prevent this: Docker manipulates the packet filter directly and its rules are commonly evaluated before the host's own.

---

## 6. Volumes

Use named volumes for durable state. Bind mounts tie the deployment to a host path, which makes the configuration host-specific and easy to break during host maintenance.

```yaml
volumes:
  app-data:

services:
  api:
    volumes:
      - app-data:/var/lib/app
      - ./config:/app/config:ro    # read-only where the container only reads
```

Every named volume in production is a backup obligation. A volume that is not backed up is data that is lost when the host is lost. Volumes must be listed in the backup scope — see [11-disaster-recovery/](../11-disaster-recovery/).

---

## 7. Logging and Disk

Configure a log driver with size and rotation limits on every production service.

The default `json-file` driver has **no size limit**. A service logging steadily will fill the host disk, and a full disk on a runtime host does not degrade one service — it takes down every container on the host, and frequently the host's own ability to recover.

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

This caps that service at 30 MB. Where logs are shipped to Loki, local files are a buffer rather than the record of truth, so a small cap is appropriate.

Disk usage must be monitored regardless. Rotation limits log growth; it does not limit image, volume, or build-cache growth.

---

## 8. Restart Policy

| Policy | Behaviour | Use |
| --- | --- | --- |
| `no` | Never restart | Local only |
| `on-failure` | Restart on non-zero exit | Batch work that should not restart after success |
| `unless-stopped` | Restart unless explicitly stopped | Default for long-running services |
| `always` | Restart even after an explicit stop | Rarely correct — it fights the operator |

`unless-stopped` is the default for services. `always` restarts a container an operator deliberately stopped, including after a host reboot, which turns a controlled shutdown into an unexplained restart.

A restart policy is not a substitute for fixing a crash. A container in a restart loop may appear healthy in a coarse dashboard while serving nothing, which is why restart count is a required metric in [08-observability/](../08-observability/).

---

## 9. Validation

Validate before merge:

```bash
docker compose -f deployment/prod/compose.yml config --quiet
```

This resolves variables and checks syntax. It does not check whether the referenced image exists, whether the values are correct, or whether the deployment will work.

`TBD` — whether validation runs in the pipeline and blocks merge.

---

## 10. Anti-Patterns

| Anti-pattern | Consequence |
| --- | --- |
| `image: ...:latest` | No deterministic answer to what is running |
| `build:` in a deployed file | The host builds a different artifact than the one verified |
| Inline secrets in `environment:` | Credentials in Git |
| No `logging` limits | Host disk fills; every container on the host stops |
| No resource limits | One container degrades all others on the host |
| `ports: "8080:8080"` on a host with a public interface | Service published to the internet, bypassing host firewall expectations |
| Bind mounts for durable state | Host-specific configuration; data lost on host replacement |
| `restart: always` | Containers restart against operator intent |
| Base file plus multiple overrides | No one can read what production will run |

---

## 11. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — how Compose files reach runtime hosts | Deployment mechanism, interaction I-06 |
| `TBD` — resource limits per application type | Production stability |
| `TBD` — environment file ownership and permissions | Secret protection |
| `TBD` — whether Docker Compose file-based secrets are adopted | Secrets management |
| `TBD` — reverse proxy and TLS termination model | Port publishing rules |
| `TBD` — whether Compose validation blocks merge | Whether this standard is enforced |
| `TBD` — named volume backup scope per application | Disaster recovery |

---

## Security Considerations

Two items here have consequences disproportionate to how minor they look.

Port publishing without an explicit bind address exposes a service on every host interface, and Docker's packet-filter rules commonly take effect before the host firewall's — so a host that appears firewalled can still be serving the port. Always bind explicitly.

Inline environment secrets place credentials in Git, where history retains them after deletion. See [SECURITY.md](../../SECURITY.md) for the response if this occurs.

An `internal: true` backend network is a cheap and effective control. It costs one line and removes outbound reachability from the components most worth isolating.

## Operational Considerations

Log rotation and resource limits are the two settings that determine whether one misbehaving service stays contained. Both are omitted by default and both fail at the host level rather than the service level, which makes the resulting incident harder to attribute.

Every named volume is a backup obligation, and volumes are easy to add without anyone updating the backup scope. That mismatch surfaces during a recovery, which is the worst time to discover it.

---

## Related

- [Docker standard](docker-standard.md)
- [Dockerfile standard](dockerfile-standard.md)
- [Image versioning](image-versioning.md)
- [Compose templates](../../templates/compose/)
- [Environment architecture](../01-architecture/environment-architecture.md)
- [Disaster recovery](../11-disaster-recovery/)
