# Access Control

## Purpose

Defines the role model across the delivery platform: who has access to what, on what basis, and how access is granted, reviewed, and removed.

## Scope

Human and automation access to GitHub, Jenkins, SonarQube, Harbor, Portainer, and runtime hosts. Credential storage and rotation are in [secrets-management.md](secrets-management.md); Harbor-specific configuration is in [harbor-standard.md](../06-container/harbor-standard.md).

## Audience

Platform engineers, security engineers, and whoever approves access requests.

## Status

**Draft for review.** Role definitions below are proposals. No role-to-permission mapping has been agreed, and no owner has been assigned.

---

## 1. Principles

**Least privilege.** Each identity holds the minimum access required for its function.

**Roles, not individuals.** Access is granted to a role; people hold roles. This document names no individuals, and neither should any permission configuration.

**Separate human from automation.** Automation uses service or robot accounts, never a person's credentials. Automation running as a person is unattributable, breaks when they leave, and inherits every permission they hold.

**Production access is a capability, not an attribute.** Being a senior engineer does not confer production access. It is granted for a purpose, recorded, and reviewed.

**Access is temporary by default where the platform allows it.** Standing access accumulates; time-bounded access expires.

---

## 2. Proposed Roles

`TBD` — all role definitions require confirmation.

| Role | Purpose |
| --- | --- |
| Developer | Builds and maintains applications |
| Team lead | Developer, plus approval within the team's scope |
| Platform engineer | Operates the delivery toolchain |
| Security engineer | Reviews and assesses security-relevant changes |
| Release approver | Authorizes production deployment |
| Operator | Executes runbooks; troubleshoots production |
| Auditor | Reads evidence; changes nothing |

The release approver role is deliberately separate. Where the person who wrote a change is also the person who approves its release, the approval gate records a decision without providing independent review — see [10-governance/](../10-governance/).

---

## 3. Proposed Permission Matrix

`TBD` — this matrix is a starting proposal, not a decision.

| System | Developer | Platform engineer | Security engineer | Release approver | Operator | Auditor |
| --- | --- | --- | --- | --- | --- | --- |
| GitHub — application repos | Write | Write | Read | Read | Read | Read |
| GitHub — blueprint repo | Read | Write | Write | Read | Read | Read |
| GitHub — branch protection settings | None | Admin | Read | None | None | Read |
| Jenkins — view builds | Read | Read | Read | Read | Read | Read |
| Jenkins — trigger non-production | Yes | Yes | No | No | Yes | No |
| Jenkins — trigger production | No | No | No | **Yes** | No | No |
| Jenkins — configure jobs | None | Admin | Read | None | None | Read |
| Jenkins — credentials | None | Admin | Read config, not values | None | None | Audit log only |
| Harbor — pull | Team projects | All | All | Read metadata | All | Metadata |
| Harbor — push | None | Via automation only | None | None | None | None |
| Harbor — administer | None | Admin | Read | None | None | Read |
| SonarQube — view | Yes | Yes | Yes | Yes | Read | Read |
| SonarQube — quality gate config | None | Admin | Admin | None | None | Read |
| Portainer — inspect | `TBD` non-prod | Yes | Read | None | Yes | Read |
| Portainer — modify | **None** | `TBD` | None | None | `TBD` under change control | None |
| Runtime host — DEV | `TBD` | Yes | Read | None | Yes | None |
| Runtime host — UAT | None | Yes | Read | None | Yes | None |
| Runtime host — PROD | **None** | `TBD` restricted | Read | None | `TBD` restricted | None |

Three rows deserve comment.

**Harbor push is automation-only.** No human account pushes images. If a person can publish an artifact directly, the pipeline is no longer the only path into production, and the traceability chain has a gap that nothing records.

**Portainer modify is heavily restricted.** Portainer's designated role is visibility, troubleshooting, and approved operational tasks. Modification capability is what turns it into an uncontrolled deployment path that bypasses CI/CD governance, and the boundary is enforced by permissions rather than by intent.

**Production host access is restricted and separate from every other role.** It is not a developer capability, and it should be time-bounded and recorded where the platform allows.

---

## 4. Automation Identities

| Identity | Purpose | Permission |
| --- | --- | --- |
| Jenkins to GitHub | Checkout, status reporting | Repository read, status write |
| Jenkins to Harbor | Publish images | Push and pull, scoped to its projects |
| Jenkins to SonarQube | Submit analysis, read gate | Project-scoped where supported |
| Jenkins to deployment targets | Deploy, verify, roll back | Per environment, deployment only |
| Runtime host to Harbor | Retrieve images | **Pull only**, per environment |
| Prometheus to services | Scrape metrics | `TBD` — network restriction or token |

