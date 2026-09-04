#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — GitOps Sync & Asynchronous Verification Controller
# Implements: adr/0010-portainer-gitops-deployment.md
#             architecture/decisions/adr-0010-gitops-convergence-analysis.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_ENV="dev"
APP_NAME="orders-api"
NEW_TAG=""
MANIFEST_FILE=""
WEBHOOK_URL=""
HEALTH_URL=""
TIMEOUT_SECONDS=120
INTERVAL_SECONDS=5
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] --tag <immutable-image-tag>

Deploys a container update via Portainer GitOps, polls health asynchronously,
and performs automated rollback on failure.

Required:
  -t, --tag <tag>           New immutable release tag (e.g., 1.4.2-sha-a82f912)

Options:
  -e, --env <env>           Target environment (dev, uat, prod) [default: dev]
  -a, --app <name>          Application name [default: orders-api]
  -m, --manifest <file>     Path to Compose stack manifest [default: infra/gitops-workloads/<env>/orders-stack.yml]
  -w, --webhook-url <url>   Portainer stack webhook URL
  --health-url <url>        Healthcheck probe URL [default: http://localhost:8081/healthz]
  --timeout <seconds>       Maximum wait time for convergence in seconds [default: 120]
  --interval <seconds>      Poll interval in seconds [default: 5]
  --dry-run                 Simulate deployment and health verification without triggering webhook
  -h, --help                Show this help message
EOF
    exit 0
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--tag)
            NEW_TAG="$2"
            shift 2
            ;;
        -e|--env)
            TARGET_ENV="$2"
            shift 2
            ;;
        -a|--app)
            APP_NAME="$2"
            shift 2
            ;;
        -m|--manifest)
            MANIFEST_FILE="$2"
            shift 2
            ;;
        -w|--webhook-url)
            WEBHOOK_URL="$2"
            shift 2
            ;;
        --health-url)
            HEALTH_URL="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --interval)
            INTERVAL_SECONDS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

if [[ -z "${NEW_TAG}" ]]; then
    echo "ERROR: --tag is required." >&2
    usage
fi

if [[ -z "${MANIFEST_FILE}" ]]; then
    MANIFEST_FILE="${REPO_ROOT}/infra/gitops-workloads/${TARGET_ENV}/orders-stack.yml"
fi

if [[ -z "${HEALTH_URL}" ]]; then
    case "${TARGET_ENV}" in
        prod) HEALTH_URL="http://127.0.0.1:8081/healthz" ;;
        uat)  HEALTH_URL="http://127.0.0.1:8081/healthz" ;;
        *)    HEALTH_URL="http://127.0.0.1:8081/healthz" ;;
    esac
fi

echo "======================================================================"
echo " Portainer GitOps Deployment & Asynchronous Verification"
echo " Target Environment : ${TARGET_ENV}"
echo " Application        : ${APP_NAME}"
echo " New Image Tag      : ${NEW_TAG}"
echo " Manifest File      : ${MANIFEST_FILE}"
echo " Health Probe URL   : ${HEALTH_URL}"
echo " Max Convergence    : ${TIMEOUT_SECONDS}s (interval: ${INTERVAL_SECONDS}s)"
echo "======================================================================"

if [[ ! -f "${MANIFEST_FILE}" ]]; then
    echo "ERROR: Manifest file not found: ${MANIFEST_FILE}" >&2
    exit 1
fi

# 1. Capture current version as rollback baseline
PREVIOUS_TAG=$(grep -E "${APP_NAME}:" "${MANIFEST_FILE}" | sed -E 's/.*:([^"} ]+).*/\1/' | head -n 1 || echo "unknown")
echo "[STEP 1/4] Recorded previous known-good tag: ${PREVIOUS_TAG}"

# 2. Update Manifest with New Tag
echo "[STEP 2/4] Updating manifest with new tag: ${NEW_TAG}"
if [[ "${DRY_RUN}" != "true" ]]; then
    # Cross-platform sed replace
    sed -i.bak -E "s|(${APP_NAME}:)[^\"} ]+|\1${NEW_TAG}|g" "${MANIFEST_FILE}"
    rm -f "${MANIFEST_FILE}.bak"
fi

# 3. Trigger Portainer Webhook
echo "[STEP 3/4] Triggering Portainer Stack Webhook..."
if [[ -n "${WEBHOOK_URL}" && "${DRY_RUN}" != "true" ]]; then
    HTTP_RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${WEBHOOK_URL}" || echo "000")
    if [[ "${HTTP_RESP}" != "200" && "${HTTP_RESP}" != "204" ]]; then
        echo "[ERROR] Portainer webhook failed with HTTP ${HTTP_RESP}."
        echo "[ACTION] Initiating immediate manifest rollback..."
        sed -i.bak -E "s|(${APP_NAME}:)[^\"} ]+|\1${PREVIOUS_TAG}|g" "${MANIFEST_FILE}"
        rm -f "${MANIFEST_FILE}.bak"
        exit 1
    fi
    echo "[INFO] Portainer accepted webhook (HTTP ${HTTP_RESP}). Stack sync queued."
else
    echo "[INFO] Webhook trigger skipped (Dry-run or WEBHOOK_URL not configured)."
fi

# 4. Asynchronous Convergence & Health Polling
echo "[STEP 4/4] Monitoring asynchronous service convergence..."
START_TIME=$(date +%s)
CONVERGED=false

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [[ "${ELAPSED}" -ge "${TIMEOUT_SECONDS}" ]]; then
        break
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "[DRY-RUN] Simulating health probe at ${HEALTH_URL}... OK"
        CONVERGED=true
        break
    fi

    PROBE_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 5 "${HEALTH_URL}" || echo "000")
    
    if [[ "${PROBE_CODE}" == "200" ]]; then
        echo "[SUCCESS] Health probe returned HTTP 200 (Elapsed: ${ELAPSED}s)."
        CONVERGED=true
        break
    else
        echo "[POLL] Health probe returned HTTP ${PROBE_CODE}. Waiting ${INTERVAL_SECONDS}s (Elapsed: ${ELAPSED}/${TIMEOUT_SECONDS}s)..."
        sleep "${INTERVAL_SECONDS}"
    fi
done

# 5. Handle Outcome & Automated Rollback
if [[ "${CONVERGED}" == "true" ]]; then
    echo "======================================================================"
    echo " [DEPLOYMENT SUCCESSFUL]"
    echo " Workload converged to version ${NEW_TAG} successfully."
    echo "======================================================================"
    exit 0
else
    echo "======================================================================"
    echo " [DEPLOYMENT FAILED — TIMEOUT AFTER ${TIMEOUT_SECONDS}s]"
    echo " Workload failed to pass health verification."
    echo " [ACTION] Triggering automated GitOps rollback to ${PREVIOUS_TAG}..."
    echo "======================================================================"

    if [[ "${DRY_RUN}" != "true" ]]; then
        sed -i.bak -E "s|(${APP_NAME}:)[^\"} ]+|\1${PREVIOUS_TAG}|g" "${MANIFEST_FILE}"
        rm -f "${MANIFEST_FILE}.bak"
        
        if [[ -n "${WEBHOOK_URL}" ]]; then
            echo "[ROLLBACK] Re-triggering Portainer webhook for rollback tag..."
            curl -s -X POST "${WEBHOOK_URL}" > /dev/null || true
        fi
        echo "[ROLLBACK] Manifest reverted to ${PREVIOUS_TAG}."
    fi

    exit 1
fi
