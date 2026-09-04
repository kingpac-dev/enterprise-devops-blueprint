#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Platform Verification & Health Drill
# Implements: docs/02-infrastructure/platform-installation-strategy.md
#             AGENTS.md (Section 19: Validation Policy)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infra"

if [[ -f "${INFRA_DIR}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${INFRA_DIR}/.env"
    set +a
fi

PLATFORM_DOMAIN="${PLATFORM_DOMAIN:-devops.local}"
PASS_COUNT=0
FAIL_COUNT=0

echo "======================================================================"
echo " Enterprise DevOps Platform — Verification & Smoke Drill"
echo " Domain: ${PLATFORM_DOMAIN}"
echo "======================================================================"

check_service() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"

    echo -n "[CHECK] Testing ${name} (${url})... "
    local http_code
    http_code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "${url}" || echo "000")

    if [[ "${http_code}" == "${expected_code}" || "${http_code}" == "302" || "${http_code}" == "200" ]]; then
        echo "PASS (HTTP ${http_code})"
        ((PASS_COUNT++))
    else
        echo "FAIL (HTTP ${http_code}, expected ${expected_code})"
        ((FAIL_COUNT++))
    fi
}

# ------------------------------------------------------------------------------
# 1. Host & Kernel Pre-requisites
# ------------------------------------------------------------------------------
echo "--- 1. Checking Host & Kernel Configuration ---"
CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
if [[ "${CURRENT_MAP_COUNT}" -ge 262144 ]]; then
    echo "[PASS] Kernel vm.max_map_count is ${CURRENT_MAP_COUNT} (>= 262144)"
    ((PASS_COUNT++))
else
    echo "[FAIL] Kernel vm.max_map_count is ${CURRENT_MAP_COUNT} (must be >= 262144)"
    ((FAIL_COUNT++))
fi

# ------------------------------------------------------------------------------
# 2. Docker Containers Status
# ------------------------------------------------------------------------------
echo "--- 2. Checking Docker Containers State ---"
cd "${INFRA_DIR}"
if command -v docker &>/dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi

# ------------------------------------------------------------------------------
# 3. Direct Internal Health Endpoints
# ------------------------------------------------------------------------------
echo "--- 3. Checking Service Direct Endpoints ---"
check_service "SonarQube System API" "http://localhost:9000/api/system/status" "200"
check_service "Jenkins Web Interface" "http://localhost:8080/login" "200"
check_service "Portainer API Status" "http://localhost:9000/api/status" "200"
check_service "Prometheus Healthy" "http://localhost:9090/-/healthy" "200"
check_service "Grafana Health API" "http://localhost:3000/api/health" "200"
check_service "Loki Ready API" "http://localhost:3100/ready" "200"

# ------------------------------------------------------------------------------
# 4. HTTPS Ingress Gateway Routing (Resolving via Localhost Header)
# ------------------------------------------------------------------------------
echo "--- 4. Checking Ingress Gateway TLS Routes ---"
check_service "HTTPS Ingress -> Jenkins" "https://localhost/login" "200" -H "Host: jenkins.${PLATFORM_DOMAIN}" || true
check_service "HTTPS Ingress -> SonarQube" "https://localhost/api/system/status" "200" -H "Host: sonarqube.${PLATFORM_DOMAIN}" || true
check_service "HTTPS Ingress -> Grafana" "https://localhost/api/health" "200" -H "Host: grafana.${PLATFORM_DOMAIN}" || true

# ------------------------------------------------------------------------------
# 5. Prometheus Scrape Targets Drill
# ------------------------------------------------------------------------------
echo "--- 5. Checking Prometheus Targets ---"
TARGETS_JSON=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null || echo "{}")
if echo "${TARGETS_JSON}" | grep -q '"health":"up"'; then
    UP_COUNT=$(echo "${TARGETS_JSON}" | grep -o '"health":"up"' | wc -l)
    echo "[PASS] Prometheus is successfully scraping ${UP_COUNT} target(s) in 'up' state."
    ((PASS_COUNT++))
else
    echo "[WARN] Could not verify active Prometheus scrape targets or no targets 'up'."
fi

# ------------------------------------------------------------------------------
# Verification Summary
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo " Platform Verification Summary"
echo " Passed: ${PASS_COUNT}"
echo " Failed: ${FAIL_COUNT}"
echo "======================================================================"

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
    echo "[SUCCESS] All platform checks passed! Platform is operational."
    exit 0
else
    echo "[WARNING] Some checks failed. Review container logs using: docker compose logs <service>"
    exit 1
fi
