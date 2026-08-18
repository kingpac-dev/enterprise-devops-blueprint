# Runbooks

## Purpose

Executable operational procedures, kept where operators can find them quickly.

## Scope

Procedures for the **platform itself** — Jenkins, Harbor, SonarQube, and the observability stack.

## Status

**Draft for review.** Six runbooks written. **None has ever been executed** — they are written from design, not from experience.

---

## Boundary With `docs/09-operations/`

Both this directory and [docs/09-operations/](../docs/09-operations/) hold runbooks. To prevent the same procedure existing in two places, the split is defined by **what is being operated**:

| Location | Holds |
| --- | --- |
| [docs/09-operations/](../docs/09-operations/) | **Application delivery** runbooks: deployment, rollback, incident response, container troubleshooting, certificate renewal |
| `runbooks/` | **Platform** runbooks: operating Jenkins, Harbor, SonarQube, and the monitoring stack |

Test to apply: if the procedure is executed by an application team to deliver or recover *their service*, it belongs in `docs/09-operations/`. If it is executed by the platform team to keep *the toolchain itself* running, it belongs here.

---

## Platform Runbooks

| File | Intent | Status |
| --- | --- | --- |
| [jenkins-backup-and-restore.md](jenkins-backup-and-restore.md) | Backup scope, the master key problem, restore, functional verification | Draft |
| [jenkins-upgrade.md](jenkins-upgrade.md) | Plan, execute, verify, rollback, abort criteria | Draft |
| [harbor-restore.md](harbor-restore.md) | Assessment, consistent two-component restore, unrecoverable storage, emergency rollback | Draft |
| [harbor-storage-management.md](harbor-storage-management.md) | Alerts, retention review, garbage collection, exhaustion | Draft |
| [sonarqube-maintenance.md](sonarqube-maintenance.md) | Database, backup, upgrade, the outage-exception path, restore | Draft |
| [observability-stack-recovery.md](observability-stack-recovery.md) | Heartbeat failure, per-component recovery, cardinality incidents | Draft |

## These Runbooks Have Never Been Run

A runbook that has never been executed is an untested assumption, and this repository applies that standard to backups — so it applies it here too.

Their **first execution is itself the first restore test**, per [restore-test.md](../sop/restore-test.md), and the corrections that execution produces are the main deliverable. Follow them exactly, without improvising, and record every point where they are wrong or incomplete.

## Verification Is Functional, Never "It Started"

Each runbook verifies that the component **works**, not that it is running. Four checks carry disproportionate weight:

| Runbook | Check | Catches |
| --- | --- | --- |
| [jenkins-backup-and-restore.md](jenkins-backup-and-restore.md) | **Use a restored credential** in a real job | The credential store restored without its master key — the restore succeeds and every credential is unusable. Nothing else detects this |
| [harbor-restore.md](harbor-restore.md) | **The previous known-good image for each production service is present** | A restore that recovered the registry but not rollback capability |
| [harbor-storage-management.md](harbor-storage-management.md) | The same check, **after garbage collection** | A collection that evicted a rollback target — silent until the next rollback attempt |
| [observability-stack-recovery.md](observability-stack-recovery.md) | **An alert reaches its destination** | A rule that evaluates correctly and routes nowhere, producing silence |

## Two Decisions Pre-Empted Under Pressure

Both are written down because both will be argued during an outage, when the fast answer is the wrong one.

**Do not shorten Harbor retention to free storage.** Retention bounds how far back a rollback can reach. Cutting it under pressure trades an availability problem for a recoverability one, silently. See [harbor-storage-management.md](harbor-storage-management.md#5-storage-exhausted).

**Do not make the Quality Gate advisory when SonarQube is down.** An unevaluated gate is not a pass; treating it as one converts a tool outage into a silent bypass of a mandatory control. If proceeding is genuinely necessary, it is a recorded, time-bounded exception. See [sonarqube-maintenance.md](sonarqube-maintenance.md#5-sonarqube-unavailable--delivery-blocked).

---

## Runbook Requirements

Each runbook must state when to use it, preconditions and required access, exact ordered steps, verification after each significant step, failure branches, an abort or rollback path, evidence to record, and the escalation path by role.

Runbooks are written to be executed under pressure by someone who did not write them.

---

## Related

- [Application operations runbooks](../docs/09-operations/)
- [Standard operating procedures](../sop/)
- [Disaster recovery](../docs/11-disaster-recovery/)
