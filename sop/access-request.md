# SOP — Access Request

## Trigger

Someone needs access they do not have: a new joiner, a role change, a specific investigation, or an emergency.

## Roles

| Role | Responsibility |
| --- | --- |
| Requester | States role, tier, environment, purpose, duration |
| Approver (`TBD`) | Approves or declines |
| Security owner (`TBD`) | Consulted for production tier 3 and above |
| Provisioner (`TBD`) | Grants and records |

---

## Before Requesting

**Grant the lowest tier that accomplishes the task.** Most investigation is possible at tiers 0 and 1.

| Tier | Capability | Ask yourself |
| --- | --- | --- |
| 0 | Dashboards and metrics | Is the answer visible here? |
| 1 | Logs | Is the answer in the logs? |
| 2 | Container inspection, read-only | **Note: this displays environment variables, which is where application secrets live.** Closer to credential access than to observation |
| 3 | Container modification | Every use is a manual change and must be recorded |
| 4 | Host shell | Reaches every container on the host, including other teams' services |

If the answer to a diagnostic question is not available at tier 0 or 1, that is usually a gap in observability rather than a reason to grant host access. Record it as such.

---

## Steps

### 1. Request

| Field | Required |
| --- | --- |
| Requester and their role | Yes |
| Tier | Yes |
| Environment | Yes |
| Purpose | Yes — specific, not "to investigate issues" |
| Duration | Yes |
| Ticket or incident reference | Where one exists |

### 2. Approve

| Tier | Approver |
| --- | --- |
| 0–1 | `TBD` |
| 2 | `TBD` |
| 3–4, non-production | `TBD` |
| 3–4, **production** | `TBD`, with the security owner consulted |

The approver does not approve their own request.

### 3. Provision

- [ ] Granted at the requested tier — **not by copying another person's access**
- [ ] Granted for the requested duration
- [ ] Expiry set where the platform supports it

Copying an existing person's access propagates every exception that person ever accumulated, and the copy is invisible thereafter because it looks like a normal grant. It is the most common route to excessive standing privilege.

### 4. Record

| Field |
| --- |
| Who, what tier, which environment |
| When granted |
| Why |
| Approved by which role |
| **Expiry** |

`TBD` — where access records are held.

### 5. Expire or revoke

- [ ] Access removed at expiry
- [ ] **Removal verified**

This is the step that fails. Access granted for an investigation remains after the investigation, because removing it is nobody's scheduled task. **Automatic expiry converts a discipline problem into a system behaviour** — prefer it wherever the platform offers it.

---

## Emergency Access

For a situation requiring a tier nobody holds. This path must be **pre-authorized**, because an undesigned path is improvised — and improvised access is neither recorded nor revoked.

```text
1. Invoke the pre-authorized emergency path
2. Access is granted, time-bounded, and recorded automatically
3. Act
4. Access expires automatically
5. Every use is reviewed afterwards — not sampled, every use
6. Revocation verified
```

`TBD` — the mechanism and the authorizing role.

**It must be fast.** A slow emergency path gets bypassed, which returns the organization to informal standing access — the state the tier model exists to replace.

Step 5 is what makes it sustainable. Without review, use becomes routine, and routine emergency access is standing access with extra steps.

---

## Verification

- [ ] Access works at the granted tier, and not above it
- [ ] Record complete
- [ ] Expiry set

---

## Open Items

| Item |
| --- |
| `TBD` — tier-to-role assignment per environment |
| `TBD` — approving role per tier |
| `TBD` — maximum duration per tier |
| `TBD` — request mechanism, and where records are held |
| `TBD` — emergency access mechanism and authorizing role |
| `TBD` — whether tier 0 is default for all engineers |

The last is worth deciding early. Developers who cannot see whether their service is healthy will find another way to find out, and every alternative is worse.

---

## Related

- [Production access policy](../docs/10-governance/production-access-policy.md)
- [Access control](../docs/07-security/access-control.md)
- [Access review](access-review.md)
- [Offboarding](offboarding.md)
