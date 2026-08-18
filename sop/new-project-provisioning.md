# SOP — New Project Provisioning

## Trigger

A team is starting a new service and needs its platform resources created.

This is the **platform side**. The team's own checklist is [new-project-onboarding.md](../docs/12-onboarding/new-project-onboarding.md).

## Roles

| Role | Responsibility |
| --- | --- |
| Requester | Team lead of the owning team |
| Provisioner (`TBD`) | Creates the resources |
| Security owner (`TBD`) | Consulted on the access model |

---

## Preconditions

- [ ] Service name agreed, and **consistent** across GitHub, Jenkins, SonarQube, Harbor, and the observability `service` label
- [ ] Owning **role** identified — not an individual
- [ ] Application type known: Angular, .NET API, or .NET Worker
- [ ] Whether the service holds durable state, and whether it has database migrations

Name consistency is worth the argument at this stage. Every inconsistency becomes a translation step performed by a person under time pressure, and it is far cheaper to settle now than to rename five systems later.

---

## Steps

### 1. GitHub repository

- [ ] Created from the template, with the agreed name
- [ ] `develop` created from `main`
- [ ] Branch protection on both: pull request required, approvals `TBD`, stale approvals dismissed, status checks required, **force push blocked**, **deletion blocked**
- [ ] `TBD` — whether administrators are included in protection

Force-push protection has the least obvious justification and one of the more serious consequences: rewriting a protected branch can orphan a commit that a deployed image was built from, leaving the deployment record pointing at nothing.

### 2. Harbor project

- [ ] Project created
- [ ] **Tag immutability rule enabled**
- [ ] Robot account: push and pull, scoped to this project, **expiry set** — for Jenkins
- [ ] Robot account: **pull only**, one per environment — for runtime hosts
- [ ] Retention policy configured, derived from required rollback depth
- [ ] Retention rule **dry-run and reviewed** before enabling

The pull-only rule has no exception. A runtime host that can push turns a host compromise into a supply-chain compromise.

The dry run matters because the alternative is discovering the mistake as a failed rollback.

### 3. SonarQube project

- [ ] Project created with the agreed key
- [ ] Quality Gate assigned
- [ ] Analysis token issued, project-scoped where supported, and stored in Jenkins Credentials

### 4. Jenkins

- [ ] Job or multibranch pipeline created
- [ ] Credentials registered: `sonarqube-token`, `harbor-push`
- [ ] Agent label available with the required tooling
- [ ] Build log retention set to match evidence retention, not a convenient default

### 5. Observability

- [ ] Service added to Prometheus scrape configuration with `environment` and `service` labels
- [ ] Log collection confirmed, with the agreed labels
- [ ] Dashboard created from the template, provisioned as code
- [ ] Alert rules created, each with a runbook link
- [ ] **An alert confirmed to actually reach its destination**

The last is a real test, not a configuration review. A rule that evaluates correctly and routes nowhere produces silence, which is indistinguishable from health.

### 6. Environments

- [ ] Environment-specific credentials created — **distinct per environment, sharing nothing**
- [ ] Deployment target prepared
- [ ] Named volumes added to the backup scope

`TBD` — deployment configuration is blocked by [ADR-0009](../adr/0009-deployment-mechanism-to-runtime-hosts.md).

The volume step is routinely missed. Every named volume is a backup obligation, and the mismatch is discovered during a recovery.

### 7. Record

| Field |
| --- |
| Service name, and its identifier in each system |
| Owning role |
| Resources created |
| Robot account names and expiries |
| Provisioned by which role, when |

---

## Verification

- [ ] A commit to `develop` triggers a build
- [ ] The build reaches the Quality Gate and it evaluates
- [ ] An image publishes to Harbor
- [ ] The image cannot be pushed with a runtime host's credential
- [ ] Metrics appear in Prometheus with the correct labels
- [ ] Logs appear in Loki with the correct labels
- [ ] An alert reaches its destination

The fourth is a negative test and is worth running once. It confirms the access model is what was intended rather than what was typed.

---

## Open Items

| Item |
| --- |
| `TBD` — who provisions each resource |
| `TBD` — whether provisioning is automated |
| `TBD` — naming convention, confirmed |
| `TBD` — robot account naming and expiry period |
| `TBD` — who signs off that provisioning is complete |

Automation is worth reaching for here. Manual provisioning produces resources that differ in ways nobody notices until one is found to have had no required checks for six months.

---

## Related

- [New project onboarding](../docs/12-onboarding/new-project-onboarding.md)
- [Git standard](../docs/04-source-control/git-standard.md)
- [Harbor standard](../docs/06-container/harbor-standard.md)
- [Access control](../docs/07-security/access-control.md)
