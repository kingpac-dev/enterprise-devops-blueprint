# Production Access Policy

## Purpose

Defines what production access means, who may hold each level of it, how it is requested and recorded, and how emergency access works.

## Scope

Access to production systems: runtime hosts, containers, data, logs, and operational tooling. The platform-wide role model is in [access-control.md](../07-security/access-control.md); change execution is in [change-management.md](change-management.md).

## Audience

Platform engineers, operators, security, and whoever approves access requests.

## Status

**Draft for review.** Tier assignments and the approving role are undecided.

---

## 1. Production Access Is Not One Thing

Most access policies treat production access as binary: someone has it or does not. That framing forces a bad choice — grant broadly so incidents can be handled, or grant narrowly and watch people work around it.

Access is better modelled as tiers, because the risk differs by an order of magnitude between reading a dashboard and holding a host shell.

| Tier | Capability | Risk | Breadth |
| --- | --- | --- | --- |
| 0 | Dashboards and metrics | Aggregate operational data only | Broad |
| 1 | Logs | Whatever the logging standard failed to exclude | Narrower |
| 2 | Container inspection — read-only | Configuration, environment variables, state | Narrow |
| 3 | Container modification — restart, stop, recreate | Service availability; manual drift | Restricted |
| 4 | Host shell | Everything on the host, including other services | Most restricted |

Tier 0 should be broad. Developers who cannot see whether their service is healthy will find another way to find out, and every alternative is worse.

