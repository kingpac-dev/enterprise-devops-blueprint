# KPIs and Success Metrics

## Purpose

Defines the metrics used to judge whether the delivery platform is working, the engineering outcome each is meant to drive, and how each can be gamed.

## Audience

Engineering management, platform owners, and service owners.

## Status

**Draft for review.** No metric is currently collected. No baseline exists.

---

## 1. How to Read This

Every metric below states three things: what it measures, **the engineering outcome it is meant to drive**, and how it can be improved without improving anything.

The third is included deliberately. A metric with a target and no stated failure mode will eventually be optimized directly, and the optimization is usually easier than the improvement. Naming the shortcut in advance makes it visible when it happens.

Targets are `TBD` throughout, and should stay that way until a baseline exists. A target set without a baseline is a guess that people then work toward.

---

## 2. Delivery Metrics

### Deployment frequency

How often a service reaches production.

**Outcome:** smaller, more frequent changes. A large release is a large diagnostic surface; frequent small releases fail less severely and are faster to attribute.

**Gaming:** deploying trivial changes to raise the count. Read alongside change failure rate — frequency that rises while failure rate holds is real; frequency that rises while failure rate rises is churn.

`TBD` — target, per service class.

### Lead time for changes

Commit merged to running in production.

**Outcome:** a short, unobstructed path from decision to production. Long lead time usually indicates queueing — waiting for approval, for a release window, or for a manual step — rather than slow engineering.

**Gaming:** measuring from release-branch creation instead of from commit, which excludes the wait that constitutes most of the delay.

`TBD` — target, and the exact measurement points.

### Change failure rate

Share of production deployments causing degradation or requiring rollback or hotfix.

**Outcome:** releases that work. This is the metric the quality and security gates exist to move.

**Gaming:** narrowing the definition of failure. A degradation quietly fixed forward is a failure; excluding it makes the number better and the platform no safer. Definition is `TBD` and should be written down before measurement starts, not after the first bad month.

`TBD` — target.

### Mean time to recovery

Detection of a production problem to restored service.

**Outcome:** recovery that is designed rather than improvised. This is where rollback capability and observability show up as a number.

**Gaming:** measuring from *diagnosis* rather than from detection, or from detection rather than from onset. The interval that matters to users starts when the problem starts.

`TBD` — target, and the definition of the start point.

---

## 3. Pipeline Metrics

### Pipeline success rate

Share of pipeline executions completing successfully.

**Outcome:** a pipeline people trust. A pipeline that fails often for reasons unrelated to the change trains people to re-run rather than investigate — and the re-run habit is how a real failure gets dismissed.

**Gaming:** removing or loosening checks. Read alongside change failure rate: a success rate that rises while change failure rate rises means the gates stopped catching things.

`TBD` — target.

### Pipeline duration

Commit to artifact published.

**Outcome:** feedback fast enough to act on. Beyond roughly ten minutes, developers context-switch away and return later, which costs more than the pipeline time itself.

**Gaming:** removing tests or scans. This one is worth watching specifically, because it is the most immediately effective way to improve the number and the most damaging.

`TBD` — target.

### Failed deployment count

Deployments that did not complete successfully.

**Outcome:** a reliable deployment mechanism. Distinguishes "the change was bad" from "deployment itself is unreliable" — two problems with different fixes that a single failure count conflates.

`TBD` — target.

### Rollback count

Rollbacks executed.

**Outcome:** rollback that works when needed. This metric is **not** minimized. A rollback is the control functioning; zero rollbacks over a long period more likely means rollback is not being used when it should be, or is not usable.

Read alongside change failure rate: failures rising while rollbacks stay at zero is the signal to investigate.

---

## 4. Security Metrics

### Vulnerability remediation time

Disclosure or detection to remediation in production, by severity.

**Outcome:** vulnerabilities are fixed rather than accumulated.

**Gaming:** granting an exception and considering it closed. Exceptions must be tracked separately — see below.

