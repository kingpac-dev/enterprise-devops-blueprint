# Pull Request Standard

## Purpose

Defines what a pull request must contain, which checks must pass, who must review it, and how it is merged.

## Scope

Pull requests in application repositories. Contribution to **this blueprint repository** is covered by [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Audience

All developers and reviewers.

## Status

**Draft for review.** Reviewer counts, required checks, and the merge strategy are proposals requiring confirmation.

---

## 1. The Pull Request Is the Review Boundary

Every change to a protected branch goes through a pull request. This is the control that separates unreviewed work from anything that can become a release candidate — see [logical-architecture.md](../01-architecture/logical-architecture.md#3-boundaries).

Its value depends on the review being real. A pull request approved without being read satisfies the process, produces the same audit record as a genuine review, and provides none of the protection. That distinction is not enforceable by configuration, which is why sections 4 and 5 are about review quality rather than review count.

---

## 2. What a Pull Request Must Contain

| Element | Requirement |
| --- | --- |
| Title | What changes, in one line |
| Description — what | The change, in terms a reviewer can verify |
| Description — why | The reason. The diff shows what; only the author knows why |
| Ticket reference | Where one exists |
| Testing performed | What was actually run, and what was not |
| Risk and rollback | For anything touching data, configuration, or production behaviour |
| Deployment notes | Migrations, configuration changes, ordering constraints |

The testing section must be accurate. "Tested locally" when nothing was run is a false statement in a permanent record that a later investigation will rely on, and reviewers calibrate their scrutiny against it.

Deployment notes matter more than they appear. A change requiring a configuration value to exist before it deploys will fail on deployment if nobody is told, and the failure surfaces during a release rather than during review.

---

## 3. Required Checks

`TBD` — the exact set per application type. Proposal:

| Check | Blocks merge |
| --- | --- |
| Build succeeds | Yes |
| Unit tests pass | Yes |
| Lint passes | Yes |
| Coverage threshold met | `TBD` |
| SonarQube Quality Gate | Yes |
| Dependency vulnerability scan | Yes, at threshold |
| Secret scan | Yes |
| No merge conflicts | Yes |
| Review conversations resolved | Yes |

Checks fail closed. A check that cannot be evaluated — because the tool is unavailable — has not passed, consistent with [security-baseline.md](../07-security/security-baseline.md#3-principles). Treating unavailable as passing converts an outage into a silent bypass of a mandatory control.

`TBD` — coverage thresholds per application type. A threshold set above what the existing codebase achieves blocks every pull request on day one and gets removed within a week. The workable approach is a threshold on **new** code, with the existing backlog addressed separately — which requires measuring the current level before setting anything.

---

## 4. Reviewers

`TBD` — the required count. Proposal:

| Change | Approvals |
| --- | --- |
| Ordinary change | 1 |
| Change to security-relevant code, configuration, or dependencies | 1, plus security review |
| Change to the pipeline, Dockerfile, or deployment configuration | 1, plus platform review |
| Database migration | 1, plus explicit acknowledgement of the rollback limitation |
| Hotfix | 1, expedited — reviewed, not skipped |

The author does not approve their own change, and approval by someone who did not read it is not approval.

Requiring two approvals is a common instinct and often counterproductive at small team sizes: it produces two people each assuming the other read it carefully. One reviewer who is accountable is better than two who are nominal.

### Stale approvals

Approvals are dismissed when new commits are pushed. An approval applies to what was reviewed, not to the branch name.

---

## 5. What a Review Is For

A review is not a search for style violations. Automated checks handle formatting; the reviewer's attention is a scarce resource and should go where automation cannot.

| Question | Why the reviewer, not a tool |
| --- | --- |
| Does this do what the description says? | Requires understanding intent |
| Is the approach right, or does it work by accident? | Requires judgement |
| What happens on the failure path? | Failure paths are the least-tested code |
| Is anything logged, exposed, or stored that should not be? | Requires knowing what is sensitive |
| What breaks if this is deployed and the previous version rolls back? | Requires knowing the deployment model |
| Is this change reversible? | Migrations, data changes, external calls |
| Is there a test that would have caught the bug this fixes? | A fix without a test invites the same defect back |

The fifth question is specific to this delivery model and is rarely asked. Rolling back to the previous image does not roll back a database migration or an external side effect — see [environment-architecture.md](../01-architecture/environment-architecture.md#5-prod). A change that makes rollback unsafe should say so, in the pull request, before it is merged.

### Comments

Distinguish blocking from non-blocking. A reviewer who marks everything as blocking gets ignored; one who marks nothing as blocking is not reviewing.

Conventional prefixes work well: `blocking:`, `suggestion:`, `question:`, `nit:`. `TBD` — whether a convention is adopted.

---

## 6. Size

A pull request should be reviewable in one sitting.

Review quality falls sharply with size, and it falls faster than most authors expect. A 1,000-line pull request does not get reviewed ten times more carefully than a 100-line one; it gets skimmed and approved, because thorough review of it is genuinely difficult and the effort is unbounded.

Where a change is genuinely large:

- separate mechanical changes — renames, formatting, moves — into their own pull request, so the reviewer of the substantive change is not reading a diff that is mostly noise
- split by layer or by feature increment
- use a feature flag so incomplete work can merge safely

`TBD` — whether a size guideline is stated. A hard limit invites gaming; a stated expectation with reviewer discretion works better.

---

## 7. Merge Strategy

`TBD` — confirm. Proposal, which differs by branch pair for a reason:

| Merge | Strategy | Reason |
| --- | --- | --- |
| `feature/*` → `develop` | **Squash** | One commit per change; clean history; simple revert; one image per change |
| `release/*` → `main` | **Merge commit** | Preserves the individual changes in the release; `main` history shows the release boundary |
| `release/*` → `develop` | **Merge commit** | Preserves the fixes so the merge-back is visible |
| `hotfix/*` → `main` and `develop` | **Merge commit** | Same as above |

### Why squash for features but not releases

Squashing a feature branch collapses "work in progress" commits into one meaningful commit on `develop`. That is an improvement — nobody needs to see six intermediate states.

Squashing a release branch into `main` would collapse an entire release into one commit, losing the individual changes and the fixes made during UAT. `main`'s history would then say only "release 1.5" with no visibility into what it contained.

### The consequence for image identity

Squash merging creates a **new commit** on `develop`. The image built from `develop` is tagged with that new commit, which is correct — that commit is the one on the branch. But it means no commit on the feature branch corresponds to any promotable image.

This is why promotable images are built only from protected branches — see [branching-strategy.md](branching-strategy.md#7-what-builds-and-what-deploys). It is a consequence worth understanding rather than discovering.

---

## 8. Merge Requirements

Before merge:

| Requirement |
| --- |
| All required checks pass |
| Required approvals present, none stale |
| All conversations resolved |
| Branch up to date with the target, or verified compatible |
| Deployment notes captured where relevant |

After merge: delete the branch. The pipeline builds from the protected branch and, for `develop`, deploys to DEV.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — required approving review count per change type | Review boundary strength |
| `TBD` — required status checks per application type | Quality boundary |
| `TBD` — coverage thresholds, and whether they apply to new code only | Whether the gate is achievable |
| `TBD` — merge strategy confirmation | History shape, image identity |
| `TBD` — comment convention | Review clarity |
| `TBD` — size expectation | Review quality |
| `TBD` — how security-relevant changes are routed to a security reviewer | Whether that review actually happens |

The last is easy to leave undefined and then not happen. "Security review required for security-relevant changes" achieves nothing unless something identifies such a change and routes it — by path-based ownership rules, labels, or an explicit checklist item.

---

## Security Considerations

The pull request is where a security-relevant change is most cheaply caught. That depends on such changes being identified and routed, which is the open item above.

Two review questions carry disproportionate security value: what is logged or exposed, and what happens on the failure path. Both are where credentials leak and where error handling reveals internal structure, and neither is found by automated checks.

Stale approval dismissal is a small setting with real consequence. Without it, a change can be approved and then substantially rewritten before merge, carrying an approval that applies to different code.

## Operational Considerations

The mechanism that most improves review quality is size, and it is under the author's control rather than the reviewer's. Separating mechanical changes from substantive ones is the highest-value habit here.

Checks that fail closed will occasionally block merges when a tool is unavailable. That is the intended behaviour and should be understood before it happens, because the pressure to make checks advisory arrives during an outage.

---

## Related

- [Git standard](git-standard.md)
- [Branching strategy](branching-strategy.md)
- [Release and tagging standard](release-and-tagging-standard.md)
- [CI/CD standards](../05-ci-cd/)
- [Security baseline](../07-security/security-baseline.md)
- [Governance](../10-governance/)
