# Implementation Plan: Production Operational Automation Phase 2

This plan outlines the next phase of operational automation and readiness drills: completing SonarQube disaster recovery automation, production Alertmanager notification routing with webhook templates, and a unified platform audit runner.

## User Review Required

> [!IMPORTANT]
> - DR drills run in isolated temporary scratch directories (`tmp/`) and do not impact running services.
> - Alertmanager notification templates use placeholder webhook URLs (`https://hooks.slack.com/...` and `https://outlook.office.com/...`).

---

## Proposed Changes

### 1. SonarQube Disaster Recovery & Re-indexing Drill
Implements [`runbooks/sonarqube-maintenance.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/runbooks/sonarqube-maintenance.md) and [`sop/restore-test.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/sop/restore-test.md).

#### [NEW] [`scripts/drill-restore-sonarqube.sh`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/scripts/drill-restore-sonarqube.sh)
- **Features**:
  1. Creates an isolated backup of SonarQube PostgreSQL database dump and plugin extensions.
  2. Simulates instance failure and data loss.
  3. Restores database schema into a clean restore target.
  4. Verifies Elasticsearch search index clearing procedure (`data/es7`) to force clean re-indexing without index corruption.
  5. Asserts Quality Gate threshold persistence and measures RTO/RPO.

---

### 2. Alertmanager Production Notification Routing
Implements [`docs/08-observability/alerting-standard.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/docs/08-observability/alerting-standard.md) and closes the notification routing gap.

#### [NEW] [`templates/monitoring/alertmanager.example.yml`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/templates/monitoring/alertmanager.example.yml)
- Complete, production-grade Alertmanager configuration:
  - Routing tree: `severity: critical` -> On-call PagerDuty/Webhook, `severity: warning` -> Slack/Teams channels, `severity: heartbeat` -> Dead Man's Snitch.
  - Inhibit rules: suppress warning alerts if critical alert is already firing on the same instance.
  - Grouping by alertname, cluster, and service to eliminate alert fatigue.

#### [NEW] [`templates/monitoring/alertmanager-templates.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/templates/monitoring/alertmanager-templates.md)
- Message template formatting guide for Microsoft Teams, Slack, and email notifications.

---

### 3. Unified Platform Audit Runner
Provides a single, master command that verifies the entire repository and generates an audit-ready compliance report.

#### [NEW] [`scripts/drill-full-platform-audit.sh`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/scripts/drill-full-platform-audit.sh)
- **Execution Pipeline**:
  1. Validates all 23+ YAML files and 10+ JSON files.
  2. Scans 150+ Markdown documents and 1,640+ links for broken references.
  3. Scans for real secrets or credential leaks.
  4. Runs all 5 reference application test suites (`scripts/test-all-examples.sh`).
  5. Runs DR restore drills (`drill-restore-jenkins.sh`, `drill-restore-harbor.sh`, `drill-restore-sonarqube.sh`).
  6. Outputs a consolidated audit record matching [`docs/10-governance/audit-evidence.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/docs/10-governance/audit-evidence.md).

---

### 4. Documentation & Verification
- Update [`scripts/README.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/scripts/README.md).
- Update [`templates/monitoring/README.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/templates/monitoring/README.md).
- Update [`CHANGELOG.md`](file:///c:/Users/supachai.nil/Documents/GitHub/enterprise-devops-blueprint/CHANGELOG.md).
- Run full verification drill.

---

## Verification Plan

### Automated Tests
1. `bash -n scripts/drill-restore-sonarqube.sh`
2. `bash -n scripts/drill-full-platform-audit.sh`
3. Execute `scripts/drill-restore-sonarqube.sh` using Git Bash.
4. Execute `scripts/drill-full-platform-audit.sh` to run the master audit.
5. Validate YAML on `alertmanager.example.yml` using `python -c "import yaml; yaml.safe_load(...)"`.
