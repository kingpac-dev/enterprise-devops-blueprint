# Release Notes — v<version>

<!--
Copy per release. The approver reads this BEFORE approving.
Notes written after deployment serve a different and lesser purpose.
-->

| | |
| --- | --- |
| Version | `<version>` |
| Git tag | `v<version>` |
| Commit | `<short commit>` |
| Image | `<harbor>/<project>/<name>:<version>-<commit>` |
| Digest | `sha256:<digest>` |
| Date | `<YYYY-MM-DD>` |
| Change reference | `<ticket>` |

---

## Changes

<!--
In terms a reader outside the team understands. A generated commit list is
complete and unreadable; a written summary is readable and sometimes omits
things. Both together is usually the workable answer.
-->

- `<change>`
- `<change>`

---

## Breaking Changes

**None.**

<!--
State "None" explicitly rather than omitting the section — "none" is
information, and an absent section is ambiguous.

A change is breaking if a consumer must change to keep working:
  - removing or renaming an API field
  - changing the type or meaning of a field
  - making an optional request field required
  - changing a message schema consumed by a worker — the consumer is the worker
  - a migration the previous version cannot run against — the consumer is rollback
-->

---

## Database Migrations

**None.**

<!-- Or: -->
<!--
| Migration | Reversible | Notes |
| --- | --- | --- |
| `<name>` | No | `<what it does>` |

**Rollback is NOT available for this release.** Redeploying the previous
image leaves the old code running against the new schema.

Before deployment:
  - [ ] Backup taken and verified
  - [ ] Expand/contract strategy applied, or the limitation accepted
  - [ ] Forward recovery plan documented
-->

---

## Configuration Changes

**None.**

<!--
| Variable | New / Changed | Action required before deployment |
| --- | --- | --- |
| `<VAR>` | New | Set in each environment's .env before deploying |

This section has its own line because its failure mode is specific: a release
requiring a new value deploys successfully and then fails at run time, in
production, on the values that were not set.
-->

---

## Rollback

| | |
| --- | --- |
| Available | Yes / **No** |
| Previous known-good version | `<version>-<commit>` |
| Image still retained in Harbor | Yes / **No — verify before deploying** |
| Limitations | `<none, or what>` |

The retention row matters. A rollback target evicted by a retention rule means the rollback fails at the moment it is needed, having appeared configured and correct until then.

---

## Verification

| Gate | Result |
| --- | --- |
| Quality Gate | Passed |
| Security scan | Passed |
| UAT verification | `<what was verified, by whom>` |
| Smoke test | `<what it covers>` |

State what was actually verified. "Tested" without specifics leaves the approver deciding on nothing.

---

## Known Issues

- `<issue, and whether it is accepted for this release>`

---

## Approval

| | |
| --- | --- |
| Approver role | `<role>` |
| Approved at | `<timestamp>` |
