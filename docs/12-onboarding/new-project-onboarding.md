# New Project Onboarding

## Purpose

An ordered checklist taking a new application from repository creation to its first production deployment.

## Scope

Consolidates steps defined across the source control, container, security, observability, and governance standards into one sequence. Each step links to the standard that defines it.

## Audience

Project leads, developers starting a service, and platform engineers provisioning one.

## Status

**Draft for review.** Several steps depend on decisions that are undecided — marked **BLOCKED** below.

---

## 1. Before Starting

| Question | Why it matters |
| --- | --- |
| Which application type? | Angular, .NET API, and .NET Worker have different templates and requirements |
| Does it hold durable state? | Volumes are a backup obligation and a rollback consideration |
| Does it have a database? | Migrations remove the rollback path; plan expand/contract from the start |
| Who owns it? | A role, recorded in the `README.md`. An unowned service is unmaintained |
| Does it need production? | Not everything does. DEV-only services skip most of this |

The migration question is worth answering before any code exists. Retrofitting expand/contract onto a schema designed without it is considerably more work than designing for it — see [release-and-tagging-standard.md](../04-source-control/release-and-tagging-standard.md#6-database-migrations-and-version-meaning).

---

## 2. Repository

| # | Step | Standard |
| --- | --- | --- |
| 1 | Create the repository from the template, with naming consistent across GitHub, Jenkins, SonarQube, Harbor, and observability labels | [git-standard.md](../04-source-control/git-standard.md#2-repository-naming) |
| 2 | Add `README.md` naming the **owning role**, and `AGENTS.md` | [git-standard.md](../04-source-control/git-standard.md#3-repository-contents) |
| 3 | Add `.gitignore`, `.gitattributes`, `.dockerignore` | [git-standard.md](../04-source-control/git-standard.md#6-line-endings) |
| 4 | Commit the dependency lockfile | [software-supply-chain-security.md](../07-security/software-supply-chain-security.md#3-dependency-trust) |
| 5 | Create `develop` from `main` | [branching-strategy.md](../04-source-control/branching-strategy.md#1-the-model) |
| 6 | Enable branch protection on both, including force-push and deletion blocking | [git-standard.md](../04-source-control/git-standard.md#7-branch-protection) |
| 7 | Configure required reviewers and required status checks | [pull-request-standard.md](../04-source-control/pull-request-standard.md#3-required-checks) |

Step 3 is easy to defer and expensive to defer. A missing `.dockerignore` means `.git` and any local `.env` enter the build context, and the resulting image ships them.

---

## 3. Build and Container

| # | Step | Standard |
| --- | --- | --- |
| 8 | Add the `Dockerfile` from the template for your application type | [dockerfile-standard.md](../06-container/dockerfile-standard.md#9-per-application-type) |
| 9 | Pin the base image to a version or digest from an approved source | [dockerfile-standard.md](../06-container/dockerfile-standard.md#2-base-image-policy) |
| 10 | Configure non-root execution and a port above 1024 | [dockerfile-standard.md](../06-container/dockerfile-standard.md#5-non-root-execution) |
| 11 | Use exec-form `ENTRYPOINT`; verify the container stops cleanly | [docker-standard.md](../06-container/docker-standard.md#2-process-and-signal-handling) |
| 12 | Move all environment-specific values to run-time configuration | [environment-architecture.md](../01-architecture/environment-architecture.md#7-configuration-and-secret-model) |
| 13 | Build locally and verify: non-root, clean stop, logs on stdout | [docker-standard.md](../06-container/docker-standard.md#9-verification) |

Step 12 is where the build-once model succeeds or fails, and for frontends it needs deliberate design rather than a configuration change.

---

## 4. Observability

| # | Step | Standard |
| --- | --- | --- |
| 14 | Add liveness and readiness endpoints, kept distinct | [observability-standard.md](../08-observability/observability-standard.md#3-health-signals) |
| 15 | For workers: add a heartbeat metric rather than an HTTP listener | [observability-standard.md](../08-observability/observability-standard.md#3-health-signals) |
| 16 | Expose the required metrics for your service type | [observability-standard.md](../08-observability/observability-standard.md#4-required-signals) |
| 17 | Configure structured logging with the required fields | [logging-standard.md](../08-observability/logging-standard.md#2-required-fields) |
| 18 | Propagate a correlation identifier across outbound calls | [observability-standard.md](../08-observability/observability-standard.md#5-correlation) |
| 19 | Verify no metric or log label carries unbounded values | [monitoring-standard.md](../08-observability/monitoring-standard.md#5-labels-and-cardinality) |

Do this before the pipeline exists, not after. Deployment verification and automatic rollback both depend on the service reporting whether it works — a service without health signals cannot be safely deployed by automation.

---

## 5. Pipeline

| # | Step | Standard | State |
| --- | --- | --- | --- |
| 20 | Add the `Jenkinsfile` from the template | [templates/jenkins/](../../templates/jenkins/) | Template not written |
| 21 | Register the project in SonarQube; define its Quality Gate | [05-ci-cd/](../05-ci-cd/) | Gate conditions `TBD` |
| 22 | Configure scanning thresholds | [vulnerability-management.md](../07-security/vulnerability-management.md#3-severity-thresholds) | Thresholds `TBD` |
| 23 | Configure coverage on new code | [pull-request-standard.md](../04-source-control/pull-request-standard.md#3-required-checks) | Threshold `TBD` |
| 24 | Verify the pipeline builds and publishes an image | | |

---

## 6. Registry

| # | Step | Standard |
| --- | --- | --- |
| 25 | Create the Harbor project; apply the naming convention | [harbor-standard.md](../06-container/harbor-standard.md#2-project-structure) |
| 26 | Create robot accounts: push for Jenkins, **pull-only per environment** for runtime hosts | [harbor-standard.md](../06-container/harbor-standard.md#3-access-model) |
| 27 | Enable tag immutability | [harbor-standard.md](../06-container/harbor-standard.md#4-immutability) |
| 28 | Configure retention, derived from required rollback depth | [image-retention-policy.md](../06-container/image-retention-policy.md#1-retention-is-a-reliability-control) |

Step 26 has no exception. A runtime host that can push images turns a host compromise into a supply-chain compromise.

Step 28 sets how far back a rollback can reach. Deriving it from storage cost instead silently shortens the recovery window.

---

## 7. Environments

| # | Step | Standard | State |
| --- | --- | --- | --- |
| 29 | Add Compose files per environment with explicit image tags, restart policy, health checks, **log rotation**, resource limits, and explicit networks | [docker-compose-standard.md](../06-container/docker-compose-standard.md#2-required-elements) | |
| 30 | Add `.env.example` with placeholders only | [docker-compose-standard.md](../06-container/docker-compose-standard.md#4-environment-values-and-secrets) | |
| 31 | Create **distinct** credentials per environment; store them in Jenkins Credentials or protected files outside Git | [secrets-management.md](../07-security/secrets-management.md#4-environment-isolation) | |
| 32 | Add named volumes to the backup scope | [backup-standard.md](../11-disaster-recovery/backup-standard.md#3-backup-scope) | |
| 33 | Configure deployment to DEV | | **BLOCKED** — see section 11 |
| 34 | Configure deployment to UAT | | **BLOCKED** |

Step 29's log rotation is one line and prevents a class of host-wide outage: the default log driver has no size limit, and a full disk stops every container on the host.

Step 32 is routinely missed. Every named volume is a backup obligation, and the mismatch is discovered during a recovery.

---

## 8. Monitoring and Alerting

| # | Step | Standard |
| --- | --- | --- |
| 35 | Add the service to Prometheus scrape configuration | [monitoring-standard.md](../08-observability/monitoring-standard.md#1-collection-model) |
| 36 | Verify logs reach Loki with the correct labels | [logging-standard.md](../08-observability/logging-standard.md#4-loki-labels-versus-fields) |
| 37 | Create the service dashboard from the template, provisioned as code | [dashboard-standard.md](../08-observability/dashboard-standard.md#10-dashboards-as-code) |
| 38 | Define alert rules, each with a runbook link | [alerting-standard.md](../08-observability/alerting-standard.md#5-rule-quality) |
| 39 | Confirm an alert actually reaches its destination | [alerting-standard.md](../08-observability/alerting-standard.md#6-monitoring-the-monitoring) |

Step 39 is a real test, not a configuration review. A rule that evaluates correctly and routes nowhere produces silence, which is indistinguishable from health.

---

## 9. Before First Production Deployment

| # | Step | Standard | State |
| --- | --- | --- | --- |
| 40 | Write the service runbook: deployment, rollback, common failures | [09-operations/](../09-operations/) | Not written |
| 41 | Define the smoke test | | `TBD` |
| 42 | **Execute a rollback in UAT and verify recovery** | [disaster-recovery-plan.md](../11-disaster-recovery/disaster-recovery-plan.md) | |
| 43 | Confirm the previous known-good image is retained | [image-retention-policy.md](../06-container/image-retention-policy.md#2-never-delete) | |
| 44 | Record any migration rollback limitation in the release notes | [release-and-tagging-standard.md](../04-source-control/release-and-tagging-standard.md#7-release-notes) | |
| 45 | Confirm the production approver role | [devops-governance.md](../10-governance/devops-governance.md#2-roles) | **BLOCKED** |
| 46 | Confirm production deployments produce a deployment record | [audit-evidence.md](../10-governance/audit-evidence.md#3-the-deployment-record) | Not implemented |
| 47 | Record which blueprint version this project aligns with | [README.md](../../README.md#11-versioning-policy) | |

**Step 42 is the one not to skip.** Rollback designed but never executed is an assumption. Executing it once in UAT costs an hour and is the difference between having a recovery path and believing you have one.

---

## 10. First Production Deployment

```text
1. Cut release/<version> from develop
2. Deploy to DEV; health check
3. Deploy to UAT; health check; verify
4. Merge to main; tag v<version>
5. Production approval
6. Deploy the SAME image; health check; smoke test
7. Record evidence
8. MERGE BACK to develop
```

Step 6 deploys the artifact UAT verified. Nothing is rebuilt.

Step 8 is not optional. Skipping it reverts every fix made during UAT at the next release.

---

## 11. Currently Blocked

| Step | Blocked by |
| --- | --- |
| 33, 34 — deployment configuration | The deployment mechanism to runtime hosts is undecided |
| 45 — production approver | No governance role has been assigned |
| 20 — Jenkins template | Templates not yet written |
| 40 — runbooks | Operations documentation not yet written |

Steps 1 to 32 and 35 to 39 can proceed today. A project can be created, built, containerized, instrumented, and published to a registry before either blocker is resolved.

---

## 12. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — who provisions Harbor projects, Jenkins jobs, and SonarQube projects | Steps 21, 25 |
| `TBD` — expected elapsed time from repository creation to first production deployment | Planning |
| `TBD` — whether provisioning is automated | Consistency across projects |
| `TBD` — smoke test definition per application type | Step 41 |
| `TBD` — who signs off that onboarding is complete | Accountability |

---

## Security Considerations

Three steps carry disproportionate security weight: pull-only runtime credentials (26), distinct credentials per environment (31), and no secrets in Git (3, 30). All three are cheap at project creation and expensive to retrofit once systems depend on the wrong arrangement.

Tag immutability (27) is what prevents an identifier from later referring to different content, which would retroactively invalidate every deployment record naming it.

## Operational Considerations

The sequence matters. Observability before the pipeline, because deployment verification depends on it. Retention before first production deployment, because it bounds rollback. A tested rollback before production, because rollback is the control most relied upon and least demonstrated.

Steps 42 and 43 together are the difference between a service that can be recovered and one that is assumed to be recoverable.

---

## Related

- [Developer onboarding](developer-onboarding.md)
- [DevOps team onboarding](devops-team-onboarding.md)
- [Project template](../../templates/project-template/)
- [Source control standards](../04-source-control/)
- [Container standards](../06-container/)
- [Governance](../10-governance/)
