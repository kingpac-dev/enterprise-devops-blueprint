# Diagram: Continuous Integration (CI) Pipeline Standard

## 1. Purpose

Visualizes the mandatory sequential stages, fail-fast gates, security scanning, and artifact promotion flow of the standardized CI pipeline.

Implements: [docs/05-ci-cd/ci-standard.md](../../docs/05-ci-cd/ci-standard.md) and [docs/05-ci-cd/pipeline-stage-standard.md](../../docs/05-ci-cd/pipeline-stage-standard.md).

---

## 2. CI Pipeline Flowchart

```mermaid
flowchart TD
    START([Developer Push / PR]) --> CHECKOUT[1. Checkout Source & Verify Commit]
    
    CHECKOUT --> RESTORE[2. Restore Dependencies & Pinning Check]
    RESTORE -->|Fail| STOP_FAIL([Stop Build: Notify Developer])
    
    RESTORE --> LINT[3. Code Formatting & Lint]
    LINT -->|Fail| STOP_FAIL
    
    LINT --> BUILD[4. Compile / Transpile Application]
    BUILD -->|Fail| STOP_FAIL
    
    BUILD --> TEST[5. Run Unit Tests & Code Coverage]
    TEST -->|Fail| STOP_FAIL
    
    TEST --> SONAR[6. SonarQube Static Analysis]
    SONAR --> QGATE{7. Quality Gate Passed?}
    QGATE -->|No| STOP_FAIL
    
    QGATE -->|Yes| TRIVY_FS[8. Trivy Filesystem & Secret Scan]
    TRIVY_FS --> SEC_CHECK{Vulnerabilities > Threshold?}
    SEC_CHECK -->|Yes| STOP_FAIL
    
    SEC_CHECK -->|No| DOCKER_BUILD[9. Multi-Stage Docker Build]
    DOCKER_BUILD -->|Fail| STOP_FAIL
    
    DOCKER_BUILD --> TRIVY_IMG[10. Trivy Container Image Scan]
    TRIVY_IMG --> IMG_GATE{Critical CVEs Found?}
    IMG_GATE -->|Yes| STOP_FAIL
    
    IMG_GATE -->|No| SBOM[11. Generate CycloneDX SBOM]
    SBOM --> SIGN[12. Sign Image with Cosign / Notation]
    
    SIGN --> PUSH[13. Push Immutable Tag to Harbor]
    PUSH --> HARBOR[(Harbor Registry: Immutable Artifact)]
    
    HARBOR --> SUCCESS([CI Succeeded: Ready for CD Promotion])

    classDef pass fill:#e6f4ea,stroke:#137333,stroke-width:2px;
    classDef fail fill:#fce8e6,stroke:#c5221f,stroke-width:2px;
    classDef gate fill:#fef7e0,stroke:#b06000,stroke-width:2px;
    
    class SUCCESS pass;
    class STOP_FAIL fail;
    class QGATE,SEC_CHECK,IMG_GATE gate;
```

---

## 3. Mandatory Governance Gates

1. **Gate 1: Unit Test & Coverage Gate** — Pipeline terminates immediately if any test fails or coverage drops below project baseline (80%).
2. **Gate 2: SonarQube Quality Gate** — Promotion stops if code smells, vulnerabilities, or maintainability ratings fail the Quality Gate.
3. **Gate 3: Trivy Security Gate** — Zero CRITICAL unmitigated vulnerabilities allowed.
4. **Gate 4: Immutable Release Identifier** — Images published to Harbor must be traceable to Git SHA and build number.
