# Diagram: Continuous Delivery (CD) Pipeline & Rollback Flow

## 1. Purpose

Visualizes the multi-environment promotion flow, manual production approval gate, health verification, automated rollback mechanism, and deployment audit recording.

Implements: [docs/05-ci-cd/cd-standard.md](../../docs/05-ci-cd/cd-standard.md), [adr/0008-production-manual-approval.md](../../adr/0008-production-manual-approval.md), and [adr/0010-portainer-gitops-deployment.md](../../adr/0010-portainer-gitops-deployment.md).

---

## 2. CD Promotion & Rollback Flowchart

```mermaid
flowchart TD
    IMG[(Harbor: Validated Image)] --> CD_START[Select Immutable Tag]

    subgraph DEV_STAGE["DEV Environment"]
        CD_START --> DEV_DEPLOY[Deploy to DEV via Portainer GitOps]
        DEV_DEPLOY --> DEV_HEALTH{Healthcheck /healthz}
        DEV_HEALTH -->|Fail| DEV_ALERT([Alert Developers: DEV Failed])
    end

    subgraph UAT_STAGE["UAT Environment"]
        DEV_HEALTH -->|Pass| UAT_DEPLOY[Promote & Deploy to UAT]
        UAT_DEPLOY --> UAT_HEALTH{UAT Healthcheck & Smoke Tests}
        UAT_HEALTH -->|Fail| UAT_ALERT([Alert QA & Devs: UAT Failed])
    end

    subgraph PROD_STAGE["PROD Environment"]
        UAT_HEALTH -->|Pass| APPROVAL_GATE{Manual Approval Gate\n(Product Owner / Lead)}
        APPROVAL_GATE -->|Rejected| CANCEL([Deployment Cancelled])
        
        APPROVAL_GATE -->|Approved| RECORD_KNOWN_GOOD[1. Record Current Known-Good Version]
        RECORD_KNOWN_GOOD --> PROD_DEPLOY[2. Deploy New Immutable Image to PROD]
        PROD_DEPLOY --> PROD_HEALTH{3. PROD Health & Smoke Checks}
        
        PROD_HEALTH -->|Pass| AUDIT_PASS[4. Record Successful Audit Trail]
        AUDIT_PASS --> COMPLETE([Production Release Complete])
        
        PROD_HEALTH -->|Fail| ROLLBACK_EXEC[4. Trigger Automated Rollback]
        ROLLBACK_EXEC --> RESTORE_IMAGE[5. Redeploy Known-Good Image]
        RESTORE_IMAGE --> VERIFY_RECOVERY{6. Healthcheck Restored?}
        
        VERIFY_RECOVERY -->|Yes| AUDIT_FAIL[7. Record Rollback & Failure Evidence]
        AUDIT_FAIL --> INCIDENT_ALERT([Incident Alert: Rollback Complete])
        
        VERIFY_RECOVERY -->|No| P1_ALERT([CRITICAL P1 ALERT: Rollback Failed, Manual SRE Intervention])
    end

    classDef pass fill:#e6f4ea,stroke:#137333,stroke-width:2px;
    classDef fail fill:#fce8e6,stroke:#c5221f,stroke-width:2px;
    classDef gate fill:#fef7e0,stroke:#b06000,stroke-width:2px;
    
    class COMPLETE,AUDIT_PASS pass;
    class DEV_ALERT,UAT_ALERT,CANCEL,INCIDENT_ALERT,P1_ALERT fail;
    class DEV_HEALTH,UAT_HEALTH,APPROVAL_GATE,PROD_HEALTH,VERIFY_RECOVERY gate;
```

---

## 3. Key Operational Requirements

1. **Pre-requisite for Production Deployment**: Current known-good image tag must be recorded in Jenkins job metadata prior to executing deployment.
2. **Health Verification**: All containers must report HTTP 200 on `/healthz` and `/readyz` within the configured start period before traffic is routed.
3. **Automated Rollback**: If validation fails in PROD, the pipeline restores the previous image automatically without waiting for manual triage.
4. **Audit Trail**: Jenkins and GitOps logs preserve commit SHA, image digest, approver username, and deployment timestamp.
