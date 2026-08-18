# Secrets Management

## Purpose

Defines how credentials are stored, referenced, scoped, rotated, and retired across the delivery platform and its environments.

## Scope

Secrets used by the pipeline and by running applications. Rules about what must never enter this repository, and the response when one does, are in [SECURITY.md](../../SECURITY.md) and are not repeated here.

## Audience

Developers, platform engineers, and security engineers.

## Status

**Draft for review.** Rotation frequencies and ownership assignments are undecided.

---

## 1. What Counts as a Secret

Any value whose disclosure grants access or enables impersonation:

- passwords and passphrases
- access tokens, personal access tokens, and API keys
- JWT signing keys and other cryptographic keys
- private certificates and private key material
- private SSH keys
- registry and package feed credentials
- database and service connection strings
- webhook signing secrets

Internal hostnames, IP addresses, and network topology are not secrets in the cryptographic sense, but they carry reconnaissance value and are handled with the same care in this repository.

---

## 2. Approved Mechanisms

| Mechanism | Used for | Scope |
| --- | --- | --- |
| Jenkins Credentials | Anything the pipeline needs: source access, registry, analysis tokens, deployment credentials | Per credential, scoped to the folder or job that needs it |
| Environment-specific protected files, held outside Git | Application runtime configuration containing secrets | Per environment, per host |
| Host-managed secrets | Values the host provides to containers | Per host |

Not approved: values in Git in any form, values in container images, values in Compose files, values in build arguments, values passed as plain build parameters.

