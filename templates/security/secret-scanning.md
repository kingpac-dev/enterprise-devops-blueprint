# Secret Scanning

## Purpose

Where secret scanning runs, what it does when it finds something, and why the response is not the same as for a vulnerability finding.

## Status

**Draft for review.** Not implemented. Tooling and placement are undecided.

Implements [secrets-management.md](../../docs/07-security/secrets-management.md) and [SECURITY.md](../../SECURITY.md).

---

## 1. A Detected Secret Is Not a Finding to Triage

Vulnerability findings are triaged against a severity threshold, may be excepted, and are remediated on an SLA.

**A detected secret is none of those.** It is a credential to treat as compromised, and the first action is rotation — not assessment, not an exception, not a ticket.

The reason is that exposure is already complete by the time it is detected. If it reached a shared branch, it is in history, in every clone, fork, and mirror, and in any CI cache. Deleting the file removes it from the working tree and from nothing else.

---

## 2. Where It Runs

Layered, because each layer catches what the previous one missed.

| Layer | Catches | Cost |
| --- | --- | --- |
| Pre-commit hook, local | Before it ever leaves the developer's machine — the only layer that prevents exposure rather than detecting it | Developer setup; bypassable |
| Push protection at GitHub | Before it reaches the remote | `TBD` — availability depends on plan |
| Pipeline scan of the repository | After the fact, reliably | Build time |
| Pipeline scan of the built image | Secrets baked into layers, which repository scanning does not see | Build time |

The pre-commit layer is the only one that prevents rather than detects, and it is the only one a developer can skip. Both facts are true and neither makes it less worth having.

The image layer catches a distinct case: a `.env` file pulled into the build context by a missing `.dockerignore`, or a credential written during a build step. Neither appears in a repository scan.

`TBD` — which layers are adopted.

---

## 3. Scanning With Trivy

Already available, since Trivy is the scanner for vulnerabilities.

```bash
# Repository
trivy fs --scanners secret --exit-code 1 .

# Built image — catches what got baked into layers
trivy image --scanners secret --exit-code 1 "${IMAGE_REF}"
```

`--exit-code 1` makes it a gate. Without it the scan reports and the pipeline continues, which is how a detection is missed in a log nobody reads.

Dedicated tools — gitleaks, trufflehog — scan **history** rather than the current tree, which Trivy does not. That matters for the first scan of an existing repository, where the question is whether anything was ever committed rather than whether anything is present now.

`TBD` — whether a history scan is run once at onboarding.

---

## 4. Response

```text
1. ROTATE the credential at its source. Before anything else
2. Notify the security contact and the credential owner
3. Replace the value in the working tree with a placeholder
4. Assess exposure: how long, which branches, who cloned or forked,
   whether CI logs or artifacts captured it
5. Review access logs of the affected system for the exposure window
6. Decide on history rewrite with the repository owner
7. Record the incident and its evidence
```

Step 1 is first, and steps 3 and 6 are not substitutes for it. History rewriting is disruptive to every clone and does not un-disclose anything.

Step 4 is the part usually skipped and the part that determines whether this was a near miss or an incident.

**Nobody is in trouble for reporting quickly.** A culture where a committed secret is embarrassing produces quiet deletions, which produce unrotated live credentials in history. That is considerably worse than the original mistake.

See [SECURITY.md](../../SECURITY.md#4-if-a-secret-is-committed).

---

## 5. False Positives

Secret scanners flag test fixtures, example values, and high-entropy strings that are not credentials.

| Handling | Note |
| --- | --- |
| Make placeholders obviously fake | `<set-via-jenkins-credentials>` is never flagged and never mistaken for real |
| Allow-list specific paths | Test fixtures, with a recorded reason |
| Never allow-list broadly | A path-wide suppression hides real secrets added there later |

The first is the cheapest fix and the one that scales. Placeholder conventions that look like credentials generate noise forever; placeholders that look like placeholders generate none.

`TBD` — allow-list format and where it lives.

---

## 6. What Scanning Does Not Cover

- Secrets in build logs. Logs are widely readable and long-lived, and a credential echoed by a verbose command lands there rather than in the repository.
- Secrets in a running container's environment, visible via container inspection.
- Secrets in tickets, chat, screenshots, and error reports.
- Secrets committed before scanning was introduced, unless a history scan is run.

The last is why the first scan of an existing repository should cover history. Introducing scanning and finding nothing means nothing has been committed *since* — which is not the question worth answering on day one.

---

## 7. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — which layers are adopted | Detection coverage |
| `TBD` — whether push protection is available | Prevention |
| `TBD` — one-time history scan at onboarding | Pre-existing exposure |
| `TBD` — allow-list format and location | False positive handling |
| `TBD` — whether a detection blocks the pipeline | Whether it is a gate |
| `TBD` — rotation runbook per credential type | Response speed |

The last is the one that determines response time. "Rotate the credential" is a straightforward instruction and a slow one when nobody has written down how to rotate this particular credential without an outage.

---

## Related

- [Secrets management](../../docs/07-security/secrets-management.md)
- [Repository security policy](../../SECURITY.md)
- [Vulnerability management](../../docs/07-security/vulnerability-management.md)
- [Git standard](../../docs/04-source-control/git-standard.md)
