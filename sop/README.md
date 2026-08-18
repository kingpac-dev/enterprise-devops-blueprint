# Standard Operating Procedures

## Purpose

Recurring, scheduled, or request-driven procedures that are not incident response.

## Scope

Routine operational work: access requests, onboarding and offboarding, credential rotation, periodic reviews, and scheduled maintenance.

## Status

**Draft for review.** Seven procedures written. Frequencies, approving roles, and record locations are `TBD` throughout — the procedures are executable, the schedules are not yet set.

---

## Difference From `runbooks/`

| Directory | Triggered by |
| --- | --- |
| [runbooks/](../runbooks/) and [docs/09-operations/](../docs/09-operations/) | An event — a deployment, a failure, an incident |
| `sop/` | A schedule or a request — routine, planned, repeatable work |

A rollback is a runbook. A quarterly credential rotation is an SOP.

---

## Procedures

| File | Intent | Status |
| --- | --- | --- |
| [restore-test.md](restore-test.md) | Executing and evidencing a restore test — **start here** | Draft |
| [credential-rotation.md](credential-rotation.md) | Rotation per credential type, and the compromise-driven variant | Draft |
| [access-request.md](access-request.md) | Requesting, approving, granting, recording, and expiring access | Draft |
| [access-review.md](access-review.md) | Periodic review; catching drift that no other process sees | Draft |
| [offboarding.md](offboarding.md) | Departure and role change, including shared-credential rotation | Draft |
| [new-project-provisioning.md](new-project-provisioning.md) | Platform-side resource creation for a new service | Draft |
| [scheduled-maintenance.md](scheduled-maintenance.md) | Windows, Harbor garbage collection, host patching | Draft |

## Start With the Restore Test

[restore-test.md](restore-test.md) covers risk R-30, ranked **first** in the [risk register](../docs/00-executive/risk-register.md#9-highest-priority) by severity against cost to reduce.

The first test is roughly a day of work and **does not require the platform to be complete**. Its two load-bearing rules:

- **A restore into the running system is not a test.** It succeeds for reasons that will not exist during a real recovery — configuration already present, dependencies installed, credentials in place, network routes working.
- **The target must be network-isolated.** A restored Jenkins that can reach production will run its scheduled jobs *against production*. A safety exercise then becomes an incident.

## Steps That Are Routinely Skipped

Each of these appears in a procedure because it is the step people omit, and each has a specific consequence.

| Procedure | Step | If skipped |
| --- | --- | --- |
| [credential-rotation.md](credential-rotation.md) | Verify the **old** credential is rejected | The number of valid credentials increased rather than one being replaced — and the old one is now unowned and unmonitored |
| [offboarding.md](offboarding.md) | Rotate shared credentials the leaver could reach | Access control cannot distinguish a credential nobody has from one someone outside the organization has |
| [offboarding.md](offboarding.md) | Re-provision on role change rather than **add** | Over a few moves, someone holds the union of every role they have ever held, and no single grant was wrong |
| [access-request.md](access-request.md) | Verify removal at expiry | Access granted for an investigation outlives it, because removal is nobody's scheduled task |
| [scheduled-maintenance.md](scheduled-maintenance.md) | Confirm the previous known-good image survived garbage collection | A service is left with no rollback path, and nothing reports it until the next rollback attempt |
| [scheduled-maintenance.md](scheduled-maintenance.md) | Verify the backup still succeeds **after** an upgrade | Backups fail silently after upgrades more often than at any other time |

## The Prerequisite Nothing Here Can Substitute For

Several procedures depend on a **credential inventory** — what exists, who owns it, when it expires.

Without it, "rotate every shared credential the leaver could reach" is not answerable, and rotation on a schedule has nothing to schedule. `TBD`, and it blocks the practical execution of [credential-rotation.md](credential-rotation.md) and step 4 of [offboarding.md](offboarding.md).

---

## Requirements

Each SOP must state its trigger and frequency, the responsible and approving roles, preconditions, ordered steps, verification, the evidence recorded, and where that evidence is retained.

Roles are named by **role**, never by invented individual names.

---

## Open Items

- `TBD` — access review frequency
- `TBD` — credential rotation frequency per credential type
- `TBD` — maintenance window policy and notice period
- `TBD` — evidence retention location and period

---

## Related

- [Governance](../docs/10-governance/)
- [Runbooks](../runbooks/)
- [Security standards](../docs/07-security/)
- [Disaster recovery](../docs/11-disaster-recovery/)