`ARG` deserves an explicit mention because it looks safe. Build arguments are recorded in image history and are readable by anyone who can pull the image, even though they do not appear in the final filesystem. See [dockerfile-standard.md](../06-container/dockerfile-standard.md#7-build-arguments-and-secrets).

---

## 3. Reference, Never Embed

Pipeline code references a credential by identifier. The value is injected at run time and never appears in the repository.

```groovy
withCredentials([usernamePassword(
    credentialsId: 'harbor-prod-push',
    usernameVariable: 'HARBOR_USER',
    passwordVariable: 'HARBOR_PASSWORD'
)]) {
    // use the credential here
}
```

Rules that follow:

- Never echo a credential, and never pass one into a command whose output is logged. Build logs are widely readable and long-lived.
- Never pass a credential as a build parameter. Parameters are visible in build history.
- Never write a credential to a file inside the workspace unless the file is removed in the same step, and understand that this is weaker than not writing it.
- Assume any command executed with `set -x`, or any tool with verbose logging, will print its arguments.

This indirection has a second benefit: because pipeline code references credentials rather than containing them, a later move to Vault or an equivalent becomes a configuration change rather than a migration. See [logical-architecture.md](../01-architecture/logical-architecture.md#7-extension-points).

---

## 4. Environment Isolation

**No credential is shared between DEV, UAT, and PROD.** This has no exceptions.

The failure this prevents is specific. DEV has the widest access, the least sensitive data, and the weakest controls, which makes it the natural first target. A credential shared with production turns a low-value DEV compromise into a production compromise, silently and immediately.

Sharing usually happens for convenience rather than by decision — one registry account, one database password, one API key, because three is more work. The work saved is a few minutes of setup; the cost is that every environment inherits the security posture of the weakest one.

| Credential | DEV | UAT | PROD |
| --- | --- | --- | --- |
| Registry pull | Distinct, pull only | Distinct, pull only | Distinct, pull only |
| Database | Distinct | Distinct | Distinct |
| External service API keys | Distinct, sandbox where the provider offers one | Distinct | Distinct |
| Signing keys | Not applicable | Not applicable | Restricted, see [container-image-signing.md](container-image-signing.md) |

---

## 5. Scope and Least Privilege

Each credential holds the minimum permission for its function.

| Consumer | Permission |
| --- | --- |
| Jenkins to GitHub | Repository read, plus commit status write |
| Jenkins to Harbor | Push and pull, limited to the projects it builds for |
| Runtime host to Harbor | **Pull only** |
| Jenkins to SonarQube | Analysis submission and gate read, project-scoped where supported |
| Jenkins to deployment targets | Deployment only, per environment |

Runtime hosts get pull-only registry credentials without exception. A production host has no reason to publish an image, and a compromised host that can push is a supply-chain compromise rather than a host compromise — see [harbor-standard.md](../06-container/harbor-standard.md#3-access-model).

---

## 6. Lifecycle

| Stage | Requirement |
| --- | --- |
| Creation | Requested through a recorded process; scope and owner role assigned at creation |
| Storage | An approved mechanism only |
| Reference | By identifier, never by value |
| Rotation | On a schedule, and immediately on suspected compromise or personnel change |
| Expiry | Set where the platform supports it |
| Revocation | On role change, offboarding, or when the consuming system is retired |
| Audit | Creation, use, and revocation recorded where the platform supports it |

Every credential has an **owner role** — never an individual name — responsible for its rotation and revocation. An unowned credential is never rotated, because rotation is nobody's task.

`TBD` — rotation frequency per credential type. Suggested starting points, to be confirmed: production credentials quarterly, non-production annually, and any credential immediately on suspected compromise.

### Expiry is the control that works without discipline

Where the platform supports credential expiry, set it. Harbor robot accounts and GitHub tokens both support it.

A non-expiring credential survives every process failure: it outlives the system that used it, the person who created it, and any memory of what it was for. It is then never revoked, because nobody can be certain what would break. An expiring credential forces that question to be answered on a schedule.

The cost is real — an expired credential breaks a pipeline — and it is the correct trade. A pipeline that fails visibly is better than a credential nobody can account for.

---

## 7. Rotation

Rotation must be possible without an outage. That is a design requirement on whatever consumes the credential, not just an operational procedure.

Where the platform supports two active credentials, use the overlap:

```text
1. Issue the new credential
2. Update consumers to the new credential
3. Verify consumers work
4. Revoke the old credential
5. Verify the old credential no longer works
```

Step 5 is not optional. A rotation that issues a new credential without revoking the old one has increased the number of valid credentials rather than replaced one.

Where overlap is not supported, rotation requires a maintenance window and must be documented as such.

`TBD` — rotation procedures per credential type, in [sop/](../../sop/).

---

## 8. Compromise Response

Treat a secret as compromised the moment it is exposed, and **rotate before anything else**. Deleting the exposure is not remediation.

The full procedure for a secret committed to this repository is in [SECURITY.md](../../SECURITY.md#4-if-a-secret-is-committed). The same principle applies wherever exposure occurs: rotate at the source, then assess, then clean up.

Exposure paths worth anticipating beyond Git: build logs, container images, `docker inspect` output on a shared host, centralized logs, error reports, and screenshots in tickets.

---

## 9. When Vault Becomes Justified

Vault or an equivalent is not adopted now. The current mechanisms are appropriate at this scale, and adopting a secret-management platform brings its own operational burden — including its own availability, backup, unseal, and recovery requirements.

Criteria that would justify revisiting:

| Signal | Why it matters |
| --- | --- |
| Secret count exceeds what can be reviewed manually | Manual inventory stops being reliable |
| Rotation frequency makes manual rotation impractical | Rotation gets deferred, which is worse than not scheduling it |
| Dynamic, short-lived credentials are needed | Static credentials cannot provide this |
| Audit requirements demand per-access records | Jenkins Credentials does not record every use |
| Secrets must be shared across systems Jenkins does not mediate | The current model assumes Jenkins is the distribution point |

`TBD` — whether any threshold has a defined value. Adopting Vault before one of these signals appears adds a critical dependency without addressing a problem.

---

## 10. Open Items

| Item | Affects |
| --- | --- |
| `TBD` — rotation frequency per credential type | Whether rotation happens at all |
| `TBD` — owner role per credential | Accountability for rotation |
| `TBD` — credential expiry policy per platform | Long-lived credential accumulation |
| `TBD` — whether Docker Compose file-based secrets replace environment variables | Runtime secret exposure |
| `TBD` — environment file ownership and permissions on each host | Secret protection at rest |
| `TBD` — secret scanning tooling and where it runs | Detection of committed secrets |
| `TBD` — rotation procedures per credential type | Operational feasibility |

---

## Security Considerations

Environment isolation and pull-only runtime credentials are the two controls with the largest effect relative to their cost. Both are cheap to establish at the start and expensive to retrofit once systems depend on shared credentials.

Environment variables deserve a note. They are visible to anyone who can run `docker inspect` on the host, and they are inherited by child processes — so a secret in an environment variable is exposed to every subprocess the application spawns, including any it spawns unintentionally. File-based secrets avoid both properties.

Jenkins holds credentials for every environment. That concentration is unavoidable in this architecture and is the reason controller access control and backup are security controls rather than operational conveniences.

## Operational Considerations

Rotation is the requirement most likely to be quietly abandoned, because skipping it has no immediate consequence and performing it carries outage risk. Expiry is the mitigation: it converts a discipline problem into a scheduled, visible event.

An unowned credential will not be rotated. Assigning an owner role at creation is the single procedural step that makes the rest of this document achievable.

---

## Related

- [Security baseline](security-baseline.md)
- [Access control](access-control.md)
- [Repository security policy](../../SECURITY.md)
- [Harbor standard](../06-container/harbor-standard.md)
- [Service interaction](../01-architecture/service-interaction.md)
- [Standard operating procedures](../../sop/)
