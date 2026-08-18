# ADR-0003 — Use SonarQube for Code Quality

| Field | Value |
| --- | --- |
| Status | Proposed |
| Date | 2026-08-16 |
| Deciding role | `TBD` — platform owner |
| Supersedes | None |
| Superseded by | None |

> Blueprint decision made when this repository was established. Alternatives were assessed analytically, not through trials.

---

## Context

The delivery model requires a quality gate that **blocks promotion** rather than reporting after the fact. That requires a tool that produces a pass or fail verdict a pipeline can act on, covering TypeScript and C# alike, and integrating coverage produced by each language's own test tooling.

Language-native linters produce findings, not verdicts, and produce them in different formats per language. A blocking gate needs one consistent answer.

---

## Decision

SonarQube provides static analysis and the Quality Gate.

In practice:

- Every application repository is registered as a SonarQube project.
- The pipeline submits analysis and coverage, then polls the Quality Gate.
- A failed gate stops the pipeline before an image is published.
- **An unavailable SonarQube fails the build.** An unevaluated gate is not a pass.

---

## Consequences

### Positive

- One verdict format across TypeScript and C#, which is what makes a single blocking gate possible.
- Coverage integrates with analysis, so both are gated together.
- Quality trend history over time, which individual linter runs do not provide.
- Findings are visible to developers with locations and explanations rather than as a build failure alone.

### Negative

- **Another database to operate**, back up, and upgrade.
- **Gate tuning is real work.** A gate set above what the existing codebase achieves blocks every pull request on day one and is removed within a week. The workable approach gates new code only, which requires measuring the current state first.
- **Findings can become noise.** A large backlog of pre-existing issues trains developers to ignore the tool, at which point the gate is theatre.
- **Delivery stops when SonarQube is down**, because the gate fails closed. This is correct and it is a real availability dependency.
- Analysis adds pipeline time, on every build.

### Neutral

- **Edition matters and is undecided.** The Community edition does not provide branch or pull-request analysis, which means the gate evaluates the main branch rather than the change under review — a materially different control. Whether a commercial edition is required is `TBD` and should be settled before the gate is designed, not after.

---

## Alternatives Considered

| Alternative | Why not chosen |
| --- | --- |
| **Language-native linters only** (ESLint, Roslyn analysers) | Already used, and complementary rather than competing — they should run regardless. Rejected as the *gate* because each produces its own format and none produces a pass/fail verdict spanning both stacks with coverage integrated |
| GitHub CodeQL | Strong for security-focused analysis. Rejected as the primary quality gate: it targets vulnerabilities rather than maintainability and coverage, and it runs at GitHub, adding an external dependency to the gate |
| Qodana | Capable, and closer to a like-for-like comparison than the others. Not evaluated in depth; SonarQube's ecosystem and familiarity decided it. **Stated plainly because this was a shallow comparison** |
| Commercial SaaS quality platforms | Source code leaves the controlled network; recurring cost |
| No quality gate | Rejected. Without a blocking verdict there is no quality boundary between source and a deployable artifact — see [logical-architecture.md](../docs/01-architecture/logical-architecture.md) |

---

## Security Considerations

SonarQube performs some security-oriented analysis, and it is **not** the security control. Dependency and container vulnerability scanning is Trivy's job — see [ADR-0004](0004-use-trivy-for-container-security.md). Treating SonarQube's security findings as sufficient would leave dependency and image vulnerabilities unexamined.

The analysis token is supplied by Jenkins Credentials at run time and must never appear in a properties file, a repository, or a build log.

SonarQube holds a copy of the source code. Its access control and network placement should reflect that.

## Operational Considerations

The fail-closed behaviour is the operational property that will be argued about. When SonarQube is down and a release is waiting, the pressure to make the gate advisory arrives within hours. Proceeding may occasionally be justified; when it is, it is a recorded, time-bounded exception with an approver — not a quiet configuration change. See [exception-management.md](../docs/10-governance/exception-management.md).

The database is the operational cost. It grows with analysis history and requires backup and periodic maintenance.

Gate conditions are `TBD` and should be set from a measured baseline. Setting them from a general recommendation produces either a gate nothing passes or a gate nothing fails.

---

## Review Trigger

Revisit if:

- Branch and pull-request analysis proves necessary and the licensing cost is not justified — the gate would then need redesigning around what the available edition supports.
- Findings are routinely ignored or excepted, indicating the gate is not fitting how work is done.
- Operational burden of the database exceeds the value delivered.
- A single tool emerges that covers quality, security, and supply-chain analysis adequately, reducing the tool count.

---

## References

- [CI/CD standards](../docs/05-ci-cd/)
- [Pull request standard](../docs/04-source-control/pull-request-standard.md)
- [Security baseline](../docs/07-security/security-baseline.md)
- [SonarQube templates](../templates/sonar/)
