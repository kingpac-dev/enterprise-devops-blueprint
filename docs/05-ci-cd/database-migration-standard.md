# Database Migration Standard

## Purpose

Defines how schema changes are made, when they are executed, and — the reason this standard exists — **what they do to rollback**.

## Scope

Schema and data migrations for application databases. The database as infrastructure is in [database-standard.md](../02-infrastructure/database-standard.md); rollback in general is in [rollback-strategy.md](rollback-strategy.md).

## Audience

Developers writing migrations, reviewers approving them, and release approvers deciding whether to deploy them.

## Status

**Draft for review.** Migration tooling is undecided. This closes the `TBD` items in [release-and-tagging-standard.md](../04-source-control/release-and-tagging-standard.md) and [rollback-strategy.md](rollback-strategy.md) that deferred to it.

---

## 1. Migrations Are Where Rollback Goes to Die

Every other recovery mechanism in this blueprint is "redeploy the previous immutable image". **A migration is the one change that mechanism cannot undo.**

Redeploy the previous image after a schema change and the old code runs against the new schema. Depending on what changed, it either works, fails on every request, or — worst — appears to work while writing to columns that are no longer read.

That is the whole subject. Everything below follows from it.

---

## 2. GitOps Makes Backward Compatibility Structural, Not Optional

Under [ADR-0010](../../adr/0010-portainer-gitops-deployment.md), the pipeline does not deploy. It publishes an image, then commits a new tag; Portainer notices and deploys.

That creates a window with a specific and unavoidable property:

```text
1. Jenkins publishes image v2 to Harbor
2. Jenkins runs the migration                 <- schema is now v2
3. Jenkins commits the v2 tag
4. Portainer notices and redeploys            <- code becomes v2

   Between steps 2 and 4, application v1 is running against schema v2.
```

**The window is not a design flaw to be closed — it is inherent to pull-based deployment.** Its length depends on the webhook, the polling interval, and how long the container takes to restart. It is never zero.

Therefore:

> **Every migration must leave the *previous* application version working.**

That is not a best practice recommendation here. It is a structural requirement of the deployment model, and a migration that violates it produces an outage in the window even when the release is otherwise perfect.

Expand/contract is how it is satisfied.

---

## 3. Expand and Contract

Split every breaking change across releases so that **each individual step is backward compatible**.

Renaming `customer_name` to `full_name`:

| Release | Migration | Application | Old version still works? |
| --- | --- | --- | --- |
| **N — expand** | Add `full_name`, nullable | Writes both; reads `customer_name` | ✅ It does not know the new column exists |
| **N+1 — migrate** | Backfill `full_name` | Writes both; reads `full_name` | ✅ `customer_name` is still written |
| **N+2 — stop writing** | None | Writes and reads `full_name` only | ✅ It reads `customer_name`, which still holds data |
| **N+3 — contract** | Drop `customer_name` | Unchanged | ❌ **Only now is version N broken** |

Four releases instead of one. In exchange, **a rollback is available at every step except the last** — and by the time N+3 ships, version N is several releases old and nobody is rolling back that far.

| Change | Expand/contract form |
| --- | --- |
| Rename a column | Add new → backfill → switch reads → drop old |
| Change a type | Add new column of the new type → backfill → switch → drop |
| Make a column required | Add nullable → backfill → application enforces → add constraint |
| Split a table | Add new table → dual-write → switch reads → stop writing → drop |
| Drop a column | Stop reading → stop writing → drop, one release apart |

`TBD` — whether expand/contract is mandatory or advisory. Given section 2, **mandatory** is the coherent position: the alternative is an outage window on every breaking change.

---

## 4. Classification

Every migration is classified in the pull request. The class determines what the release notes say and what the approver is agreeing to.

| Class | Examples | Rollback | Approval |
| --- | --- | --- | --- |
| **Safe** | Add nullable column, add table, add index concurrently | Available | Normal |
| **Expand** | Any expand phase of a planned contract | Available | Normal |
| **Data** | Backfill, correction | Available for schema; **data change is not undone** | Normal, with a backup |
| **Destructive** | Drop column or table, tighten a constraint, change a type in place | **NOT AVAILABLE** | **Explicit, with the limitation stated** |

