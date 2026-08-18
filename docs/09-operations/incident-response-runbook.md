# Runbook — Incident Response

> **This runbook has never been used.** Correct it after the first real incident.

## When to Use

A production service is not working as it should. Detected by an alert, a user report, or an observation.

## Roles

| Role | Responsibility |
| --- | --- |
| Incident lead | **Coordinates. Does not fix.** See section 2 |
| Responders | Investigate and fix |
| Service owner | Domain knowledge |
| Communicator | Stakeholder updates |

At small team sizes one person holds several roles. **Incident lead and responder should still be separated once more than one person is involved** — the coordination stops happening otherwise, and it is what prevents duplicated and conflicting work.

---

## 1. First Five Minutes

```text
1. Is production actually affected, or is this a delivery outage?
2. What changed recently?
3. Declare, or stand down
```

### Delivery outage or service outage

| Down | Production | Urgency |
| --- | --- | --- |
| Jenkins | **Running** | Serious, not an emergency |
| Harbor | **Running** | Serious — deployment *and rollback* are blocked |
| SonarQube | Running | Low |
| Observability | Running, **unmonitored** | Serious — you are blind |
| A production host | **Down** | **Emergency** |

Establishing this first prevents the response effort going to the wrong place. The dangerous case is a delivery outage that later becomes a service outage: production is running, something then goes wrong, and the ability to deploy or roll back is already gone.

### What changed

Check in this order — it is roughly the order of likelihood:

```text
1. A deployment? Check the deployment markers on the dashboard
2. A configuration change?
3. A manual change? Check change records — and ask
4. A dependency, external service, or certificate?
5. Load?
```

**A recent deployment is the most likely cause.** If one correlates, go to [rollback-runbook.md](rollback-runbook.md) before investigating further. Restore service, then diagnose.

The manual-change question needs asking out loud. A manual change is reverted at the next deployment and returns days later in an unrelated release — and the person investigating has no reason to suspect it.

---

## 2. Declare

`TBD` — severity definitions.

| Severity | Meaning | Response |
| --- | --- | --- |
| Critical | Users affected now | Immediate, any hour |
| High | Degraded, or failure imminent | Working day, escalating |
| Low | Worth knowing | Next working day |

On declaring:

- [ ] **Incident lead named**
- [ ] Communication channel opened
- [ ] Timeline started — record actions as they happen

**The incident lead coordinates and does not fix.** The most common failure of small-team incident response is everyone investigating and nobody coordinating, which produces duplicated work, conflicting changes, and a timeline reconstructed afterwards from memory.

Record actions **as they happen**. Reconstruction afterwards is unreliable, and the timeline is the input to the review.

---

## 3. Stabilize Before Diagnosing

Restore service first. Understanding can wait; users cannot.

| Fastest stabilizing action | When |
| --- | --- |
| **Roll back** | A recent deployment correlates |
| Restart the container | A crash loop or a stuck process |
| Scale or shed load | Saturation |
| Disable a feature flag | The affected path is behind one |
| Fail over a dependency | One exists |

Every stabilizing action is a **manual change**: record it, including during the incident. An unrecorded intervention is reverted at the next deployment, and the problem returns.

**Change one thing at a time.** Multiple simultaneous changes make it impossible to know which helped, and one of them may be making things worse.

---

## 4. Diagnose

| Question | Where |
| --- | --- |
| What is the symptom? | Dashboards: error rate, latency, availability |
| When did it start? | Metrics; correlate with deployment markers |
| Which service? | Service dashboards |
| What is it saying? | Logs, filtered by service and level |
| One request or all? | Trace one with its correlation identifier |
| Is a dependency failing? | Dependency health; that dependency's own signals |
| Resource exhaustion? | Memory against limit, CPU, **disk** |
| Crash looping? | Restart count |

Two checks are worth doing early because they are cheap and commonly the answer:

**Restart count.** A container in a restart loop looks running on a coarse dashboard while serving almost nothing.

**Host disk.** A full disk stops **every** container on the host, so a symptom in one service can be caused by another service's logs. Check the host, not only the service.

---

## 5. Communicate

`TBD` — audience, channel, and cadence.

| Update | Content |
| --- | --- |
| Initial | What is affected, that it is being worked, next update time |
| Periodic | Status, what has been tried, next update time |
| Resolution | What was affected, for how long, current state |

Give a **next update time** every time. Its absence is what generates the interruptions that slow the response down.

The communication channel must not depend on the systems that are down.

---

## 6. Resolve

- [ ] Service verified working — not just "the alert cleared"
- [ ] Metrics returned to normal
- [ ] Stakeholders informed
- [ ] Timeline complete
- [ ] Every manual change recorded, with a follow-up to bring it into the pipeline
- [ ] Temporary measures ticketed for removal

The last two are how an incident leaves debt. A manual fix that resolved the incident and was never recorded will be reverted at the next deployment — reintroducing the problem, disconnected from its cause.

---

## 7. Review

`TBD` — when, and who attends.

| Question | Purpose |
| --- | --- |
| What happened? | Timeline |
| **How was it detected?** | See below |
| What made it worse or slower? | Process improvements |
| What made it better? | Keep doing it |
| What would prevent recurrence? | Actions with owners |
| What would have detected it sooner? | Monitoring gaps |

**The detection question is the most valuable.** An incident found by a user report rather than by an alert is a monitoring gap with a concrete example attached — which is the most useful feedback the alerting system ever receives.

The review is **blameless**. An incident review that assigns fault produces incidents that are not reported, which is strictly worse than the incident.

Actions get owners and dates, or they do not happen.

---

## 8. Open Items

| Item |
| --- |
| `TBD` — severity definitions and response targets |
| `TBD` — on-call rotation and escalation, by role |
| `TBD` — communication channel, independent of platform availability |
| `TBD` — where timelines and reviews are recorded |
| `TBD` — review cadence and attendance |
| `TBD` — who may authorize an emergency change during an incident |

---

## Related

- [Rollback runbook](rollback-runbook.md)
- [Container troubleshooting runbook](container-troubleshooting-runbook.md)
- [Observability stack recovery](../../runbooks/observability-stack-recovery.md)
- [Change management](../10-governance/change-management.md)
- [Alerting standard](../08-observability/alerting-standard.md)
