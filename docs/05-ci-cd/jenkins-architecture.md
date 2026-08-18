# Jenkins Architecture

## Purpose

Defines how Jenkins is structured and operated: controller and agents, credential isolation, shared library strategy, and backup.

## Scope

The Jenkins platform. What pipelines do is in [ci-standard.md](ci-standard.md) and [cd-standard.md](cd-standard.md).

## Audience

Platform engineers.

## Status

**Draft for review.** Not installed. The agent model is undecided and interacts with [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md).

---

## 1. What Jenkins Concentrates

Jenkins holds credentials for **every environment**, is authorized to publish artifacts, and is authorized to change production.

Its compromise is compromise of the delivery chain, and **no downstream control detects it** — everything it produces afterwards is legitimate in every observable respect: valid images, passing health checks, accurate deployment records naming real approvers.

This concentration cannot be removed at this scale. Everything in this document is about constraining it.

---

## 2. Controller and Agents

| Component | Runs | Holds |
| --- | --- | --- |
| Controller | Orchestration, the web interface, credential store | **Everything sensitive** |
| Agents | Build execution | Only what a build needs, only while it runs |

**Builds never run on the controller.** A build executing on the controller has access to the credential store, the configuration, and every other job's workspace — which makes any build capable of compromising the whole platform.

`TBD` — agent count and labels.

---

## 3. Ephemeral Versus Persistent Agents

`TBD`, and it matters more than it appears.

| | Ephemeral | Persistent |
| --- | --- | --- |
| Compromise persists to the next build | **No** | **Yes** |
| Artifacts leak between builds | No | Possible without disciplined cleanup |
| Build cache | Cold each time; slower | Warm; faster |
| Disk accumulation | None | Requires management |
| Provisioning cost | Per build | Once |
| Operational complexity | Higher | Lower |

A persistent agent compromised once affects **every subsequent build on it**, including builds for applications unrelated to the one that introduced the compromise. That is the argument for ephemeral, and it is a real security property rather than a preference.

The argument against is cost and complexity: cold caches make every build slower, and provisioning infrastructure is another thing to operate.

Interim measure if agents are persistent: clean the workspace after every build, and keep dependency caches inside the workspace so cleanup removes them.

---

## 4. Agents and ADR-0009

Option A in [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) places a Jenkins agent on **every runtime host, including production**.

| | Consequence |
| --- | --- |
| Satisfies the no-inbound constraint | The agent connects outbound to the controller |
| Widens what a production host compromise reaches | The agent holds controller connectivity |
| Conflicts with ephemeral agents | A runtime host's agent is persistent by nature |
| Adds a JVM to every runtime host | Patching, memory, and monitoring |

If option A is chosen, the agent model becomes mixed: ephemeral build agents, and persistent deployment agents on runtime hosts. That is workable and should be a deliberate decision rather than a consequence nobody noticed.

Options B, C, and D do not require agents on runtime hosts.

---

## 5. Credential Isolation

| Rule | Reason |
| --- | --- |
| Credentials scoped to the folder or job that needs them | A build cannot read credentials it has no business with |
| **Distinct credentials per environment** | A DEV compromise must not reach production |
| Referenced by identifier, never by value | Makes a later move to Vault a configuration change rather than a migration |
| Never echoed | Jenkins runs `sh` with `-x` in many configurations. `set +x` around every credential-handling block |
| Never a build parameter | Parameters are visible in build history |

The `set +x` requirement is not stylistic. Without it, a pipeline publishes its own registry password into a build log on every run — a log that is widely readable and long-lived.

`TBD` — credential ID naming convention.

---

## 6. Shared Library

`TBD` — **Phase 5.** Deliberately not now.

A shared library removes the duplication between the four pipeline templates, which the CI standard warns against. It is deferred because a library written before several services have run through the pipeline encodes patterns that were **predicted** rather than used — and an abstraction over a workflow nobody has run is expensive to unwind.

Candidates to factor out, marked `[LIBRARY CANDIDATE]` in [Jenkinsfile.template](../../templates/jenkins/Jenkinsfile.template):

