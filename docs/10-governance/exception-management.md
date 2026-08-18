# Exception Management

## Purpose

Defines how a deviation from a standard is requested, approved, time-bounded, recorded, and closed.

## Scope

Exceptions to any standard in this repository. Decision rights are in [devops-governance.md](devops-governance.md).

## Audience

Anyone requesting an exception, anyone approving one, and standard owners.

## Status

**Draft for review.** Approval authority, maximum durations, and the register location are undecided.

---

## 1. Why Exceptions Exist

Standards are written against the general case. Reality produces cases they did not anticipate, and a standard with no exception path forces one of two outcomes:

- work stops, because compliance is impossible
- the standard is violated silently, because work must proceed

The second is the common one, and it is worse than a recorded exception: the deviation exists either way, and in one case the organization knows about it.

An exception process makes deviation visible, bounded, and reviewable. It exists to surface the gap, not to legitimize it.

---

## 2. What Requires an Exception

| Situation | Exception required |
| --- | --- |
| A mandatory control cannot be met | Yes |
| A vulnerability above threshold must be accepted temporarily | Yes |
| A required check must be bypassed | Yes |
| A standard's requirement does not fit a specific case | Yes |
| A recommendation is not followed | No — record the reason in the pull request |
| A standard does not address the situation at all | No — that is a gap; raise it against the standard |

The last row matters. Where a standard is silent, the answer is to improve the standard, not to grant an exception to something it never said. Exceptions to unwritten rules produce a register full of entries nobody can evaluate.

---

## 3. What an Exception Records

Every exception, without exception:

| Field | Requirement |
| --- | --- |
| Identifier | Unique |
| Standard and requirement | Which specific requirement, not "the security standard" |
| Scope | The specific repository, image, service, or environment — never a blanket rule |
| Justification | Why it cannot be met now |
| Risk | What becomes possible because of this |
| Compensating control | What reduces the risk meanwhile |
| Owner | Role responsible for closing it |
| Approver | Role that granted it, and when |
| **Expiry** | A date. Required |
| Remediation plan | What closes it, and roughly when |

Two fields carry most of the weight.

**Scope.** A narrowly scoped exception describes a known gap. A broad one — "this team is exempt from container scanning" — silently disables a control for everything in its path, including things added later that nobody assessed.

**Expiry.** See section 5.

---

## 4. Approval

| Exception to | Approved by |
| --- | --- |
| A security standard | Security owner |
| Vulnerability severity threshold | Security owner |
| An architecture decision | Platform owner |
| Any other standard | That standard's owner |
| A production control | `TBD` — likely security owner plus management |

**The requester never approves their own exception.** Where they can, the exception process is a self-service bypass with paperwork.

`TBD` — all authorities, and whether high-risk exceptions need a second approver.

---

## 5. Expiry Is the Mechanism

**An expired exception is a control failure, not a default extension.**

This is the load-bearing sentence in this document. Without enforced expiry, exceptions become permanent by inaction — nobody decides to make them permanent, and nobody revisits them, so they simply persist.

Expiry must have effect. If the control blocks again at expiry, the exception is real and bounded. If expiry is a date in a register that nothing enforces, it is a comment.

| Enforcement | Strength |
| --- | --- |
| The control blocks automatically at expiry | Works regardless of discipline |
| Expiry alerts the owner and the approver | Depends on someone acting |
| Expiry recorded in a register reviewed periodically | Depends on the review happening |
| Expiry recorded and nothing else | Not enforcement |

`TBD` — which is implemented per exception type. `.trivyignore` entries are the clearest case: the file has no concept of expiry, so an entry without external enforcement is permanent by construction — see [vulnerability-management.md](../07-security/vulnerability-management.md#7-exceptions).

### At expiry

```text
1. The control takes effect again
2. The owner either remediates, or requests renewal
3. Renewal is a new decision with fresh justification — not a rubber stamp
4. Repeated renewal is escalated: the standard may be wrong, or the risk is being accepted permanently
```

Step 4 is the useful part. An exception renewed three times is telling you something: either the standard does not fit reality and should change, or the organization has accepted this risk permanently and should say so through the risk register rather than through a rolling exception.

---

## 6. Duration

`TBD` — maximum durations. Proposal:

| Risk | Maximum |
| --- | --- |
| Low | `TBD` |
| Medium | `TBD` |
| High | `TBD` — short, with a firm remediation plan |
| Critical | Not granted without management risk acceptance |

A maximum matters more than the specific numbers. Without one, a reasonable-sounding "until the next major refactor" becomes indefinite, and the exception outlives everyone who understood it.

---

## 7. The Register

All exceptions live in one register.

`TBD` — its location. Requirements: visible to those who need it, hard to bypass, and reviewed on a schedule.

Scattered exceptions — some in `.trivyignore`, some in pull request comments, some in a wiki page, some understood but unwritten — cannot be reviewed, and their total is unknown. That total is the number that matters: any individual exception may be reasonable while the aggregate describes a control set that is no longer operating.

### Review

`TBD` — frequency. At each review:

| Question | Signal |
| --- | --- |
| How many are active? | Growth means the standards do not fit reality |
| How old is the oldest? | Age indicates remediation is not happening |
| Any expired but still in effect? | Any non-zero value is a control failure |
| Any renewed more than twice? | Escalate — see section 5 |
| Any granted without an approver? | Process failure |
| Which standard has the most? | That standard is probably wrong |

The last question is the constructive one. A standard with many exceptions is usually a standard that does not fit how work is actually done, and rewriting it is more valuable than processing more exceptions against it.

---

## 8. What Cannot Be Excepted

`TBD` — confirm. Proposal: some requirements have no exception path, because the consequence is unbounded or irreversible.

| Requirement | Reason |
| --- | --- |
| No real secrets in Git | The exposure is permanent and retroactive |
| No shared credentials across environments | Collapses the environment boundary entirely |
| Production deployment must be recorded | Without it the audit trail is fiction |
| Production images must be immutable | Retroactively invalidates records already written |

The common property is that violating them damages records or boundaries **retroactively** — the harm is not bounded by the exception's duration, so a time-bounded exception does not bound it.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — approval authority per exception type | Whether exceptions are controlled |
| `TBD` — maximum duration by risk level | Whether exceptions end |
| `TBD` — register location and format | Whether the total is knowable |
| `TBD` — enforcement mechanism per exception type | Whether expiry has effect |
| `TBD` — review frequency and who performs it | Whether drift is caught |
| `TBD` — the no-exception list | Where the hard limits are |
| `TBD` — escalation path for repeatedly renewed exceptions | Standards that do not fit |

---

## Security Considerations

The exception process is the documented way to weaken a control. Its integrity rests on three things: the requester cannot approve, the scope is narrow, and expiry has effect. Remove any one and it becomes a bypass mechanism that produces a record.

Aggregate exception count is a security metric in its own right. Individually reasonable exceptions can sum to a control set that no longer operates, and only a single register makes that visible.

## Operational Considerations

The realistic failure is not abuse. It is accumulation: exceptions granted in good faith, remediation deprioritized against delivery work, expiry unenforced, and nobody ever deciding to make them permanent.

Automatic enforcement at expiry is what prevents it, because it makes the exception's end a system behaviour rather than a task competing for attention.

---

## Related

- [DevOps governance](devops-governance.md)
- [Change management](change-management.md)
- [Audit evidence](audit-evidence.md)
- [Vulnerability management](../07-security/vulnerability-management.md)
- [Security baseline](../07-security/security-baseline.md)
- [Executive risk register](../00-executive/)
