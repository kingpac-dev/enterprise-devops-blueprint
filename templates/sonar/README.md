# SonarQube Templates

## Purpose

Reusable SonarQube project configuration and Quality Gate guidance.

## Scope

Scanner configuration per application type and the settings that make the Quality Gate meaningful. Quality policy is defined in [docs/05-ci-cd/](../../docs/05-ci-cd/).

## Status

**Draft for review.** All three are written. Thresholds are proposals; the SonarQube edition is undecided and determines whether the recommended approach is available at all.

---

## Templates

| File | Target | Status |
| --- | --- | --- |
| [sonar-project.properties.angular](sonar-project.properties.angular) | Angular applications | Draft |
| [sonar-project.properties.dotnet](sonar-project.properties.dotnet) | .NET API and Worker projects | Draft |
| [quality-gate-baseline.md](quality-gate-baseline.md) | Recommended gate conditions, the reasoning, and how to introduce a gate | Draft |

## The Decision That Determines Whether the Gate Survives

Gate **new code**, not the whole codebase.

A gate applied to the whole codebase fails on day one for every pre-existing issue, blocks every pull request regardless of what it contains, and is removed within days — after which nobody proposes one again for a long time.

This depends on SonarQube identifying new code, which requires branch or pull-request analysis. **The Community edition does not provide it.** That constraint must be settled before the gate is designed rather than discovered afterwards — see [ADR-0003](../../adr/0003-use-sonarqube-for-code-quality.md).

## Two Configuration Details That Fail Quietly

**Test paths must be separated from source.** Without `sonar.tests` and matching exclusions, test code is measured as production code, which distorts every ratio the gate evaluates.

**The coverage report path must match what the build actually writes.** A wrong path reports zero coverage — which looks like a coverage problem rather than a configuration one, and gets "fixed" by lowering the threshold.

## Validation Performed

| Check | Result |
| --- | --- |
| No credential in any template | Confirmed — the analysis token is referenced, never embedded |
| **Analysis executed against a real SonarQube** | **Not run — no SonarQube available in this environment** |
| **Property names against the installed scanner version** | **Not verified** |

---

## Configuration Expectations

---

## Configuration Expectations

- Correct source and test path separation, so test code is not measured as production code.
- Coverage report path wired to the actual report the build produces.
- Sensible exclusions for generated code, with the reason recorded — exclusions that hide real code defeat the gate.
- Consistent project keys that match the repository and Harbor naming conventions.

## Credential Rules

The SonarQube token is supplied by Jenkins Credentials at run time. It must never appear in a properties file, in the repository, or in build logs.

---

## Open Items

- `TBD` — SonarQube server URL
- `TBD` — project key naming convention
- `TBD` — Quality Gate conditions and coverage thresholds per application type
- `TBD` — whether the gate applies to new code only or to the whole codebase

---

## Related

- [Templates index](../README.md)
- [CI/CD standards](../../docs/05-ci-cd/)
- [Jenkins templates](../jenkins/)