- artifact identity computation
- Quality Gate wait with fail-closed behaviour
- dependency, secret, and container scanning
- SBOM generation
- Harbor push with credential handling and digest capture

When adopted, the library is version-controlled, reviewed, and **versioned** — pipelines pin a version rather than tracking a moving branch. An unpinned shared library means a change to it modifies every pipeline in the organization simultaneously, with no review of the effect.

---

## 7. Plugins

Plugins run **with controller privileges**. Capability comes from the ecosystem and so does the risk.

| Requirement | Reason |
| --- | --- |
| Plugin list and versions recorded | The input to any later question about what has that access |
| Reviewed before adding | Maintenance quality varies widely |
| Updated with the controller | A plugin that stops working after a core upgrade breaks a stage in a way that looks like an application failure |
| Unmaintained plugins removed | An unmaintained plugin with controller privileges is an unpatched dependency |

`TBD` — plugin inventory and its review process.

---

## 8. Backup

Covered by [jenkins-backup-and-restore.md](../../runbooks/jenkins-backup-and-restore.md). Two points belong here because they are architecture rather than procedure.

**The credential store is encrypted with a master key held separately.** Backed up without it, the restore succeeds and every credential is unusable. Backed up with it, the backup is a complete set of credentials for every environment — a production-equivalent asset requiring production-equivalent protection.

**Controller configuration as code** would move the reproducible parts into Git and leave credentials as the only irreplaceable item. `TBD` — worth adopting, and it also makes an upgrade a rebuild rather than an in-place change.

---

## 9. Failure Modes

| Failure | Effect | Recovery |
| --- | --- | --- |
| Controller down | **All delivery stops.** Production unaffected | Restore from backup |
| Agent down | Builds queue | Add or restore an agent |
| Agent disk full | Builds fail confusingly | Workspace cleanup; monitoring |
| Credential store unrecoverable | Every credential must be reissued across every system | Rotation, at scale |
| Plugin failure after upgrade | A stage breaks, often misdiagnosed as an application failure | Downgrade the plugin; restore as fallback |

Jenkins down is a **delivery outage**, not a service outage. Running containers keep serving. That distinction sets the urgency — see [disaster-recovery-plan.md](../11-disaster-recovery/disaster-recovery-plan.md#1-the-distinction-that-changes-everything).

---

## 10. Open Items

| Item |
| --- |
| `TBD` — ephemeral or persistent agents |
| `TBD` — agent count, labels, and available tooling |
| `TBD` — whether option A of ADR-0009 places agents on runtime hosts |
| `TBD` — credential ID naming convention |
| `TBD` — plugin inventory and review process |
| `TBD` — controller configuration as code |
| `TBD` — build log retention, matching evidence retention rather than a default |
| `TBD` — whether controller high availability is ever justified |

---

## Security Considerations

The controller is the platform's highest-value target and its compromise is undetectable downstream. The controls that matter are: builds never run on it, credentials are scoped and per-environment, administrative access is restricted, plugins are inventoried, and it is backed up in a way that is recoverable.

Ephemeral agents are the single largest available reduction in blast radius, and their cost is real. The decision should be made explicitly rather than defaulting to persistent because it is simpler to set up.

## Operational Considerations

The controller is a single point of failure whose recovery time is currently **unbounded**, because no restore has been demonstrated. Tested backup is not high availability and delivers most of the practical benefit at a fraction of the cost — it converts "unknown recovery time" into "measured recovery time".

Agent capacity is where build queueing lives, and queueing is usually most of the wall-clock time developers experience as "the pipeline is slow".

---

## Related

- [CI standard](ci-standard.md)
- [CD standard](cd-standard.md)
- [Jenkins backup and restore](../../runbooks/jenkins-backup-and-restore.md)
- [Jenkins templates](../../templates/jenkins/)
- [ADR-0001 — Jenkins](../../adr/0001-use-jenkins-for-ci-cd.md)
- [Secrets management](../07-security/secrets-management.md)
