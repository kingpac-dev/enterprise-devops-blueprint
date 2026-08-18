# SOP — Credential Rotation

## Trigger and Frequency

| Trigger | Timing |
| --- | --- |
| Scheduled | `TBD` — proposal: production quarterly, non-production annually |
| Suspected compromise | **Immediately** |
| Secret detected in Git, a log, an image, or a ticket | **Immediately** |
| Someone with access leaves or changes role | Within `TBD` of offboarding |
| Credential expiry approaching | Before expiry |

## Roles

| Role | Responsibility |
| --- | --- |
| Credential owner (`TBD` per credential) | Performs rotation |
| Security owner (`TBD`) | Notified on compromise-driven rotation |

**Every credential has an owner role.** An unowned credential is never rotated, because rotation is nobody's task.

---

## The Overlap Method

Rotation must be possible without an outage. Where the platform supports two active credentials, use the overlap:

```text
1. Issue the new credential
2. Update consumers
3. Verify consumers work with the new credential
4. Revoke the old credential
5. VERIFY the old credential no longer works
```

**Step 5 is not optional.** A rotation that issues a new credential without revoking the old one has increased the number of valid credentials rather than replaced one — and the old one is now unowned and unmonitored.

Where overlap is not supported, rotation requires a maintenance window and is a normal change under [change-management.md](../docs/10-governance/change-management.md).

---

## Per Credential Type

### Harbor robot account (push — Jenkins)

```text
1. Create a new robot account with the same scope: push and pull,
   limited to the projects it builds for. Set an expiry
2. Update the Jenkins credential (id: harbor-push) with the new value
3. Trigger a build; verify the push succeeds
4. Delete the old robot account in Harbor
5. Verify: attempt a login with the old credential — it must fail
```

### Harbor robot account (pull — runtime host)

**Pull-only, per environment, without exception.** A host that can push turns a host compromise into a supply-chain compromise.

```text
1. Create the new pull-only robot account for that environment
2. Update the host's registry login
3. Pull an image; verify success
4. Delete the old account
5. Verify the old credential fails
```

Rotate one environment at a time. Rotating all three together means a mistake affects everything simultaneously.

### SonarQube token

```text
1. Generate a new token, project-scoped where supported
2. Update the Jenkins credential (id: sonarqube-token)
3. Trigger a build; verify analysis submits AND the gate is read
4. Revoke the old token
5. Verify the old token is rejected
```

Step 3 verifies both directions. A token that can submit but not read the gate produces a pipeline that hangs at the Quality Gate.

### GitHub access

```text
1. Issue a new token with repository read and status write only
2. Update the Jenkins credential
3. Trigger a build; verify checkout AND status reporting
4. Revoke the old token
5. Verify rejection
```

### Application secrets (connection strings, signing keys)

The hardest, because rotation may invalidate state.

```text
1. Determine whether the application supports two valid values at once
   (many signing key implementations do; most connection strings do not)
2. If yes  — overlap: add new, deploy, verify, remove old, deploy
   If no   — maintenance window; this is a normal change
3. Update the environment file on the target host, or the Jenkins credential
4. Redeploy
5. Verify the application starts and functions
6. Verify the old value no longer works at its source
```

**A JWT signing key rotation invalidates every issued token** unless the application accepts both during an overlap. Users are logged out. Plan for it or design for overlap.

### Jenkins credential store master key

Not a routine rotation. It re-encrypts every stored credential.

`TBD` — procedure. Requires a verified backup first, and a restore test afterwards, because a mistake here makes every credential unrecoverable.

---

## Compromise-Driven Rotation

Different order. **Rotate first; investigate second.**

```text
1. ROTATE at the source. Do not wait for assessment
2. Notify the security contact and the credential owner
3. Replace the value in the working tree with a placeholder
4. Assess exposure: how long, which branches, who cloned or forked,
   whether CI logs or artifacts captured it
5. Review access logs of the affected system for the exposure window
6. Decide on history rewrite with the repository owner
7. Record the incident
```

Deleting the exposure is not remediation. History rewriting is disruptive to every clone and does not un-disclose anything.

**Nobody is in trouble for reporting quickly.** A culture where this is embarrassing produces quiet deletions and unrotated live credentials.

---

## Expiry Is the Better Control

Where the platform supports credential expiry, **set it**. Harbor robot accounts and GitHub tokens both do.

A non-expiring credential survives every process failure: it outlives the system that used it, the person who created it, and any memory of what it was for. It is then never revoked, because nobody is certain what would break.

The cost is real — an expired credential breaks a pipeline — and it is the correct trade. A pipeline that fails visibly is better than a credential nobody can account for.

---

## Verification and Evidence

- [ ] New credential works
- [ ] **Old credential verified as rejected**
- [ ] Scope unchanged — rotation is not an occasion to widen permissions
- [ ] Expiry set where supported
- [ ] Owner role recorded
- [ ] Recorded: what, when, by which role, why

`TBD` — where records are held.

---

## Failure

| Situation | Action |
| --- | --- |
| New credential does not work | Do not revoke the old one. Diagnose first |
| Old credential still works after revocation | **Escalate.** An unrevoked credential is worse than an unrotated one — it is unowned and unmonitored |
| A consumer nobody knew about breaks | That consumer was undocumented. Record it, then continue |

The third is common and is useful information: rotation is how undocumented consumers are discovered.

---

## Open Items

| Item |
| --- |
| `TBD` — rotation frequency per credential type |
| `TBD` — owner role per credential |
| `TBD` — expiry policy per platform |
| `TBD` — Jenkins master key rotation procedure |
| `TBD` — credential inventory: what exists, who owns it, when it expires |

The inventory is the prerequisite for all of the above. Rotation on a schedule requires knowing what there is to rotate.

---

## Related

- [Secrets management](../docs/07-security/secrets-management.md)
- [Access control](../docs/07-security/access-control.md)
- [Repository security policy](../SECURITY.md)
- [Secret scanning](../templates/security/secret-scanning.md)