**A destructive migration must be stated in the release notes before approval** — not discovered during a failed deployment. See [RELEASE-NOTES.template.md](../../templates/project-template/RELEASE-NOTES.template.md).

---

## 5. Execution: Where Migrations Run

`TBD` — decide before the first migration. Three options, and the deployment model rules one of them out.

### Option A — A pipeline step, before committing the tag

```text
build → publish → MIGRATE → commit tag → Portainer deploys
```

| | |
| --- | --- |
| Ordering | Correct: the schema is ready before the code that needs it arrives |
| Failure | Visible in the pipeline; the tag is never committed, so nothing deploys |
| Concurrency | Single execution — no race |
| Requires | The migration account, held only by this step |
| Constraint | **The migration must be backward compatible**, per section 2 |

**Recommended.** It is the only option where a failed migration prevents the deployment rather than breaking it.

### Option B — The application migrates on startup

| | |
| --- | --- |
| Ordering | Correct per instance |
| Failure | The container fails to start — a **crash loop**, not a clear error |
| Concurrency | **Multiple instances race.** Requires an advisory lock |
| Requires | The application account to hold schema permissions, which [database-standard.md](../02-infrastructure/database-standard.md#3-credentials) argues against |
| Under GitOps | Runs again on **every redeploy**, including a rollback |

The last row is the problem. A rollback redeploys the previous image, which runs its startup migration — against a schema that is already ahead of it. Behaviour then depends entirely on the tool.

### Option C — Manual execution

Rejected as a routine path. No audit trail beyond what someone remembers to record, and no relationship to the release that needs it.

Acceptable only as an emergency path, under change control.

---

## 6. Tooling

`TBD` — per stack. Whatever is chosen must provide: versioned migrations in source control, a recorded applied state, single-execution safety, and a dry-run.

| Stack | Candidates | Note |
| --- | --- | --- |
| .NET | EF Core Migrations; DbUp; Fluent Migrator | EF Core generates from the model, which is convenient and makes it easy to produce a destructive migration without noticing — **review the generated SQL, not the model diff** |
| Go | golang-migrate; goose; Atlas | Plain SQL files, which makes review straightforward |

**Migrations live in the application repository**, versioned with the code that needs them. A schema change and the code that depends on it belong in the same reviewed change.

### Review the SQL

For any tool that generates migrations, the pull request must show the **SQL**, not only the model change. A one-line model edit can generate a `DROP COLUMN`, and a reviewer looking at the model diff will not see it.

---

## 7. Operations That Lock

A migration that takes a lock on a busy table is an outage, and the ones that do are not obvious.

| Operation | PostgreSQL behaviour |
| --- | --- |
| `ADD COLUMN` with no default | Fast — metadata only |
| `ADD COLUMN` with a volatile default | **Rewrites the table** |
| `CREATE INDEX` | **Blocks writes** — use `CREATE INDEX CONCURRENTLY` |
| `ALTER COLUMN TYPE` | **Rewrites the table** |
| `ADD CONSTRAINT` | Blocks — add `NOT VALID`, then `VALIDATE` separately |
| `DROP COLUMN` | Fast |

Requirements:

- **Set a lock timeout.** Without one, a migration waits behind a long-running query and then holds a queue of blocked requests behind itself — the outage is caused by the waiting, not the change.
- `CREATE INDEX CONCURRENTLY` on any table with traffic. It cannot run inside a transaction, which most migration tools wrap by default — `TBD`, confirm the tool supports it.
- Test against **production-like data volume**. A migration that takes 200 ms on an empty DEV table can take minutes on production, and that difference is invisible until it happens.

---

## 8. Backup Before Destructive Changes

**Required**, and verified — not assumed.

```text
1. Take a backup
2. VERIFY it is readable
3. Record which backup corresponds to which migration
4. Run the migration
```

Step 3 is what makes the backup usable during recovery. "Restore the backup from before the migration" needs someone to know which one that was, under pressure.

Point-in-time recovery makes this considerably better: recovery targets the moment before the migration rather than the last full backup. See [database-standard.md](../02-infrastructure/database-standard.md#5-backup--now-the-most-important-backup-in-the-system).

---

## 9. When It Goes Wrong

| Situation | Response |
| --- | --- |
| Migration fails cleanly | Nothing deployed under option A. Fix and retry |
| Migration partially applied | **Do not retry blindly.** Establish the actual schema state first |
| Migration succeeded, application broken | Roll back the **application** if the migration was backward compatible. If it was not, forward fix |
| Migration succeeded, data corrupted | Point-in-time restore to before the migration. **This loses everything written since** — a decision requiring the authority in [disaster-recovery-plan.md](../11-disaster-recovery/disaster-recovery-plan.md#5-decision-authority) |
| Destructive migration, application broken | **Rollback unavailable.** Forward fix. This was known at approval |

The second row is the one that turns a problem into an incident. A migration tool that recorded a version but did not complete its work leaves the schema in a state neither the old nor the new code expects, and retrying may apply parts of it twice.

`TBD` — whether the chosen tool wraps each migration in a transaction. PostgreSQL supports transactional DDL, which makes partial application impossible for most operations — a strong reason to prefer a tool that uses it, and a reason `CREATE INDEX CONCURRENTLY` needs separate handling since it cannot run in one.

---

## 10. What the Approver Needs

A release containing a migration changes what approval means. The release notes must state:

| Field | |
| --- | --- |
| Migration class | Safe / Expand / Data / **Destructive** |
| What it does | In plain terms |
| **Rollback available** | Yes, or **no with the reason** |
| Locking risk | Expected duration against production volume |
| Backup taken and verified | Yes, with which backup |
| Forward recovery plan | Where rollback is unavailable |

Approving a destructive migration is approving a release that **cannot be rolled back**. That should be a conscious decision, made with the information above, rather than a discovery made later.

---

## 11. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — migration tooling per stack | Everything |
| `TBD` — **execution option A, B, or C** | Ordering, failure behaviour, credentials |
| `TBD` — whether expand/contract is mandatory | Whether rollback survives breaking changes |
| `TBD` — migration ownership: who writes, who reviews, who approves | Accountability |
| `TBD` — lock timeout value | Outage risk |
| `TBD` — whether migrations are tested against production-like volume | Whether duration is known before production |
| `TBD` — separate migration account and its grants | [database-standard.md](../02-infrastructure/database-standard.md#3-credentials) |
| `TBD` — backup verification step in the pipeline | Recovery |

---

## Security Considerations

The migration account holds `CREATE`, `ALTER`, and `DROP` — permissions the running application should not have. It is held by the migration step only, and it is the credential whose compromise allows arbitrary schema change.

Migrations that touch personal data are data-protection events as much as technical ones. A backfill that copies data into a new column has copied it, and a later `DROP` of the old column is the only thing that removes it.

Migration SQL is reviewed as code, and generated migrations are reviewed as **SQL** rather than as model diffs. A destructive statement is one line and easy to miss in a diff of a model class.

## Operational Considerations

Section 2 is the operational core: the deployment model guarantees a window in which the old application runs against the new schema, so backward compatibility is structural rather than advisory.

Section 7 is where migrations cause unplanned outages, and the operations that lock are not the ones people expect. A lock timeout is one setting and it converts a stalled migration into a failed one, which is much easier to recover from.

The most valuable practice available is testing migrations against production-like volume. Duration is the property that differs most between DEV and production, and it is the property that determines whether a migration is a deployment step or an outage.

---

## Related

- [Database standard](../02-infrastructure/database-standard.md)
- [Rollback strategy](rollback-strategy.md)
- [CD standard](cd-standard.md)
- [Release and tagging standard](../04-source-control/release-and-tagging-standard.md)
- [ADR-0010 — Portainer GitOps deployment](../../adr/0010-portainer-gitops-deployment.md)
- [Backup standard](../11-disaster-recovery/backup-standard.md)
