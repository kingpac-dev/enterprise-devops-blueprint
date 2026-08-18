# DevOps Governance

## Purpose

Defines who decides what, who owns which standard, and how standards change.

## Scope

Decision rights and ownership across the delivery platform. Access permissions are in [production-access-policy.md](production-access-policy.md) and [access-control.md](../07-security/access-control.md); change execution is in [change-management.md](change-management.md).

## Audience

Engineering management, platform owners, team leads, and anyone who needs to know who can approve something.

## Status

**Draft for review.** The framework is proposed; **no role has been assigned to any person or team.** Every assignment below is `TBD`.

---

## 1. What This Governance Is For

Governance here exists to answer three questions quickly:

- Who decides this?
- What evidence remains afterwards?
- What happens when someone needs an exception?

`AGENTS.md` requires change management to be lightweight and auditable, and explicitly warns against unnecessary bureaucracy. That constraint shapes everything below: the model has few roles, few change classes, and no approval board.

The failure mode being avoided is specific. A governance process heavy enough to be worth circumventing will be circumvented — through emergency classifications that are not emergencies, through standing exceptions, and through work that quietly happens outside the process. The result is worse than a light process, because the organization believes it has control it does not have.

---

## 2. Roles

Roles, never individuals. A person may hold several; some combinations are prohibited (section 4).

| Role | Decides |
| --- | --- |
| Platform owner | Platform architecture, toolchain selection, standard content |
| Security owner | Security standards, security exceptions, vulnerability policy |
| Service owner | Their service's design, release content, and readiness |
| Release approver | Whether a specific release deploys to production |
| Change approver | Whether a normal change proceeds |
| Emergency approver | Whether an emergency change proceeds |
| Operator | Executes runbooks; escalates rather than deciding |

`TBD` — every assignment. Which team or job function holds each role is an organizational decision this document cannot make, and inventing one would produce a policy that reads as authoritative while describing nothing real.

---

## 3. Decision Rights

| Decision | Decides | Consulted | Evidence |
| --- | --- | --- | --- |
| Adopt or replace a platform component | Platform owner | Security owner, service owners | ADR |
| Change a security standard | Security owner | Platform owner | Pull request plus ADR where architectural |
| Change any other standard | Platform owner | Affected service owners | Pull request |
| Grant an exception to a standard | Standard's owner | Security owner if security-relevant | Exception register |
| Approve a production release | Release approver | Service owner | Deployment record |
| Approve a normal change | Change approver | — | Change record |
| Approve an emergency change | Emergency approver | Retrospective review | Change record plus post-review |
| Grant production access | `TBD` | Security owner | Access record |
| Accept a residual risk | `TBD` — management | Security owner | Risk register |

The last row is the one most often left undefined. Accepting risk is a management decision, not an engineering one, and where it is undefined the risk is accepted by default — by whoever declines to block the work.

---

## 4. Separation of Duties

| Rule | Reason |
| --- | --- |
| The release approver is not the change author | Approval without independent review records a decision without providing one |
| The exception approver is not the requester | Otherwise an exception is a self-service bypass |
| The person granting production access does not grant it to themselves | |
| Emergency changes are reviewed by someone other than the person who made them | The review is the control; urgency does not remove it |

At small team sizes strict separation is sometimes impossible — there may be one person who understands the service. Where that is true, say so rather than pretending otherwise, and compensate: retrospective review by a peer, a recorded justification, or a second pair of eyes at a later stage.

An undocumented compensating control is not a compensating control.

---

## 5. Standard Ownership

Every standard in this repository has an owning role responsible for its accuracy, its review, and its exceptions.

| Area | Owner |
| --- | --- |
| Architecture | Platform owner |
| Source control | Platform owner |
| CI/CD | Platform owner |
| Container | Platform owner |
| Security | Security owner |
| Observability | Platform owner |
| Operations | `TBD` — operations owner |
| Governance | `TBD` |
| Disaster recovery | `TBD` |

An unowned standard is not maintained. It drifts from practice, and the drift is discovered when someone cites it in an argument and finds it describes a system that no longer exists.

`TBD` — review cadence per standard. A standard nobody has read in two years is a liability, because people assume it is current.

---

## 6. How a Standard Changes

```text
1. Proposal, as a pull request against this repository
2. Review by the owning role
3. Security review, where security-relevant
4. ADR where the change is architectural
5. Merge
6. Communication to affected teams
7. Changelog entry
```

