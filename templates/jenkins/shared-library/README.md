# Enterprise Jenkins Shared Library

## Purpose

Provides reusable, standardized pipeline steps and opinionated declarative pipeline wrappers for the Enterprise DevOps Platform.

This library eliminates pipeline drift across repositories and enforces organizational quality gates, security scanning, and GitOps deployments consistently.

---

## 1. Directory Structure

```text
shared-library/
├── README.md
└── vars/
    ├── standardPipeline.groovy    # Opinionated declarative pipeline wrapper
    ├── trivyScan.groovy           # Reusable Trivy vulnerability scanning step
    └── gitopsDeploy.groovy        # Pull-based GitOps deployment with rollback
```

---

## 2. Registering in Jenkins (JCasC)

To register this library globally in Jenkins, add the following configuration to `infra/configs/jenkins/jenkins.yaml` under `unclassified.globalLibraries`:

```yaml
unclassified:
  globalLibraries:
    libraries:
      - name: "enterprise-pipeline-library"
        defaultVersion: "v1.0.0"
        retriever:
          modernSCM:
            scm:
              git:
                remote: "https://github.com/kingpac-dev/enterprise-devops-blueprint.git"
                credentialsId: "jenkins-github-pat"
                traits:
                  - "gitBranchDiscovery"
```

---

## 3. Usage in Application Repositories

In any application repository, replace boilerplate pipeline definitions with:

```groovy
@Library('enterprise-pipeline-library@v1.0.0') _

standardPipeline(
    appName: 'order-api',
    appType: 'go-fiber', // Supported: angular, react-vite, dotnet-api, dotnet-worker, go-fiber
    harborProject: 'core-services'
)
```

Or consume individual steps inside a custom declarative pipeline:

```groovy
stage('Security Scan') {
    steps {
        trivyScan(
            imageName: "${HARBOR_REGISTRY}/apps/order-api:1.2.0",
            severity: 'CRITICAL,HIGH',
            exitCode: 1
        )
    }
}
```

---

## Related Documents

- [Jenkins Templates Directory](../README.md)
- [CI Pipeline Flow Diagram](../../../architecture/diagrams/ci-pipeline.md)
- [GitOps Deployment Script](../deploy-gitops.sh)
- [Trivy Scan Standard](../../../docs/07-security/vulnerability-management.md)
