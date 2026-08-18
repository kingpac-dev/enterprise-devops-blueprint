# ADR-0008 — Require Manual Approval for Production Deployment

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established.

---

## Context

Deployment to production must be authorized, and the authorization must be recorded. The question is whether the gate is a human decision or an automated policy evaluation.

Continuous deployment — automated promotion once gates pass — is the stronger practice where its prerequisites exist. Those prerequisites are a test suite trusted enough that passing means the change is safe, observability good enough to detect a bad release quickly, and rollback proven enough to be automatic.

None of the three exists today. There is no test suite of known quality, no observability, and no rollback that has ever been executed.

---

## Decision

Production deployment requires explicit human approval, recorded.

```text
Release Candidate -> Quality Gate -> Security Gate -> UAT Verification -> Production Approval -> Deployment
```

| Rule | |
| --- | --- |
| Approver | `TBD` role, **not the change author** |
| Recorded | Approver, version, timestamp, change reference |
| Informed by | Release notes, including breaking changes, migrations, and rollback limitations |
| Scope | Production only. DEV and UAT deploy without approval |
| Not a substitute | Approval does not replace review, gates, or verification |

---

## Consequences

### Positive

- A person with context decides, informed by release notes, breaking changes, and rollback limitations — judgement that no current automated policy could apply.
- Creates the audit record of who authorized what, which is the join in the evidence model.
- Enforces separation of duties: the author does not approve their own change.
- Provides a deliberate pause where a release with an irreversible migration can be reconsidered.

### Negative

- **Release throughput is bounded by approver availability.** An approver on leave or unreachable delays every release, including urgent ones.
- **Approval fatigue leads to rubber-stamping.** An approver processing many releases stops reading release notes, at which point the gate records a decision without providing one. This is the failure mode to watch for, and it is invisible from the record — a rubber-stamped approval and a considered one look identical.
- **Out-of-hours releases require an out-of-hours approver**, or they wait.
- Encourages batching: if approval is friction, changes accumulate into larger releases, which are harder to diagnose when they fail — the opposite of the intended effect.
- Adds elapsed time to lead time, a metric the platform is otherwise trying to improve.

### Neutral

- The approval is a governance control, not a technical one. It can be bypassed by anyone with direct production access, which is why production access is tiered and restricted.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Full continuous deployment** | The stronger practice where its prerequisites hold. Rejected because none of the three prerequisites — trusted tests, working observability, proven rollback — currently exists. Deploying automatically on a green pipeline whose green is not yet meaningful would remove the last check without replacing it. **This is the intended destination**; see the review trigger |
| Automated policy gate (rules rather than a person) | Consistent and fast. Rejected for now: the policies that would encode the judgement — is this migration reversible, is this release notes claim accurate — are not expressible against evidence the platform currently captures |
| Approval by the change author | Removes the availability constraint. Rejected: an author approving their own change records a decision without providing independent review |
| Time-window releases (fixed days) | Predictable and reduces the availability problem. Rejected as adding scheduling friction on top of approval friction, which encourages batching further |
| Two approvers | Considered and rejected. At small team sizes, two approvers each assume the other read it carefully. One accountable approver is stronger |

---

## Security Considerations

The approval boundary separates UAT-verified releases from production, and it is the only control in the chain that applies human judgement to whether a specific change should go live.

Its integrity depends on separation of duties. Where the author can approve, the boundary is decorative. At small team sizes strict separation is sometimes impossible; where that is true, the compensating control must be documented — an undocumented compensation is an undocumented gap.

The approval record is a primary piece of audit evidence and is subject to the integrity limitation in [audit-evidence.md](../docs/10-governance/audit-evidence.md): it is held by the system that performs the deployment.

## Operational Considerations

Approver availability is a real operational dependency. It requires a designated backup, and an emergency path for changes that cannot wait — which is emergency change, with its own recording and retrospective review.

The metric to watch is **emergency-change share**. When it rises, the usual cause is not more emergencies but an approval path people are avoiding. Treat that as a defect in the process rather than as misconduct.

The second signal is time-to-approval. Growth indicates the gate has become a queue, and a queue encourages batching.

---

## Review Trigger

Move toward automated promotion when all three prerequisites hold:

1. A test suite trusted enough that passing means the change is safe.
2. Observability good enough that a bad release is detected within minutes.
3. Rollback proven by repeated, successful, automatic execution.

Also revisit if:

- Deployment frequency rises to the point where approval is the dominant component of lead time.
- Approval becomes a rubber stamp — measurable by whether approvers ever reject or question a release.
- Emergency-change share rises, indicating the normal path is being routed around.

Removing the gate before the prerequisites hold would remove a control without replacing it.

---

## References

- [Governance](../docs/10-governance/devops-governance.md)
- [Change management](../docs/10-governance/change-management.md)
- [Audit evidence](../docs/10-governance/audit-evidence.md)
- [Release and tagging standard](../docs/04-source-control/release-and-tagging-standard.md)
- [KPIs and success metrics](../docs/00-executive/kpi-and-success-metrics.md)
