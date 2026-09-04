#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Master Platform Bootstrap Script
# Implements: docs/02-infrastructure/platform-installation-strategy.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infra"

echo "======================================================================"
echo " Enterprise DevOps Platform — Automated Deployment & Bootstrap"
echo "======================================================================"

# ------------------------------------------------------------------------------
# 1. Prerequisite Checks
# ------------------------------------------------------------------------------
echo "[1/6] Checking system prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker Engine is not installed. Please run scripts/setup-host.sh first." >&2
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "[ERROR] Docker Compose v2 plugin is not installed." >&2
    exit 1
fi

# Verify vm.max_map_count for SonarQube
CURRENT_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
if [[ "${CURRENT_MAP_COUNT}" -lt 262144 ]]; then
    echo "[WARN] vm.max_map_count is ${CURRENT_MAP_COUNT} (must be >= 262144 for SonarQube)."
    echo "[INFO] Attempting to set vm.max_map_count=524288 (requires sudo)..."
    sudo sysctl -w vm.max_map_count=524288 || true
fi

# ------------------------------------------------------------------------------
# 2. Environment Configuration (.env)
# ------------------------------------------------------------------------------
echo "[2/6] Verifying environment configuration..."
if [[ ! -f "${INFRA_DIR}/.env" ]]; then
    echo "[INFO] No .env found. Creating ${INFRA_DIR}/.env from .env.example..."
    cp "${INFRA_DIR}/.env.example" "${INFRA_DIR}/.env"
    
    # Generate random secure passwords for initialization
    RANDOM_PASS_SONAR=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)
    RANDOM_PASS_JENKINS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)
    RANDOM_PASS_GRAFANA=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)

    sed -i "s/ReplaceWithSecureDbPassword123!/${RANDOM_PASS_SONAR}/g" "${INFRA_DIR}/.env"
    sed -i "s/ReplaceWithStrongPassword123!/${RANDOM_PASS_JENKINS}/g" "${INFRA_DIR}/.env"
    sed -i "s/ReplaceWithSecureGrafanaPassword123!/${RANDOM_PASS_GRAFANA}/g" "${INFRA_DIR}/.env"
    echo "[INFO] Generated initial secure passwords in ${INFRA_DIR}/.env"
else
    echo "[INFO] Existing ${INFRA_DIR}/.env file detected."
fi

# Source .env
set -a
# shellcheck disable=SC1091
source "${INFRA_DIR}/.env"
set +a

# ------------------------------------------------------------------------------
# 3. TLS Certificate Generation
# ------------------------------------------------------------------------------
echo "[3/6] Generating TLS Certificates for *.${PLATFORM_DOMAIN}..."
bash "${SCRIPT_DIR}/generate-certs.sh" "${PLATFORM_DOMAIN}" "${INFRA_DIR}/certs"

# ------------------------------------------------------------------------------
# 4. Create Platform Docker Network
# ------------------------------------------------------------------------------
echo "[4/6] Creating internal platform network (devops-platform-net)..."
if ! docker network inspect devops-platform-net &> /dev/null; then
    docker network create \
        --driver bridge \
        --subnet "${TOOLCHAIN_NETWORK_SUBNET:-10.200.2.0/24}" \
        devops-platform-net
    echo "[INFO] Network devops-platform-net created."
else
    echo "[INFO] Network devops-platform-net already exists."
fi

# ------------------------------------------------------------------------------
# 5. Launch Stacks in Sequence
# ------------------------------------------------------------------------------
echo "[5/6] Launching platform services..."

cd "${INFRA_DIR}"

# Step A: Launch Core Toolchain (Jenkins, SonarQube, Portainer)
echo "--- Starting Core Platform Stack (Jenkins, SonarQube, Portainer) ---"
docker compose -f docker-compose.platform.yml up -d --build

echo "[INFO] Waiting for SonarQube and Jenkins healthchecks to report healthy..."
for i in {1..30}; do
    SONAR_STATUS=$(docker inspect --format='{{json .State.Health.Status}}' devops-platform-core-sonarqube-1 2>/dev/null || echo '"unknown"')
    JENKINS_STATUS=$(docker inspect --format='{{json .State.Health.Status}}' devops-platform-core-jenkins-1 2>/dev/null || echo '"unknown"')
    
    echo "  [Poll $i/30] SonarQube: ${SONAR_STATUS}, Jenkins: ${JENKINS_STATUS}"
    if [[ "${SONAR_STATUS}" == '"healthy"' && "${JENKINS_STATUS}" == '"healthy"' ]]; then
        echo "[INFO] Core toolchain is HEALTHY!"
        break
    fi
    sleep 5
done

# Step B: Launch Observability Stack (Prometheus, Grafana, Loki)
echo "--- Starting Observability Stack (Prometheus, Grafana, Loki) ---"
docker compose -f docker-compose.observability.yml up -d

# Step C: Launch Ingress Gateway / Reverse Proxy
echo "--- Starting TLS Reverse Proxy (Nginx) ---"
docker compose -f docker-compose.proxy.yml up -d

# ------------------------------------------------------------------------------
# 6. Final Status & Access Summary
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo " Enterprise DevOps Platform Deployment Completed Successfully!"
echo "======================================================================"
echo ""
echo "Service Endpoints (HTTPS via TLS Ingress Gateway):"
echo "  - Jenkins Controller: https://jenkins.${PLATFORM_DOMAIN}/"
echo "  - SonarQube Server:   https://sonarqube.${PLATFORM_DOMAIN}/"
echo "  - Portainer GitOps:   https://portainer.${PLATFORM_DOMAIN}/"
echo "  - Grafana Dashboards: https://grafana.${PLATFORM_DOMAIN}/"
echo "  - Prometheus Engine:  https://prometheus.${PLATFORM_DOMAIN}/"
echo ""
echo "Initial Credentials (Stored in ${INFRA_DIR}/.env):"
echo "  - Jenkins Admin:   ${JENKINS_ADMIN_USER} / [Password in .env]"
echo "  - SonarQube Admin: admin / admin (Default on first login; reset required)"
echo "  - Grafana Admin:   ${GRAFANA_ADMIN_USER} / [Password in .env]"
echo ""
echo "Local DNS Setup:"
echo "  Add the following line to /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "  127.0.0.1  jenkins.${PLATFORM_DOMAIN} sonarqube.${PLATFORM_DOMAIN} portainer.${PLATFORM_DOMAIN} grafana.${PLATFORM_DOMAIN} prometheus.${PLATFORM_DOMAIN}"
echo ""
echo "Run verification drill:"
echo "  bash scripts/verify-platform.sh"
echo "======================================================================"