Requirements for every automation identity: a distinct account per function, a distinct account per environment, minimum scope, an expiry where supported, and an owner role responsible for its rotation.

`TBD` — naming convention, so an account's purpose is evident without consulting a register.

---

## 5. Granting, Changing, and Removing Access

### Joining

```text
1. Request states the role, the systems, and the business reason
2. Approval by the owning role
3. Provisioning to role defaults only, not by copying another person's access
4. Record: who, what, when, approved by which role
```

Copying an existing person's access is how privilege accumulates across an organization. It propagates every exception that person ever accumulated, and the copy is invisible thereafter because it looks like a normal grant.

### Changing role

Access is re-provisioned to the new role, not added to the old. Someone who moves between teams and keeps both access sets ends up with the union of every role they have ever held — which is the most common route to excessive standing privilege.

### Leaving

```text
1. Revoke access across every system, including automation they own
2. Reassign ownership of any credential or account they held
3. Rotate any shared credential they had access to
4. Record completion
```

Step 3 is regularly skipped and is the reason it is listed. If a departing person had access to a credential, that credential is compromised for the purpose of access control, regardless of trust in the individual.

`TBD` — the offboarding procedure and its target completion time, in [sop/](../../sop/).

---

## 6. Review

Access review is the control that catches everything the processes above miss.

| Review | Frequency | Confirms |
| --- | --- | --- |
| Production access | `TBD` | Every holder still requires it |
| Administrative access, all systems | `TBD` | Admin sets have not grown |
| Automation accounts | `TBD` | Each is still used, still scoped, still owned |
| Expired and orphaned accounts | `TBD` | Nothing remains for a departed person or retired system |

The review that matters most is automation accounts. They are created for a purpose, outlive it, and are never removed because nobody is certain what would break. An expiry set at creation is a more reliable control than a review scheduled for later — see [secrets-management.md](secrets-management.md#6-lifecycle).

---

## 7. Emergency Access

There will be situations requiring access that the normal model does not grant. That path must be designed rather than improvised, because an improvised path is neither recorded nor reversed.

| Requirement | Detail |
| --- | --- |
| Pre-authorized | Defined before it is needed, not negotiated during an incident |
| Time-bounded | Expires automatically |
| Recorded | Who, what, when, why, authorized by which role |
| Reviewed after use | Every use examined afterwards |
| Revoked | Explicitly, and verified |

Without a designed path, emergency access is obtained by someone with standing privilege doing it directly — which produces no record and no review, and is precisely the drift this document exists to prevent.

`TBD` — the emergency access procedure and authorizing role.

---

## 8. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — role definitions and the permission matrix | Everything here |
| `TBD` — release approver role assignment | Production approval |
| `TBD` — production host access model | Production access policy |
| `TBD` — Portainer modification permissions per environment | Governance boundary |
| `TBD` — automation account naming convention | Auditability |
| `TBD` — review frequencies and who performs them | Whether reviews happen |
| `TBD` — emergency access procedure | Incident response |
| `TBD` — offboarding procedure and completion target | Departure risk |
| `TBD` — whether an identity provider centralizes any of this | Feasibility of the whole model |

The last item has the widest effect. Managing seven role definitions across six systems by hand is achievable at small scale and does not remain so. Whether a central identity provider is available determines how much of this model is realistically enforceable.

---

## Security Considerations

Two rows in section 3 carry the most weight: Harbor push restricted to automation, and Portainer modification restricted. Both prevent a path into production that bypasses the pipeline, and both are enforced by permissions rather than by policy statements.

Privilege accumulation is the failure this document is mostly about. It happens through copied grants, role changes that add rather than replace, and automation accounts that outlive their purpose. None of these is a breach; together they produce an environment where an ordinary compromise reaches much further than it should.

## Operational Considerations

Access review has recurring cost and no immediate consequence for skipping, which places it in the category of controls that lapse. Expiry, where the platform supports it, converts the discipline problem into a scheduled event.

Restricting production access has a real cost in incident response time, and that cost is paid at the worst moment. The mitigation is a designed emergency path, not standing access — but the emergency path must genuinely exist and be tested, or the practical outcome is standing access held informally.

---

## Related

- [Security baseline](security-baseline.md)
- [Secrets management](secrets-management.md)
- [Harbor standard](../06-container/harbor-standard.md)
- [Governance](../10-governance/)
- [Standard operating procedures](../../sop/)
- [Logical architecture](../01-architecture/logical-architecture.md)
