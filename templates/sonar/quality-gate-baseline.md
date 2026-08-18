# Quality Gate Baseline

## Purpose

Recommended Quality Gate conditions, the reasoning behind each, and the sequence for introducing a gate to a codebase that has never had one.

## Status

**Proposal requiring confirmation.** Thresholds below are starting points, not measurements. `TBD` throughout until a baseline exists.

---

## 1. Gate New Code, Not the Whole Codebase

This is the decision that determines whether a gate survives its first week.

A gate applied to the whole codebase fails on day one for every existing issue, blocks every pull request regardless of what the change contains, and is removed within days — after which nobody proposes one again for a long time.

A gate applied to **new code** — code added or changed in this change set — passes immediately for a clean change and blocks only what the author actually wrote. The existing backlog is addressed on a schedule, separately, as its own work.

| Approach | Day-one effect | Outcome |
| --- | --- | --- |
| Whole codebase | Everything blocked | Gate removed |
| **New code** | Only genuinely new problems blocked | Gate survives, and quality improves at the edge |

The new-code approach depends on SonarQube being able to identify new code, which requires branch or pull-request analysis. **The Community edition does not provide it.** That constraint must be settled before the gate is designed — see [ADR-0003](../../adr/0003-use-sonarqube-for-code-quality.md).

---

## 2. Proposed Conditions

All apply to **new code**.

| Condition | Proposed | Reasoning |
| --- | --- | --- |
| Coverage on new code | `TBD` — 70% or 80% | Below roughly 60%, the number stops indicating anything. Above roughly 85%, effort goes into testing trivial paths |
| Duplicated lines on new code | `TBD` — under 3% | Copy-paste is the cheapest defect multiplier available |
| Maintainability rating on new code | A | Sonar's own scale; A on new code is achievable |
| Reliability rating on new code | A | New code should introduce no bug-rated issues |
| Security rating on new code | A | New code should introduce no vulnerability-rated issues |
| Security hotspots reviewed | 100% | Reviewed, not necessarily fixed — a hotspot is a "look at this", and the requirement is that someone looked |
| Blocker and critical issues on new code | 0 | |

The security hotspot condition is the one most often misunderstood. A hotspot is not a defect; it is a construct that requires human judgement. Requiring 100% *reviewed* means the judgement was applied. Requiring 100% *resolved* would push people to dismiss rather than to think.

---

## 3. What Not to Gate On

| Not gated | Why |
| --- | --- |
| Overall coverage percentage | Punishes new work for the state of old code, and is the metric most easily gamed by testing trivial paths |
| Total issue count | An aggregate that changes with codebase size rather than with quality |
| Cognitive complexity as a hard block | A genuine signal and a poor gate — some code is legitimately complex, and the exceptions become routine |
| Lines of code | Not a quality property |

---

## 4. Introducing a Gate

```text
1. Enable analysis with NO gate. Measure for a period
2. Read the baseline: current coverage, duplication, and issue counts
3. Set new-code conditions the team can meet today
4. Enable the gate as advisory — report, do not block
5. Observe: what would have been blocked, and was it right?
6. Enable blocking
7. Tighten gradually, on evidence
8. Address the existing backlog as separate, scheduled work
```

Steps 4 and 5 exist so that enabling blocking does not stop delivery on day one for reasons nobody predicted. Step 6 is when the gate begins to provide anything — a gate left permanently advisory is a report, and reports about code quality are not read.

Step 2 cannot be skipped. Thresholds set from a general recommendation rather than a measurement produce either a gate nothing passes or a gate nothing fails.

---

## 5. Failure Behaviour

| Situation | Required |
| --- | --- |
| Gate fails | Pipeline stops. No image is published |
| SonarQube unavailable | **Pipeline fails.** An unevaluated gate is not a pass |
| Gate result delayed | Pipeline waits, up to a timeout, then fails |

The second is the one argued about, and the argument arrives within hours of the first outage. Treating unavailable as passing converts a tool outage into a silent bypass of a mandatory control.

Where a prolonged outage genuinely requires proceeding, that is a recorded, time-bounded exception with an approver — not a configuration change made quietly. See [exception-management.md](../../docs/10-governance/exception-management.md).

---

## 6. Per Application Type

`TBD` — whether thresholds differ.

| Type | Consideration |
| --- | --- |
| .NET API | Business logic; coverage is meaningful and achievable |
| .NET Worker | Same, with the caveat that message-handling paths need deliberate test design |
| Angular | Component tests are often shallow. A high coverage number can coexist with untested behaviour, so read it alongside the tests rather than as a substitute for reading them |

The Angular caveat generalizes: coverage measures which lines executed, not whether anything was asserted about them.

---

## 7. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — SonarQube edition, which determines whether new-code analysis is available | The entire approach in section 1 |
| `TBD` — measured baseline per repository | Every threshold |
| `TBD` — coverage threshold per application type | Section 2 |
| `TBD` — timeout when waiting for a gate result | Failure behaviour |
| `TBD` — who owns the gate definition, and whether teams may vary it | Consistency versus fit |

---

## Related

- [ADR-0003 — SonarQube](../../adr/0003-use-sonarqube-for-code-quality.md)
- [Pull request standard](../../docs/04-source-control/pull-request-standard.md)
- [CI/CD standards](../../docs/05-ci-cd/)
- [Security baseline](../../docs/07-security/security-baseline.md)