Step 6 is the one that gets skipped. A standard that changed without anyone being told is a standard teams will violate in good faith, and enforcing it then feels arbitrary — which damages the standard's credibility more than the original gap did.

`TBD` — the communication mechanism.

### Applying to work already in flight

A tightened standard does not retroactively invalidate work already merged. It applies from its effective date, with a stated period for existing work to comply, or an exception recorded.

Retroactive enforcement produces a backlog nobody can clear and a set of permanent exceptions — which is how a standard becomes something everyone has an exception to.

---

## 7. Where Platform Ends and Teams Begin

| Concern | Platform team | Service team |
| --- | --- | --- |
| Jenkins, Harbor, SonarQube, observability stack | Operates | Consumes |
| Pipeline templates and shared library | Provides | Uses; may extend within the standard |
| Application pipeline definition | Reviews | Owns |
| Application code, tests, Dockerfile | — | Owns |
| Runtime hosts and their configuration | Operates | — |
| What runs on them | — | Owns |
| Service health and its alerts | Provides the mechanism | Owns the response |
| UAT environment parity | `TBD` | `TBD` |

The last row is deliberately unresolved and is called out because it is the one that fails silently. UAT is nobody's production and everybody's second priority, so it decays until a release fails because UAT no longer resembled production. Whoever owns parity should be named — see [environment-architecture.md](../01-architecture/environment-architecture.md#8-environment-parity).

The alerting row is where paging disputes originate. The platform team provides Prometheus and the routing; the service team decides what is worth being woken for and answers when it fires. Where that split is undefined, the platform team receives every alert for every service and triages what they cannot fix.

---

## 8. Escalation

```text
Operator  ->  Service owner  ->  Platform owner / Security owner  ->  Management
```

`TBD` — contacts by role, and response expectations per severity.

Escalation must be possible without knowing who is on duty. A path that depends on knowing the right person's name fails for anyone new, at night, which is when escalation paths are used.

---

## 9. Metrics

Governance is measured by whether it works, not by how much of it there is.

| Metric | Answers | Bad sign |
| --- | --- | --- |
| Emergency changes as a share of all changes | Is the normal path usable? | A rising share means normal change is too painful |
| Active exceptions, and their age | Are exceptions temporary? | Growth means standards do not fit reality |
| Expired exceptions still in effect | Is expiry enforced? | Any non-zero value |
| Changes without a change record | Is the process being used? | Any non-zero value |
| Standards not reviewed within their cadence | Are standards current? | Growth means drift |
| Time from change request to deployment | Is governance a bottleneck? | Growth invites circumvention |

The first is the most diagnostic. Emergency change exists for genuine emergencies; when its share rises, the usual cause is not more emergencies but a normal path people are avoiding. Treat that as a defect in the process rather than as misconduct.

---

## 10. Open Items

| Item | Blocks |
| --- | --- |
| `TBD` — assignment of every role in section 2 | Every approval in this repository |
| `TBD` — release approver role | Production deployment |
| `TBD` — emergency approver role | Emergency change |
| `TBD` — who grants production access | Production access policy |
| `TBD` — who accepts residual risk | Risk register |
| `TBD` — UAT parity ownership | Whether UAT verification means anything |
| `TBD` — alerting ownership split | Who answers a page |
| `TBD` — standard review cadence per area | Standard currency |
| `TBD` — escalation contacts by role and response expectations | Incident response |
| `TBD` — how standard changes are communicated | Whether teams know the rules |

---

## Security Considerations

Separation of duties in section 4 is a security control, and it is the one most easily eroded by team size. Where it cannot be maintained, the compensating control must be documented — an undocumented compensation is an undocumented gap.

Exception approval authority determines how easily a security control is bypassed. Where the requester can approve their own exception, the control is advisory.

## Operational Considerations

The model's viability depends on the roles in section 2 being assigned. Until they are, every approval in this repository has no named authority, and in practice approvals will be given by whoever is available — which is the ungoverned state the document exists to replace.

Section 9's first metric is the early warning for the whole model. Governance that people route around fails quietly, and emergency-change share is where that becomes visible before anything else.

---

## Related

- [Change management](change-management.md)
- [Production access policy](production-access-policy.md)
- [Exception management](exception-management.md)
- [Audit evidence](audit-evidence.md)
- [Access control](../07-security/access-control.md)
- [Architecture Decision Records](../../adr/)
