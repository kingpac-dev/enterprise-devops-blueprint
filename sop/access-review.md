# SOP — Access Review

## Trigger and Frequency

`TBD`. Proposal:

| Review | Frequency |
| --- | --- |
| Production access, tiers 3–4 | `TBD` — most frequent |
| Administrative access, all systems | `TBD` |
| Automation accounts | `TBD` |
| Expired and orphaned accounts | `TBD` |

## Roles

| Role | Responsibility |
| --- | --- |
| Reviewer (`TBD`) | Performs the review |
| System owner | Confirms whether each grant is still needed |
| Security owner (`TBD`) | Accountable for the outcome |

## Why This Exists

Access review catches what every other process misses.

Privilege accumulates through copied grants, role changes that add rather than replace, and automation accounts that outlive their purpose. **None of these is a breach.** Together they produce an environment where an ordinary compromise reaches much further than it should — and because it is drift rather than an event, there is no moment at which anyone notices.

---

## Steps

### 1. Enumerate

For each system — GitHub, Jenkins, SonarQube, Harbor, Portainer, runtime hosts — list every identity and its permissions.

- [ ] Human accounts
- [ ] Automation and robot accounts
- [ ] Accounts with administrative rights

`TBD` — whether enumeration is automated. Manual enumeration across six systems is achievable at small scale and does not remain so.

### 2. Review each grant

| Question | Action if bad |
| --- | --- |
| Does this person still hold the role this was granted for? | Revoke |
| Is the tier still the lowest that works? | Reduce |
| Has this person changed role or left? | Revoke; see [offboarding.md](offboarding.md) |
| Was this granted temporarily and never removed? | Revoke |
| Is this automation account still used? | Revoke if not |
| Does this automation account have an owner? | Assign one, or revoke |
| Is the scope still minimal? | Reduce |

### 3. Review automation accounts specifically

**This is the review that matters most.** Automation accounts are created for a purpose, outlive it, and are never removed because nobody is certain what would break.

| Check |
| --- |
| Last used — an account unused for a long period is a candidate for removal |
| Owner role assigned |
| Scope still minimal, and still pull-only where it should be |
| Expiry set |

An expiry set at creation is a more reliable control than a review scheduled for later. Where accounts have expiry, this review becomes confirmation rather than detection.

### 4. Cross-check against practice

| Question | What a bad answer means |
| --- | --- |
| Did anyone use tier 3 or 4 without a corresponding change record? | The gap between policy and practice — investigate |
| Was any emergency access left in place? | Revoke; investigate why expiry did not fire |
| Is any tier held by more people than the work requires? | Reduce |
| Are there accounts for people who have left? | Offboarding failed; check whether shared credentials were rotated |

The first is the one that finds what the enumeration cannot.

### 5. Act and record

- [ ] Revocations performed
- [ ] Reductions performed
- [ ] **Removals verified**
- [ ] Findings and actions recorded

`TBD` — where review records are held, and their retention.

---

## Verification

- [ ] Every revoked identity confirmed to no longer authenticate
- [ ] Every reduced grant confirmed at the new level
- [ ] Findings recorded, including "no change required" where that is the outcome

---

## Metrics Worth Tracking

| Metric | A bad trend means |
| --- | --- |
| Identities per system, over time | Accumulation |
| Administrative accounts, over time | The admin set is growing |
| Automation accounts with no owner | Nobody is accountable for rotation |
| Grants revoked at each review | High is healthy early, and should fall |
| Tier 3–4 uses with no change record | Practice diverging from policy |

---

## Open Items

| Item |
| --- |
| `TBD` — review frequency per category |
| `TBD` — who performs the review |
| `TBD` — whether enumeration is automated |
| `TBD` — where records are held and for how long |
| `TBD` — whether a central identity provider exists |

The last determines how much of this is realistically enforceable. Managing seven role definitions across six systems by hand works at small scale and does not remain so.

---

## Related

- [Access control](../docs/07-security/access-control.md)
- [Production access policy](../docs/10-governance/production-access-policy.md)
- [Access request](access-request.md)
- [Offboarding](offboarding.md)
