# Templates

## Purpose

Reusable, copy-and-adapt artifacts that let an application team adopt the blueprint without writing pipeline and container configuration from scratch.

## Scope

Jenkins pipelines, Dockerfiles, Compose files, SonarQube configuration, security scanning configuration, monitoring configuration, and a full project template.

## Status

**Skeleton.** No templates published yet.

---

## Contents

| Directory | Contents |
| --- | --- |
| [jenkins/](jenkins/) | `Jenkinsfile` templates per application type |
| [docker/](docker/) | `Dockerfile` and `.dockerignore` templates per application type |
| [compose/](compose/) | Environment-specific Compose files and `.env.example` |
| [sonar/](sonar/) | SonarQube project configuration |
| [security/](security/) | Trivy and scanning configuration, ignore policy, SBOM generation |
| [monitoring/](monitoring/) | Prometheus scrape configuration, alert rules, Grafana dashboards |
| [project-template/](project-template/) | Complete starting layout for a new application repository |

---

## Rules for Every Template

- **No real credentials, ever.** Use Jenkins Credentials references or obvious placeholders.
- No real hostnames, IP addresses, or internal DNS names. Use `example.internal` style values or `TBD`.
- Templates must be secure by default. A team copying a template unchanged must not end up with a weakened control.
- State clearly which values a team must replace, and which must not be changed.
- Keep templates consistent with the corresponding standard in `docs/`. When a standard changes, update the template in the same change set.
- Prefer parameterization and Jenkins Shared Libraries over copies that drift apart.

A template is replicated across many repositories. A weakness introduced here is replicated with it — which is why template changes require security review under [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## Related

- [Documentation index](../docs/README.md)
- [CI/CD standards](../docs/05-ci-cd/)
- [Container standards](../docs/06-container/)
- [Security standards](../docs/07-security/)
- [Examples](../examples/)
