# 09 — Operations

## Purpose

Step-by-step operational procedures for deploying, recovering, and troubleshooting production services.

## Scope

Runbooks executed by operators during deployment, failure, and maintenance. Standards that define *why* a procedure exists live in the corresponding standard area.

## Audience

Operations, SRE, and on-call engineers.

## Status

**Draft for review.** All five are written. **None has ever been executed.** The deployment and rollback execution steps depend on [ADR-0009](../../adr/0009-deployment-mechanism-to-runtime-hosts.md) and are written per option.

---

## Runbooks

| File | Intent | Status |
| --- | --- | --- |
| [production-deployment-runbook.md](production-deployment-runbook.md) | Preconditions, artifact verification, deploy, verify, observe, close | Draft |
| [rollback-runbook.md](rollback-runbook.md) | **Step 0: is rollback available?** Then execute, verify recovery, record | Draft |
| [incident-response-runbook.md](incident-response-runbook.md) | First five minutes, declare, stabilize, diagnose, communicate, review | Draft |
| [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md) | By symptom, from lowest access tier upward | Draft |
| [certificate-renewal-runbook.md](certificate-renewal-runbook.md) | Renewal, verification with real clients, expired certificates, key compromise | Draft |

## Written for the Person Who Did Not Write Them

Each runbook is designed to be executed under pressure by someone unfamiliar with it. Three consequences shape them:

**Decision points come first.** [rollback-runbook.md](rollback-runbook.md) opens with "is rollback available?" — thirty seconds that prevent a failed rollback attempt during an outage.

**Stabilize before diagnosing.** Restore service, then understand. If a recent deployment correlates, roll back before investigating.

**Start at the lowest access tier.** [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md) reaches the end of section 4 on dashboards and logs alone. If the answer is not available there, that is usually an observability gap rather than a reason to escalate access.

## Findings Worth Reviewing First

| Finding | Where |
| --- | --- |
| **Exit code 137 is the memory limit**, and the application logs nothing — it was killed without warning. The record is on the **host**, not in the container | [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md#2-not-running) |
| **Never run `docker system prune -a` on a runtime host.** It removes images not currently in use — including the previous known-good image, which is the rollback target. One command destroys rollback capability, executed while fixing an outage | [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md#6-every-container-on-the-host) |
| **A restart storm caused by a liveness check that queries a dependency.** If restarts began when a dependency slowed rather than at a deployment, suspect the health check itself | [container-troubleshooting-runbook.md](container-troubleshooting-runbook.md#3-restarting-repeatedly) |
| **An expired Jenkins webhook certificate fails silently.** GitHub's delivery fails, nothing in the platform reports it, and builds simply stop being triggered — which looks like nobody pushing | [certificate-renewal-runbook.md](certificate-renewal-runbook.md#2-certificate-inventory) |
| **Verify a renewed certificate with the real consumer.** `openssl s_client` proves the certificate is served, not that clients accept it. For Harbor that means a `docker pull` from a runtime host | [certificate-renewal-runbook.md](certificate-renewal-runbook.md#3-renewal) |
| **The incident lead coordinates and does not fix.** The common failure of small-team response is everyone investigating and nobody coordinating | [incident-response-runbook.md](incident-response-runbook.md#2-declare) |
| **"How was it detected?" is the most valuable review question.** An incident found by a user report rather than an alert is a monitoring gap with a concrete example attached | [incident-response-runbook.md](incident-response-runbook.md#7-review) |

---

## Runbook Requirements

Each runbook must state:

- when to use it and when not to
- preconditions and required access
- exact steps in order
- verification after each significant step
- failure branches, including what to do when a step fails
- rollback or abort path
- evidence to record
- escalation path and owner role

Runbooks are written to be executed under pressure by someone who did not write them.

---

## Rollback Sequence

```text
1. Record the current known-good version
2. Deploy the requested immutable image
3. Execute health checks
4. Execute smoke tests where applicable
5. Restore the previous version on failure, where technically safe
6. Verify recovery
7. Record failure evidence
8. Notify responsible engineers
```

Database migrations may make rollback unsafe or impossible. Never promise automatic rollback for irreversible database changes.

---

## Open Items

- `TBD` — on-call rotation and escalation contacts (roles, not names)
- `TBD` — incident severity definitions
- `TBD` — where deployment evidence is stored
- `TBD` — smoke-test definition per application type

---

## Related

- [Documentation index](../README.md)
- [CI/CD rollback strategy](../05-ci-cd/)
- [Observability](../08-observability/)
- [Disaster recovery](../11-disaster-recovery/)
- [Runbooks directory](../../runbooks/)
- [Standard operating procedures](../../sop/)
