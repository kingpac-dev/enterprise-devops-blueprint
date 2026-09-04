#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — GitOps Deployment Repository Initializer
# Implements: adr/0010-portainer-gitops-deployment.md
#             docs/05-ci-cd/deployment-repository-standard.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infra"

TARGET_DIR="${1:-${REPO_ROOT}/../devops-deployments}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [TARGET_DIRECTORY]

Initializes a dedicated, isolated GitOps Deployment Repository for Portainer stacks
as mandated by ADR-0010.

Default target: ${TARGET_DIR}
EOF
    exit 0
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

echo "======================================================================"
echo " Enterprise DevOps Blueprint — GitOps Repository Initializer"
echo " Target Location : ${TARGET_DIR}"
echo "======================================================================"

mkdir -p "${TARGET_DIR}/environments/dev" \
         "${TARGET_DIR}/environments/uat" \
         "${TARGET_DIR}/environments/prod" \
         "${TARGET_DIR}/webhooks" \
         "${TARGET_DIR}/policies"

# 1. Copy Workload Stacks from Blueprint
echo "[1/4] Copying stack manifests for DEV, UAT, and PROD..."
cp "${INFRA_DIR}/gitops-workloads/dev/orders-stack.yml" "${TARGET_DIR}/environments/dev/orders-stack.yml"
cp "${INFRA_DIR}/gitops-workloads/uat/orders-stack.yml" "${TARGET_DIR}/environments/uat/orders-stack.yml"
cp "${INFRA_DIR}/gitops-workloads/prod/orders-stack.yml" "${TARGET_DIR}/environments/prod/orders-stack.yml"

# 2. Generate Environment Variable Placeholders
echo "[2/4] Generating environment variable templates..."
cat << 'EOF' > "${TARGET_DIR}/environments/dev/.env.example"
# DEV Environment Variables
ASPNETCORE_ENVIRONMENT=Development
DB_CONNECTION_STRING=Host=dev-db;Database=orders;Username=orders_app;Password=devpass
JWT_SIGNING_KEY=dev-insecure-key-for-local-testing-only-12345
ORDERS_API_VERSION=latest-dev
ORDERS_WORKER_VERSION=latest-dev
EOF

cat << 'EOF' > "${TARGET_DIR}/environments/uat/.env.example"
# UAT Environment Variables
ASPNETCORE_ENVIRONMENT=Staging
DB_CONNECTION_STRING=ReplaceWithUatDbConnectionString
JWT_SIGNING_KEY=ReplaceWithUatSecureJwtSigningKey
ORDERS_API_VERSION=1.4.2-sha-a82f912
ORDERS_WORKER_VERSION=1.4.2-sha-a82f912
EOF

cat << 'EOF' > "${TARGET_DIR}/environments/prod/.env.example"
# PROD Environment Variables
ASPNETCORE_ENVIRONMENT=Production
DB_CONNECTION_STRING=ReplaceWithProductionSecureDbConnectionString
JWT_SIGNING_KEY=ReplaceWithProductionSecureJwtSigningKey
ORDERS_API_VERSION=1.4.2
ORDERS_WORKER_VERSION=1.4.2
EOF

# 3. Create Policy and Webhook Documentation
echo "[3/4] Writing branch protection and Portainer webhook guides..."
cat << 'EOF' > "${TARGET_DIR}/policies/branch-protection.md"
# GitOps Deployment Repository — Branch Protection Policy

## Rules
1. **`main` Branch**:
   - Required Pull Request reviews: Minimum 1 designated release engineer.
   - Restrict pushes: Only CI/CD automation account (`jenkins-robot`) may push directly to release branches.
2. **Environment Mapping**:
   - `environments/dev/` : Synchronized by Portainer DEV stack.
   - `environments/uat/` : Synchronized by Portainer UAT stack.
   - `environments/prod/`: Synchronized by Portainer PROD stack.
EOF

cat << 'EOF' > "${TARGET_DIR}/webhooks/portainer-webhooks.md"
# Portainer GitOps Webhook Setup Guide

In Portainer UI:
1. Navigate to **Stacks** > Select Stack (e.g. `orders-prod`).
2. Enable **Auto-update** via Webhook.
3. Copy the generated Webhook URL (format: `https://portainer.devops.local/api/stacks/webhooks/...`).
4. Save the Webhook URL into Jenkins Credentials (`PORTAINER_WEBHOOK_PROD`).
5. Jenkins triggers this webhook using `scripts/gitops-sync-and-verify.sh`.
EOF

# 4. Generate README & .gitignore
echo "[4/4] Writing GitOps README and .gitignore..."
cat << 'EOF' > "${TARGET_DIR}/.gitignore"
.env
.env.*
!.env.example
secrets/
*.key
*.pem
EOF

cat << 'EOF' > "${TARGET_DIR}/README.md"
# Organization GitOps Deployments Repository

Dedicated deployment repository managed via Portainer GitOps as specified in ADR-0010.

## Repository Layout
```text
environments/
├── dev/          <- Synchronized to DEV runtime
├── uat/          <- Synchronized to UAT runtime
└── prod/         <- Synchronized to PROD runtime
```

## How It Works
1. CI Pipeline in application repo builds and publishes immutable image to Harbor.
2. CI Pipeline commits new tag to this repository.
3. CI Pipeline calls Portainer Stack Webhook.
4. Portainer pulls updated manifest and executes container update.
EOF

echo "======================================================================"
echo "[SUCCESS] Dedicated GitOps Deployment Repository scaffolded at:"
echo "          ${TARGET_DIR}"
echo "======================================================================"
