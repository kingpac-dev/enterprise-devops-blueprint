# Runbook — Certificate Renewal

> **This runbook has never been executed.** Certificate management is undecided — see Open Items.

## When to Use

| Trigger | |
| --- | --- |
| Expiry alert fired | Renew, within the warning window |
| Scheduled renewal | Renew |
| **Certificate has already expired** | Section 5 — this is an incident |
| Private key compromised | Section 6 — urgent |

## Roles

| Role | Responsibility |
| --- | --- |
| Platform engineer | Executes |
| Change approver (`TBD`) | Approves; renewal usually requires a service restart |

---

## 1. Why This Has a Runbook

A certificate expiry is a **predictable, preventable, total outage** with weeks of warning.

It is one of the few cases where alerting on a cause rather than a symptom is correct: the lead time is the entire point. An expired TLS certificate on Harbor stops every image push and pull — which stops deployment **and rollback** — and the failure presents as a connection error that looks like a network problem.

---

## 2. Certificate Inventory

`TBD` — the authoritative inventory. Without one, renewal is reactive and something is eventually missed.

| Certificate | Used by | Expiry impact |
| --- | --- | --- |
| Harbor | Registry push and pull | **Deployment and rollback both stop** |
| Jenkins | Web interface, webhook endpoint | Delivery stops; the webhook fails silently at GitHub's end |
| SonarQube | Analysis submission | Builds fail at the gate |
| Grafana | Dashboards | Observability access lost |
| Portainer | Operations interface | Troubleshooting access lost |
| Application ingress | User traffic | **User-facing outage** |

The Jenkins row has a subtlety: an expired certificate on the webhook endpoint causes GitHub's delivery to fail. Nothing in the platform reports it — builds simply stop being triggered, which looks like nobody pushing.

---

## 3. Renewal

### Preconditions

- [ ] Expiry date confirmed
- [ ] New certificate obtained, with its full chain
- [ ] Private key available and protected
- [ ] Change approved if a restart is required
- [ ] Rollback plan: the current certificate retained until the new one is verified

### Steps

```text
1. Verify the new certificate BEFORE installing:
     - subject and SANs cover every name in use
     - not-before and not-after dates
     - the full chain is present and in order
     - the key matches the certificate
2. Back up the current certificate and key
3. Install the new certificate
4. Reload or restart the service
5. Verify — see below
6. Record: what, when, new expiry, by whom
```

Step 1 catches the common failures before an outage rather than during one:

| Failure | Symptom if not caught |
| --- | --- |
| A SAN is missing | Some clients fail, others work — an intermittent-looking problem |
| Incomplete chain | Some clients fail depending on their trust store |
| Key does not match | The service will not start |

### Verify

```bash
openssl s_client -connect <host>:<port> -servername <host> </dev/null 2>/dev/null \
  | openssl x509 -noout -dates -subject -issuer
```

- [ ] New expiry date shown
- [ ] Chain complete
- [ ] **A real client operation succeeds** — a registry pull, an analysis submission, a page load
- [ ] The expiry alert has cleared

The third is the check that matters. `openssl s_client` succeeding proves the certificate is served; it does not prove the clients accept it. **Verify with the actual consumer** — for Harbor, that means a `docker pull` from a runtime host, not a browser.

---

## 4. Consumers That Must Be Updated Too

Renewing the server's certificate is sometimes only half the work.

| If | Then |
| --- | --- |
| Clients pin the certificate or its issuer | Update every client |
| An internal certificate authority issued it and clients trust the CA | Nothing further, unless the CA itself changed |
| A client has its own copy of the certificate | Update it |
| Docker was configured to trust a specific certificate | Update `/etc/docker/certs.d/` on **every runtime host** |

The last row is the one that produces a partial outage: Harbor's certificate is renewed, some hosts pull fine, and others fail — because their trust configuration still references the old certificate.

`TBD` — whether an internal CA is used. It makes renewal a server-side operation only, which is a substantial simplification.

---

## 5. Certificate Already Expired

This is an incident. Follow [incident-response-runbook.md](incident-response-runbook.md) alongside these steps.

```text
1. Establish the blast radius — which consumers are failing
2. Renew immediately per section 3
3. Verify with real client operations
4. Afterwards: find out why the alert did not produce action
```

Step 4 is the important one. An expiry has weeks of warning, so an expired certificate means either the alert did not exist, did not fire, did not reach anyone, or reached someone who did not act. Each has a different fix, and the incident review should identify which.

**Do not disable certificate verification to restore service.** It is the fastest available action and it removes the control entirely — and a verification setting disabled during an incident is rarely re-enabled afterwards. If it is genuinely necessary, it is a recorded, time-bounded exception with an approver.

---

## 6. Private Key Compromised

Different order of operations. **Revoke first.**

```text
1. Issue a new key and certificate
2. Install and verify
3. REVOKE the old certificate
4. Assess what the compromised key could have protected or impersonated
5. Record the incident
```

Renewal alone is not remediation if the key is compromised. The old certificate remains valid until revoked, and anyone holding the key can continue to present it.

---

## 7. Prevention

| Control | Status |
| --- | --- |
| Expiry monitoring with an alert | Defined in [alerting-standard.md](../08-observability/alerting-standard.md); **not implemented** |
| Warning window with enough lead time | `TBD` — 21 days proposed in the alert rules |
| Certificate inventory | `TBD` |
| Automated renewal | `TBD` — see below |

Automated renewal removes the class of failure entirely, and it introduces its own: an automation that silently stops working produces the same outage with less warning. If adopted, monitor the **renewal** as well as the expiry — the alert on expiry is what catches a failed automation.

---

## 8. Open Items

| Item |
| --- |
| `TBD` — certificate management: internal CA or external issuer |
| `TBD` — certificate inventory and its owner |
| `TBD` — expiry monitoring implementation and warning window |
| `TBD` — whether renewal is automated |
| `TBD` — whether clients pin certificates |
| `TBD` — renewal procedure per component, once the approach is chosen |

---

## Related

- [Incident response runbook](incident-response-runbook.md)
- [Network security baseline](../03-network/network-security-baseline.md)
- [Alerting standard](../08-observability/alerting-standard.md)
- [Scheduled maintenance](../../sop/scheduled-maintenance.md)
