# SOP — Offboarding

## Trigger

Someone leaves the organization, leaves a team, or changes role.

`TBD` — target completion time. Same working day for a departure is a reasonable starting proposal.

## Roles

| Role | Responsibility |
| --- | --- |
| Line manager | Initiates |
| Provisioner (`TBD`) | Revokes and records |
| Security owner (`TBD`) | Consulted where production access or shared credentials were held |

---

## Steps

### 1. Establish what they held

- [ ] Access per system: GitHub, Jenkins, SonarQube, Harbor, Portainer, runtime hosts
- [ ] Production access tier
- [ ] **Automation accounts they created or own**
- [ ] **Shared credentials they had access to**
- [ ] Standards, services, or credentials for which they are the owner role

The third and fourth are the ones that get missed, and they are the ones that matter after the person has gone.

### 2. Revoke access

- [ ] Revoked in every system
- [ ] **Each revocation verified** — confirm the identity no longer authenticates
- [ ] Access records updated

Revocation without verification is a checklist tick. Systems fail to propagate, sessions persist, and a second authentication path is sometimes forgotten.

### 3. Reassign ownership

- [ ] Automation accounts they owned reassigned to another role
- [ ] Credentials they owned reassigned
- [ ] Services they owned reassigned
- [ ] Standards they owned reassigned

An unowned credential is never rotated. An unowned service is unmaintained. Reassignment is not paperwork — it is what prevents both.

### 4. Rotate shared credentials

**This is the step that is routinely skipped, and it is why this SOP exists.**

- [ ] Every shared credential they had access to is rotated
- [ ] Rotation verified: the old value is rejected

If a departing person had access to a credential, that credential is compromised for the purpose of access control, **regardless of trust in the individual**. This is not a judgement about them. It is that access control cannot distinguish between a credential nobody has and a credential someone outside the organization has.

Follow [credential-rotation.md](credential-rotation.md).

### 5. Record

| Field |
| --- |
| Who, and their last day |
| Systems revoked, and when |
| Verification performed |
| Ownership reassigned to which roles |
| Shared credentials rotated |
| Completed by which role, and when |

`TBD` — where records are held.

---

## Role Change Rather Than Departure

The same procedure, with one difference that matters more than it appears to.

**Access is re-provisioned to the new role. It is not added to the old.**

Someone who moves between teams and keeps both access sets ends up with the union of every role they have ever held. Over a few moves, that person has more access than anyone intended and more than anyone can account for — and no single grant was wrong.

- [ ] Old role's access revoked
- [ ] New role's access granted from role defaults
- [ ] **Not** the union of the two

---

## Verification

- [ ] Every revocation confirmed
- [ ] Every ownership reassignment confirmed with the receiving role
- [ ] Shared credential rotations confirmed
- [ ] No orphaned automation account remains

Cross-check at the next [access review](access-review.md): an account for someone who has left means this procedure failed, and the shared-credential question then needs asking retrospectively.

---

## Failure

| Situation | Action |
| --- | --- |
| A system cannot be revoked immediately | Record it, escalate, and track to completion. Do not close the offboarding |
| An automation account has no obvious new owner | Escalate to the platform owner. Do not leave it unowned |
| Shared credentials cannot be rotated without an outage | Schedule it as a normal change, and record the interval during which the risk stands |

The third is honest risk acceptance rather than a reason to skip step 4.

---

## Open Items

| Item |
| --- |
| `TBD` — target completion time |
| `TBD` — who initiates, and how they are notified of a departure |
| `TBD` — whether an identity provider makes revocation single-step |
| `TBD` — credential inventory, so step 4 is answerable |

Step 4 depends entirely on the last item. "Every shared credential they had access to" cannot be enumerated without an inventory of what exists and who could reach it.

---

## Related

- [Access control](../docs/07-security/access-control.md)
- [Credential rotation](credential-rotation.md)
- [Access review](access-review.md)
- [Production access policy](../docs/10-governance/production-access-policy.md)
