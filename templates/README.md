# Templates

## Purpose

Reusable, copy-and-adapt artifacts that let an application team adopt the blueprint without writing pipeline and container configuration from scratch.

## Scope

Jenkins pipelines, Dockerfiles, Compose files, SonarQube configuration, security scanning configuration, monitoring configuration, and a full project template.

## Status

**Published.** Production-ready templates available across all supported platforms and stacks.

---

## Contents

| Directory | Contents | Target Platforms / Stacks |
| --- | --- | --- |
| [jenkins/](jenkins/) | `Jenkinsfile` templates and GitOps deploy script | Angular, React+Vite, .NET API, Go Fiber, .NET Worker |
| [docker/](docker/) | Multi-stage `Dockerfile`, `.dockerignore`, and Nginx configurations | Angular, React+Vite, .NET API, Go Fiber, .NET Worker |
| [compose/](compose/) | Environment-specific Compose files (`compose.dev.yml`, `compose.uat.yml`, `compose.prod.yml`) and `.env.example` | All workloads |
| [sonar/](sonar/) | SonarQube project configurations and quality gate baseline standard | Angular, React+Vite, .NET, Go |
| [security/](security/) | `trivy.yaml`, `.trivyignore.example`, SBOM generation, and secret scanning standards | Trivy, Gitleaks, Syft |
| [monitoring/](monitoring/) | Prometheus scrape configuration, Alertmanager rules, Grafana service dashboard JSON, and Loki label rules | Prometheus, Loki, Grafana |
| [project-template/](project-template/) | Complete starting layout for a new application repository (`README`, `AGENTS.md`, `.gitignore.*`, `RELEASE-NOTES`) | New Projects |

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
