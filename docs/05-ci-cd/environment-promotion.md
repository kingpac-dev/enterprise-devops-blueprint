# Environment Promotion

## Purpose

Defines how one artifact moves from DEV through UAT to production, what may change between them, and what must not.

## Scope

The promotion model. The deployment flow is in [cd-standard.md](cd-standard.md); environment definitions are in [environment-architecture.md](../01-architecture/environment-architecture.md).

## Audience

Developers, platform engineers, and release approvers.

## Status

**Draft for review.**

---

## 1. Promotion Moves a Decision, Not an Artifact

The image does not travel. It is published once and pulled from the same registry by each environment.

What moves is a **decision**: this artifact, having passed these gates and this verification, may now run here.

That framing removes a common confusion. There is no "promoting the image to UAT" step that transforms anything. There is a deployment referencing an identifier that already exists.

```text
Build once
    |
    v
Harbor  ──> DEV   (automatic)
        ──> UAT   (release candidate)
        ──> PROD  (approved)
```

---

## 2. What Must Be Identical

| Identical across all three |
| --- |
| The image, byte for byte, under the same identifier |
| The application code and its compiled dependencies |
| The base image |

**Verifiable in one command.** Compare image digests across environments; they match, or the model is not being followed:

```bash
docker inspect --format '{{index .RepoDigests 0}}' <image>
```

`TBD` — whether this comparison is automated. It is a cheap check that detects the single most consequential deviation.

---

## 3. What May Differ

| May differ | Because |
| --- | --- |
| Endpoint addresses and connection strings | Different systems per environment |
| Credentials and certificates | **Must** differ — see section 5 |
| Log verbosity | DEV may be verbose; production must not be |
| Resource limits and replica counts | Different hardware and load |
| Feature flag values | That is what flags are for |
| Diagnostic endpoints | DEV only |

All supplied at run time. Nothing in this list may be compiled into the artifact.

---

## 4. What Must Never Happen

| Prohibited | Consequence |
| --- | --- |
| Rebuilding for an environment | UAT verification stops being evidence about production |
| Deploying to PROD something that did not pass UAT | The approval gate approves something unverified |
| Retagging during promotion | Retroactively invalidates every record naming that tag |
| `latest` in production | No deterministic answer to what is running |
| A shared credential across environments | A DEV compromise becomes a production compromise |
| Deploying outside the pipeline without change control | The audit trail stops describing reality |

---

## 5. The Secret Boundary Is Not Crossed

Every environment has its own credentials. **This has no exceptions.**

DEV has the widest access, the least sensitive data, and the weakest controls, which makes it the natural first target. A credential shared with production converts a low-value DEV compromise into a production compromise, silently and immediately.

Sharing happens for convenience rather than by decision — one registry account, one database password, one API key, because three is more work. The work saved is minutes of setup; the cost is that every environment inherits the security posture of the weakest one.

---

## 6. Promotion Gates

| Promotion | Requires |
| --- | --- |
| Build → DEV | All CI gates passed; image published |
| DEV → UAT | DEV health check passed; a release candidate exists |
| UAT → PROD | UAT verification complete; **explicit approval**, recorded |

Each gate is a stop, not a formality. Promotion does not proceed past a failure.

`TBD` — whether UAT deployment requires approval, and what "UAT verification complete" means concretely. Without a definition, it means "somebody looked", which is not a gate.

---

## 7. The Harbor Promotion Model

`TBD`, and it has a consequence worth understanding before choosing.

Some registry models implement promotion by **copying** an image between projects — `dev/app` to `prod/app`. That produces a **new identifier for identical content**, so "the artifact UAT verified" and "the artifact production runs" become two references requiring a mapping to relate.

| Model | Effect on identity |
| --- | --- |
| **One project; environment separation by access control** | Identity survives promotion. Recommended |
| Copy between per-environment projects | Identity changes. Every deployment record needs the mapping to be meaningful |

If copy-based promotion is chosen, the mapping between source and destination identifiers must be recorded in the deployment record — otherwise the traceability chain has a gap exactly at the environment boundary that matters most.

See [harbor-standard.md](../06-container/harbor-standard.md#2-project-structure).

---

## 8. Configuration Precedence

```text
1. Environment-specific configuration supplied at run time   (highest)
2. Environment-specific defaults in deployment configuration
3. Application defaults built into the image                 (lowest)
```

**Application defaults must be safe if nothing overrides them.** A default that points at a production endpoint, or that disables a control, is a defect: the failure mode of a missing override should be "does not start", not "starts and connects to production".

The Compose templates express this with `${VAR:?message}` for required values, so a missing value stops the deployment with a named error rather than starting in the wrong configuration.

---

## 9. The Frontend Exception That Is Not an Exception

An Angular build that substitutes environment values at **compile** time produces a different artifact per environment, which breaks everything above.

The resolution is runtime configuration: the container writes `assets/config.json` at start from environment variables, and the application reads it at bootstrap. See [templates/docker/](../../templates/docker/).

This generalizes. Any build-time-configured artifact has the same defect; the frontend just makes it obvious.

---

## 10. Environment Parity

Perfect parity between UAT and production is rarely achievable. What matters is knowing **where the gaps are**, because each gap is a class of defect UAT cannot catch.

| Dimension | Why it matters |
| --- | --- |
| Data volume | Performance and query behaviour differ at scale |
| Data shape | Real data contains cases synthetic data does not |
| External dependencies | Mocked or shared dependencies do not fail like real ones |
| Resource limits | Limits that hold in UAT may not hold under production load |
| Network topology | Latency, segmentation, and TLS termination differ |
| Concurrency | Contention and race conditions appear under real load |
| Configuration | Any deliberate difference is a difference in what was tested |

`TBD` — the divergence register, and **who owns UAT parity**. UAT is nobody's production and everybody's second priority, so it decays until a release fails because it no longer resembled production.

---

## 11. Open Items

| Item |
| --- |
| `TBD` — Harbor promotion model; section 7 |
| `TBD` — whether digest comparison across environments is automated |
| `TBD` — what "UAT verification complete" means concretely |
| `TBD` — whether UAT deployment requires approval |
| `TBD` — UAT parity owner and the divergence register |
| `TBD` — Angular runtime configuration mechanism, confirmed |

---

## Security Considerations

Section 5 is the security content of this document. The secret boundary is the only boundary in the blueprint with no legitimate crossing, and it is the one most often broken by convenience rather than by decision.

Copy-based promotion has a security dimension as well as a traceability one: an image copied between projects is a new artifact from the registry's perspective, and whatever scanning or signing applied to the original does not automatically apply to the copy.

## Operational Considerations

The single most useful check available here is comparing image digests across environments. It is one command, it detects the deviation that invalidates the entire model, and it currently is not run.

Environment parity decays silently. The divergence register exists so the decay is visible; without an owner, both the register and the parity go unmaintained.

---

## Related

- [CD standard](cd-standard.md)
- [Environment architecture](../01-architecture/environment-architecture.md)
- [Image versioning](../06-container/image-versioning.md)
- [Harbor standard](../06-container/harbor-standard.md)
- [Secrets management](../07-security/secrets-management.md)
- [Environment promotion diagram](../../architecture/diagrams/environment-promotion.md)
