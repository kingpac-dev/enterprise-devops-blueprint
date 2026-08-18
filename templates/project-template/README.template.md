# <Service Name>

<!--
Copy to your repository root as README.md and replace every <placeholder>.
Delete these comments.

This README is read by someone who did not build the service, under time
pressure, trying to work out why it is broken. Optimise for that reader.
-->

<One sentence: what this service does and for whom.>

| | |
| --- | --- |
| **Owning role** | `<role, never an individual — an unowned service is unmaintained>` |
| **Type** | Angular / .NET Web API / .NET Worker Service |
| **Repository** | `<repo-name>` |
| **Harbor project** | `<harbor-project>/<image-name>` |
| **SonarQube key** | `<sonar-key>` |
| **Service label** | `<value of the `service` label in metrics and logs>` |
| **Blueprint version** | `<version this project aligns with>` |

The five identifiers above should be the **same name** wherever possible. Every inconsistency becomes a translation step performed by a person during an incident.

---

## What It Does

<Two or three paragraphs. What problem it solves, what it talks to, what
depends on it. Enough for someone unfamiliar to orient in a minute.>

### Dependencies

| Depends on | For | If unavailable |
| --- | --- | --- |
| `<service or system>` | `<what>` | `<degraded how — this is the row that matters during an incident>` |

### Depended on by

| Consumer | For |
| --- | --- |
| `<service>` | `<what>` |

---

## Build and Test Locally

```bash
# Prerequisites: <tooling and versions>

<restore command>
<build command>
<test command>

# Build the container — most pipeline failures at the container stage
# reproduce here in one command
docker build -t <image-name>:local .
```

---

## Run Locally

```bash
cp deployment/.env.example .env
# Fill in local values. NEVER put real credentials in a local .env — a local
# .env plus a missing .dockerignore is how production credentials end up
# inside an image.

docker compose -f deployment/dev/compose.yml up
```

| Endpoint | URL |
| --- | --- |
| Application | `<url>` |
| Liveness | `<url>/health/live` |
| Readiness | `<url>/health/ready` |
| Metrics | `<url>/metrics` |

---

## Configuration

Every value the service reads. **Keep this table current** — a release requiring a new value deploys successfully and then fails at run time, in production, on the values that were not set.

| Variable | Required | Default | Purpose | Secret |
| --- | --- | --- | --- | --- |
| `<VAR>` | Yes | — | `<what it controls>` | No |
| `<VAR>` | Yes | — | `<what it controls>` | **Yes** — Jenkins Credentials |
| `<VAR>` | No | `<safe default>` | `<what it controls>` | No |

Defaults must be safe if nothing overrides them. A default that points at a production endpoint, or that disables a control, is a defect: the failure mode of a missing override should be "does not start", not "starts and connects to production".

Secrets are supplied through Jenkins Credentials or environment-specific protected files held outside Git. Never in this repository, never in a Compose file, never in a build argument.

---

## Observability

| Signal | Where |
| --- | --- |
| Dashboard | `<link>` |
| Alerts | `<link>` |
| Logs | `{service="<service-label>", environment="prod"}` |
| Key metrics | `<the two or three that matter most for this service>` |

### What "unhealthy" looks like

<The specific symptoms of this service failing, and where they show first.
This is the most valuable section in this document for whoever is on call.>

---

## Deploy

| Environment | Trigger | Approval |
| --- | --- | --- |
| DEV | Automatic on merge to `develop` | None |
| UAT | On `release/*` | `TBD` |
| PROD | Manual, after UAT verification | Required |

The same image is promoted through all three. Nothing is rebuilt.

### Rollback

<State plainly whether rollback is available for this service.>

| | |
| --- | --- |
| Rollback available | Yes / **No, because `<reason>`** |
| Method | Redeploy the previous image |
| Limitations | `<database migrations, external side effects, anything irreversible>` |
| Last verified | `<date a rollback was actually executed>` |

**If this service has database migrations, rollback is probably unavailable.** Redeploying the previous image leaves old code against a new schema. Say so here, and in the release notes before approval — not during a failed deployment.

"Last verified" is the row that matters. Rollback designed but never executed is an assumption.

---

## Runbooks

| Situation | Runbook |
| --- | --- |
| Deployment | `<link>` |
| Rollback | `<link>` |
| Common failures | `<link>` |

---

## Contributing

Follow the [Enterprise DevOps Blueprint](<link>) standards. Project-specific rules are in [AGENTS.md](AGENTS.md).

```text
feature/* -> develop -> DEV
release/* -> UAT
main      -> PROD
```

After a fix on a release branch reaches `main`, **it must also be merged back to `develop`** — otherwise the next release reverts it, a full cycle later, and whoever fixed it will believe it is fixed.
