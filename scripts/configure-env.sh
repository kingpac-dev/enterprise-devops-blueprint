#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Platform Environment Configurator
# Implements: docs/02-infrastructure/platform-installation-strategy.md
#             docs/07-security/secrets-management.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infra"
ENV_TEMPLATE="${INFRA_DIR}/.env.example"
TARGET_ENV="${INFRA_DIR}/.env"

DOMAIN="devops.local"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Configures environment variables and generates secure random passwords for the DevOps Platform.

Options:
  -d, --domain <domain>    Platform domain (default: devops.local)
  -f, --force              Overwrite existing infra/.env file
  -n, --non-interactive    Run without user prompts using auto-generated passwords
  --dry-run                Print generated configuration without writing to file
  -h, --help               Show this help message
EOF
    exit 0
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -n|--non-interactive)
            NON_INTERACTIVE=true
            shift
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

generate_password() {
    local length="${1:-32}"
    if command -v openssl &>/dev/null; then
        openssl rand -base64 48 | tr -dc 'A-Za-z0-9!#%*+,-./:;=?@^_~' | head -c "${length}"
    else
        tr -dc 'A-Za-z0-9!#%*+,-./:;=?@^_~' < /dev/urandom | head -c "${length}"
    fi
}

echo "======================================================================"
echo " Enterprise DevOps Platform — Environment Configurator"
echo "======================================================================"

if [[ -f "${TARGET_ENV}" && "${FORCE}" != "true" && "${DRY_RUN}" != "true" ]]; then
    echo "[WARNING] ${TARGET_ENV} already exists."
    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        echo "Use --force to overwrite. Exiting without modifying existing file."
        exit 0
    else
        read -r -p "Do you want to overwrite it? (y/N): " CONFIRM
        if [[ "${CONFIRM}" != [yY] && "${CONFIRM}" != [yY][eE][sS] ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
fi

if [[ "${NON_INTERACTIVE}" != "true" && "${DRY_RUN}" != "true" ]]; then
    read -r -p "Enter platform domain [${DOMAIN}]: " INPUT_DOMAIN
    if [[ -n "${INPUT_DOMAIN}" ]]; then
        DOMAIN="${INPUT_DOMAIN}"
    fi
fi

echo "[INFO] Configuring platform for domain: ${DOMAIN}"
echo "[INFO] Generating cryptographically secure service passwords..."

JENKINS_PW=$(generate_password 24)
POSTGRES_PW=$(generate_password 32)
GRAFANA_PW=$(generate_password 24)
HARBOR_ROBOT_SECRET=$(generate_password 32)

ENV_CONTENT=$(cat <<EOF
# ==============================================================================
# Enterprise DevOps Blueprint — Generated Platform Environment
# Generated on: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Security Notice: Keep this file protected (chmod 600) and NEVER commit to Git.
# ==============================================================================

# Platform Domain and Storage
PLATFORM_DOMAIN=${DOMAIN}
DATA_DIR=/opt/devops-platform/data
CERTS_DIR=/opt/devops-platform/certs
LOGS_DIR=/opt/devops-platform/logs

# Network Configuration
DEV_NETWORK_SUBNET=10.200.1.0/24
TOOLCHAIN_NETWORK_SUBNET=10.200.2.0/24
OBSERVABILITY_NETWORK_SUBNET=10.200.3.0/24

# Jenkins Configuration
JENKINS_VERSION=2.440.3-lts-jdk17
JENKINS_ADMIN_USER=admin
JENKINS_ADMIN_PASSWORD=${JENKINS_PW}
JENKINS_AGENT_PORT=50000

# SonarQube & PostgreSQL Configuration
SONARQUBE_VERSION=10.4.1-community
SONAR_DB_IMAGE=postgres:15-alpine
SONAR_DB_NAME=sonar
SONAR_DB_USER=sonar
SONAR_DB_PASSWORD=${POSTGRES_PW}

# Portainer Configuration
PORTAINER_VERSION=2.20.1

# Observability Configuration
PROMETHEUS_VERSION=v2.51.0
GRAFANA_VERSION=10.4.0
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PW}
LOKI_VERSION=2.9.6
PROMTAIL_VERSION=2.9.6
CADVISOR_VERSION=v0.49.1
NODE_EXPORTER_VERSION=v1.7.0

# Harbor External Integration
HARBOR_DOMAIN=harbor.${DOMAIN}
HARBOR_ROBOT_USER=robot\$\$jenkins-ci
HARBOR_ROBOT_SECRET=${HARBOR_ROBOT_SECRET}
EOF
)

if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    echo "--- Generated Configuration (Dry Run) ---"
    echo "${ENV_CONTENT}"
    echo "-----------------------------------------"
    echo "[SUCCESS] Dry run completed."
    exit 0
fi

echo "${ENV_CONTENT}" > "${TARGET_ENV}"
chmod 600 "${TARGET_ENV}" 2>/dev/null || true

echo "[SUCCESS] Successfully generated configuration: ${TARGET_ENV}"
echo "[NOTE] File permissions set to 600 (read/write by owner only)."
echo ""
echo "Next step: Run 'sudo bash scripts/bootstrap-platform.sh' to launch the platform."