`TBD` — target per severity, aligned with the SLAs in the vulnerability management standard.

### Active exceptions, and their age

Count and age of exceptions to standards.

**Outcome:** deviations stay temporary and visible.

This is the most informative security metric available. A stable finding count with a rising exception count means the exception process has become the way vulnerabilities are recorded rather than fixed — the metrics improve while exposure does not.

**Any expired-but-still-in-effect exception is a control failure.** That count should be zero and should alert.

`TBD` — targets.

### Control coverage

Share of repositories with each mandatory control enforced.

**Outcome:** the baseline actually applies, rather than applying to whoever adopted it.

Currently zero for every control — see [security-baseline.md](../07-security/security-baseline.md#2-control-catalogue).

`TBD` — targets.

---

## 5. Reliability Metrics

### Service availability

Share of time a service meets its availability definition.

**Outcome:** the service is usable. Definition is `TBD` and matters more than the number — availability measured by whether the process is running is not availability as users experience it.

**Gaming:** measuring liveness rather than usefulness. A container in a restart loop is running.

`TBD` — target per service class.

### Restart count

Container restarts per service.

**Outcome:** crash loops are visible. A restarting container can appear healthy on a coarse dashboard while serving almost nothing.

### Backup restore test results

Whether a restore has been successfully performed, and when.

**Outcome:** recovery capability that is demonstrated rather than assumed. **A backup is not operationally reliable until a restore has been demonstrated** — until then, recovery capability is unproven and must be described that way.

`TBD` — required test frequency.

---

## 6. Governance Metrics

### Emergency change share

Emergency changes as a proportion of all changes.

**Outcome:** the normal change path is usable.

This is the leading indicator for the whole governance model. When it rises, the cause is usually a normal path people are avoiding rather than more emergencies — a process defect, not misconduct.

`TBD` — threshold that triggers investigation.

### Changes without a record

Production changes with no change record.

**Outcome:** the audit trail describes reality. Any non-zero value means the record and the runtime have diverged, silently.

Target: zero.

---

## 7. Metrics Deliberately Not Used

| Not used | Why |
| --- | --- |
| Lines of code, commit count | Measures activity, not outcome; rewards verbosity |
| Story points delivered | Not comparable between teams; inflates under pressure |
| Test count | Rewards writing tests, not testing |
| Code coverage as a headline target | Useful as a gate on new code; as a headline it rewards testing trivial paths |
| Individual developer metrics | Delivery is a system property. Individual metrics damage the collaboration the system depends on |

The last is the important one. Every metric here is a property of the **system**, and attributing them to individuals converts a diagnostic tool into a performance-management one — after which the numbers stop being honest and stop being useful for their original purpose.

---

## 8. Measurement Discipline

| Rule | Reason |
| --- | --- |
| Capture the baseline **before** implementation | Otherwise improvement cannot be demonstrated, only asserted |
| Define each metric precisely before collecting it | An unwritten definition drifts toward whatever produces a good number |
| Read metrics in pairs | Frequency with failure rate; success rate with failure rate; failures with rollbacks |
| Review trends, not points | Single readings are noise |
| Publish the definition alongside the number | An unexplained number invites its own interpretation |

The baseline point is time-critical. It can only be captured before the platform exists, and that window is currently open.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — baseline measurement of current delivery performance | Whether any improvement claim is supportable |
| `TBD` — precise definition of each metric | Whether numbers are comparable over time |
| `TBD` — targets, set after the baseline | Meaningful goals |
| `TBD` — who collects, publishes, and reviews | Whether measurement happens |
| `TBD` — availability definition per service class | The availability metric |
| `TBD` — change failure definition | The change failure metric |

---

## Related

- [Executive summary](executive-summary.md)
- [Business value](business-value.md)
- [DevOps roadmap](devops-roadmap.md)
- [Risk register](risk-register.md)
- [Security baseline](../07-security/security-baseline.md)
- [Governance](../10-governance/)
