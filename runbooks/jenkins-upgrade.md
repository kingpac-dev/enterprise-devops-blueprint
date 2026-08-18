# Runbook — Jenkins Upgrade

> **This runbook has never been executed.** Verify against the installed Jenkins version before relying on it.

## When to Use

Upgrading the Jenkins controller, its plugins, or its agents.

An upgrade is a **normal change** under [change-management.md](../docs/10-governance/change-management.md).

## Preconditions

- [ ] Change approved
- [ ] **Backup taken and verified readable** — [jenkins-backup-and-restore.md](jenkins-backup-and-restore.md)
- [ ] Window agreed, not during a release window
- [ ] Abort criteria agreed **before** starting

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Change approver (`TBD`) | Approves |
| Application teams | Notified — delivery stops during the window |

---

## 1. Plan

```text
1. Record current versions: Jenkins core, every plugin, agent versions
2. Read the upgrade notes for BREAKING changes between the two versions
3. Identify plugins that will need upgrading with core, and any that are
   no longer maintained
4. Estimate duration; agree the abort point
5. Announce the window
```

Step 3 is where upgrades go wrong. A plugin that stops working after a core upgrade can break a pipeline stage in a way that looks like an application failure — and the plugin ecosystem is where Jenkins's capability comes from and where its fragility lives.

Step 1's version record is what makes "what changed" answerable afterwards. Without it, diagnosing a post-upgrade problem starts by reconstructing what the previous state was.

---

## 2. Execute

```text
1. Confirm no build is running; disable new builds
2. Take a fresh backup — see preconditions
3. Upgrade the controller
4. Start; watch the startup log for plugin and configuration errors
5. Upgrade plugins
6. Restart if required; watch the log again
7. Upgrade agents if required
8. Re-enable builds
```

Step 2 repeats a precondition deliberately. The backup taken yesterday does not include today's configuration change.

---

## 3. Verify — Functionally

Jenkins starting is not verification.

- [ ] Web interface loads with no startup errors
- [ ] All jobs are present
- [ ] Agents connect, at the expected versions and with the expected tooling
- [ ] **A build runs to completion**
- [ ] **A credential is used successfully**
- [ ] The Quality Gate step still functions — the SonarQube plugin is a common casualty
- [ ] An image publishes to Harbor
- [ ] Build history and logs are intact
- [ ] **The backup still succeeds afterwards**

The last is the check that is almost always omitted and the one with the longest-delayed consequence. Backups fail silently after upgrades more often than at any other time: a new version changes a path or a format, and the job keeps succeeding against the old assumption. The failure is discovered at the next restore attempt, which may be a real one.

Schedule a [restore test](../sop/restore-test.md) after the upgrade, not only a backup run.

---

## 4. Rollback

| Situation | Action |
| --- | --- |
| Controller fails to start | Restore from backup per [jenkins-backup-and-restore.md](jenkins-backup-and-restore.md) |
| Starts, plugin errors | Downgrade the affected plugins first; a full restore is the fallback |
| Starts, jobs fail | Diagnose within the window; abort to a restore at the agreed abort point |
| Beyond the abort point | Restore. Do not continue diagnosing inside a window that has overrun |

The last row is why the abort criteria are agreed in advance. Under time pressure the instinct is to keep trying — and each additional attempt makes the eventual restore start from a less well-understood state.

---

## 5. Close

- [ ] Teams notified
- [ ] Change record completed with the outcome
- [ ] New versions recorded
- [ ] **Post-upgrade restore test scheduled**
- [ ] Any correction to this runbook committed

---

## 6. Open Items

| Item |
| --- |
| `TBD` — upgrade cadence |
| `TBD` — plugin inventory and its review process |
| `TBD` — whether agents upgrade automatically |
| `TBD` — expected window duration, from a measured upgrade |
| `TBD` — whether controller configuration as code would make this a rebuild rather than an upgrade |

The last is worth considering. With configuration as code, an upgrade becomes provisioning a new controller and pointing it at the same configuration — which is testable in advance in a way an in-place upgrade is not.

---

## Related

- [Jenkins backup and restore](jenkins-backup-and-restore.md)
- [Scheduled maintenance](../sop/scheduled-maintenance.md)
- [Change management](../docs/10-governance/change-management.md)
- [Restore test](../sop/restore-test.md)