Tier 2 is more sensitive than it looks. Container inspection displays environment variables, which is where application secrets live under the current secret mechanism — see [docker-compose-standard.md](../06-container/docker-compose-standard.md#4-environment-values-and-secrets). Tier 2 is therefore closer to credential access than to observation.

`TBD` — which role holds which tier, and per environment.

---

## 2. Principles

**Access is granted for a purpose, not as a status.** Seniority does not confer production access.

**Least privilege by tier.** Grant the lowest tier that accomplishes the task. Most investigation is possible at tiers 0 and 1.

**Time-bounded where the platform supports it.** Standing access accumulates; expiring access forces the question to be re-answered.

**Recorded.** Who, what tier, when, why, approved by which role.

**Separate from deployment.** Production access is for investigation and approved operational tasks. Deploying is the pipeline's job — see [change-management.md](change-management.md#5-manual-changes).

---

## 3. Tier Detail

### Tier 0 — Dashboards and metrics

Aggregate operational data. No personal data, no credentials, no request content.

Grant to: developers, platform engineers, operators, service owners, management. `TBD` — whether it is default for all engineers.

### Tier 1 — Logs

Log content is variable-sensitivity by nature. The logging standard prohibits credentials and unnecessary personal data — see [logging-standard.md](../08-observability/logging-standard.md#5-what-must-never-be-logged) — but that prohibition is a control that can fail, and log access is where its failures become exposure.

Grant to: service owners for their services, platform engineers, operators. `TBD` — whether access is scoped per service.

### Tier 2 — Container inspection

Read-only inspection through Portainer or equivalent. Reveals configuration and environment variables.

Grant to: platform engineers, operators. `TBD` — whether service owners hold it for their own services.

### Tier 3 — Container modification

Restarting, stopping, or recreating a container. This changes production, so every use is a manual change under [change-management.md](change-management.md#5-manual-changes) and must be recorded — including during an incident.

Grant to: platform engineers, operators. `TBD`.

Note what tier 3 does *not* include: deploying a new version. That is the pipeline's function, and permitting it here reopens the ungoverned deployment path the whole model exists to close.

### Tier 4 — Host shell

Full access to the host and everything running on it, including services belonging to other teams.

Grant to: `TBD` — most restricted, and ideally through the emergency path in section 5 rather than as standing access.

Host shell access is the tier where the blast radius exceeds the requester's own service. A shell on a host running four services grants access to all four.

---

## 4. Requesting Access

```text
1. Request states role, tier, environment, purpose, and duration
2. Approval by TBD role; security consulted for tier 3 and above
3. Grant at the requested tier, for the requested duration
4. Record: who, tier, when, why, approved by which role, expiry
5. Expire or revoke; verify removal
```

Step 5 is the one that fails. Access granted for an investigation remains after the investigation, because removing it is nobody's scheduled task. Automatic expiry converts that from a discipline problem into a system behaviour.

`TBD` — the approving role, the request mechanism, and the maximum duration per tier.

---

## 5. Emergency Access

Situations will arise requiring a tier nobody holds. That path must be designed, because an undesigned path is improvised — and improvised access is neither recorded nor revoked.

| Requirement | Detail |
| --- | --- |
| Pre-authorized | Defined before it is needed, not negotiated during an incident |
| Fast | Slow enough to be an obstacle and it will be bypassed |
| Time-bounded | Expires automatically, `TBD` duration |
| Recorded automatically | Who, when, what tier, which incident |
| Reviewed after every use | Not sampled — every use |
| Explicitly revoked and verified | |

The review is what makes emergency access sustainable. Without it, use becomes routine, and routine emergency access is standing access with extra steps.

`TBD` — the mechanism and the authorizing role.

---

## 6. Session Recording

`TBD` — whether tier 3 and 4 sessions are recorded.

Recording provides an account of what was actually done, which change records depend on people to supply accurately. It also captures whatever appears on screen during the session, which will include credentials and production data.

If adopted: recordings are themselves sensitive, need their own access control and retention, and their existence must be disclosed to those recorded.

This is a genuine trade-off between accountability and both privacy and new exposure. It should be decided explicitly rather than defaulted either way.

---

## 7. Review

`TBD` — frequency. At each review:

| Question | Action |
| --- | --- |
| Does every holder still need this tier? | Revoke where not |
| Has anyone changed role or left? | Revoke; see [access-control.md](../07-security/access-control.md#5-granting-changing-and-removing-access) |
| Was any emergency access left in place? | Revoke; investigate why |
| Is any tier held by more people than the work requires? | Reduce |
| Did anyone use tier 3 or 4 without a change record? | Investigate |

The last question is the one that finds the gap between policy and practice.

---

## 8. Data Access

Access to production **data** is distinct from access to production systems and is not covered here.

Reading a database directly, exporting records, or querying customer data is a data-protection matter with its own legal and regulatory considerations. It must not be granted implicitly by holding tier 4.

`TBD` — the production data access policy, its owner, and its relationship to this document. Until it exists, tier 4 grants can confer data access without anyone having decided to allow it.

---

## 9. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — tier-to-role assignment per environment | Every access decision |
| `TBD` — approving role for access requests | Whether the process functions |
| `TBD` — maximum duration per tier | Standing access accumulation |
| `TBD` — emergency access mechanism and authorizing role | Incident response |
| `TBD` — whether tier 3 and 4 sessions are recorded | Accountability versus exposure |
| `TBD` — review frequency and who performs it | Whether review happens |
| `TBD` — production data access policy | Data protection |
| `TBD` — whether tier 0 is default for all engineers | Practical usability |

---

## Security Considerations

Tier 2 is the sleeper in this policy. Container inspection is intuitively "read-only and harmless", and it displays environment variables — which under the current secret mechanism is where application credentials are. Treat tier 2 as credential access when assigning it, and note that adopting file-based secrets would materially reduce this exposure.

Tier 4 blast radius exceeds the requester's service. A host shell reaches every container on the host, which is a boundary the tier model makes visible and a binary access model hides.

Emergency access without automatic expiry becomes standing access. That is the single most likely failure of this policy.

## Operational Considerations

Restricting production access has a real cost in incident response time, paid at the worst moment. That cost is why tier 0 should be broad and why the emergency path must be fast — a slow emergency path is one people work around, which returns the organization to informal standing access.

The tier model's practical value is that it makes "grant the lowest tier that works" a possible instruction. Under a binary model, the only available answers are all or nothing, and the pressure of incidents pushes consistently toward all.

---

## Related

- [DevOps governance](devops-governance.md)
- [Change management](change-management.md)
- [Audit evidence](audit-evidence.md)
- [Access control](../07-security/access-control.md)
- [Logging standard](../08-observability/logging-standard.md)
- [Standard operating procedures](../../sop/)
