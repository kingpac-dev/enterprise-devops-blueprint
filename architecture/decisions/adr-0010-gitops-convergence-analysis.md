# Supporting Analysis: GitOps Convergence & Asynchronous Rollback

## 1. Context

This analysis provides the operational and architectural evaluation supporting [ADR-0010: Portainer GitOps Deployment](../../adr/0010-portainer-gitops-deployment.md).

ADR-0010 established that production deployment is **pull-based**: Portainer Stacks synchronize from a deployment Git repository triggered by a webhook, eliminating direct inbound SSH access from CI/CD to production runtime hosts.

---

## 2. The Asynchronous Convergence Problem

In a traditional push-based model (e.g. Jenkins SSH):
```text
Jenkins SSH -> Host -> docker compose up -d -> docker inspect -> Result (Synchronous)
```
The pipeline waits directly on the SSH execution and immediately knows the exit code.

In a pull-based GitOps model:
```text
Jenkins -> Git Commit -> Portainer Webhook -> Portainer schedules sync -> Host pulls image -> Container starts (Asynchronous)
```
When Portainer acknowledges the webhook with HTTP 200, **nothing has deployed yet** — Portainer has merely queued the stack synchronization.

### The Architectural Challenge
Without convergence verification:
1. Jenkins reports build success even if the image pull fails or the new container crashes in a restart loop.
2. The pipeline cannot know when smoke tests should start.
3. Automated rollback has no signal to trigger upon.

---

## 3. Options for Convergence Verification

| Option | How It Works | Trade-offs |
| --- | --- | --- |
| **Option A: Fixed Sleep Delay** | Pipeline waits 60s after webhook, then runs smoke tests. | ❌ Brittle; slow on fast deploys, fails on large image pulls; no error detection. |
| **Option B: Direct Portainer API Polling** | Jenkins polls Portainer API for container status and image SHA. | ⚠️ Requires high-privilege Portainer API token in Jenkins; couples CI to Portainer internal API. |
| **Option C: Endpoint Version Probe with Convergence Loop (Selected)** | Jenkins polls the public/ingress health endpoint (`/healthz` or `/version`) until the reported version matches the newly deployed tag. | ✅ Decoupled; tests real user-facing availability; robust timeout and rollback triggering. |

---

## 4. The Automated Rollback Sequence

The convergence loop implemented in [`templates/jenkins/deploy-gitops.sh`](../../templates/jenkins/deploy-gitops.sh) works as follows:

```mermaid
sequenceDiagram
    participant J as Jenkins Pipeline
    participant G as Deployment Git Repo
    participant P as Portainer Webhook
    participant A as Application Container

    J->>G: 1. Commit new image tag (e.g. app:1.4.2)
    J->>P: 2. Trigger Stack Webhook
    P-->>J: 200 OK (Sync Scheduled)

    loop Convergence Loop (every 10s, timeout 300s)
        J->>A: 3. Probe /healthz & Version
        alt Version matches and healthy
            A-->>J: HTTP 200 (version=1.4.2)
            Note over J: Deployment Converged!
        else Version old or unhealthy
            A-->>J: HTTP 503 or old version
            Note over J: Wait & retry...
        end
    end

    alt Timed out or Container Crashed
        Note over J: Triggering Automated Rollback!
        J->>G: 4. Revert Git Commit to previous tag (app:1.4.1)
        J->>P: 5. Trigger Stack Webhook
        loop Verification of Rollback
            J->>A: 6. Probe /healthz
            A-->>J: HTTP 200 (version=1.4.1)
        end
        Note over J: Rollback Verified. Fail Pipeline & Alert.
    end
```

---

## 5. Architectural Conclusion

Pull-based GitOps satisfies enterprise network security requirements (no SSH keys across security zones) while maintaining strict deployment guarantees by wrapping the webhook in an **asynchronous convergence loop**. This ensures automated rollback remains reliable and fully functional in production.
