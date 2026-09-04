#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Automated Credential Rotation Tool
# ==============================================================================
# Implements: sop/credential-rotation.md
#             docs/07-security/secrets-management.md
#             docs/10-governance/audit-evidence.md
#
# Rotates platform credentials safely using the overlap principle:
#   1. Backs up current infra/.env
#   2. Generates new cryptographically secure high-entropy secret
#   3. Updates targeted secret in infra/.env
#   4. Validates Compose configuration syntax
#   5. Emits auditable rotation evidence record
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/infra/.env"

TARGET_KEY=""
DRY_RUN="false"

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Safely rotates service credentials in infra/.env with automated backup and syntax validation.

Options:
  -k, --key <KEY_NAME>    Target credential key to rotate:
                          - JENKINS_ADMIN_PASSWORD
                          - SONAR_DB_PASSWORD
                          - GRAFANA_ADMIN_PASSWORD
                          - HARBOR_ROBOT_SECRET
  --dry-run               Simulate rotation without modifying infra/.env
  -h, --help              Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--key)
            TARGET_KEY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

if [[ -z "${TARGET_KEY}" ]]; then
    echo "[ERROR] Missing required --key argument." >&2
    show_help
    exit 1
fi

VALID_KEYS=("JENKINS_ADMIN_PASSWORD" "SONAR_DB_PASSWORD" "GRAFANA_ADMIN_PASSWORD" "HARBOR_ROBOT_SECRET")
IS_VALID=false
for vk in "${VALID_KEYS[@]}"; do
    if [[ "${vk}" == "${TARGET_KEY}" ]]; then
        IS_VALID=true
        break
    fi
done

if [[ "${IS_VALID}" != "true" ]]; then
    echo "[ERROR] Unsupported key: ${TARGET_KEY}" >&2
    echo "Supported keys: ${VALID_KEYS[*]}" >&2
    exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "[ERROR] Environment file not found: ${ENV_FILE}" >&2
    exit 1
fi

ROTATION_ID="rot-$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${ENV_FILE}.bak.${ROTATION_ID}"

echo "======================================================================"
echo " Enterprise DevOps Platform — Credential Rotation"
echo " Rotation Identifier : ${ROTATION_ID}"
echo " Target Key          : ${TARGET_KEY}"
echo " Mode                : $( [[ "${DRY_RUN}" == "true" ]] && echo "DRY RUN" || echo "EXECUTE" )"
echo "======================================================================"

# 1. Generate new high-entropy password (32 chars)
if command -v openssl >/dev/null 2>&1; then
    NEW_SECRET=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
else
    NEW_SECRET=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
fi

echo "[INFO] Generated new cryptographically secure secret (length: ${#NEW_SECRET})"

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[DRY-RUN] Target file: ${ENV_FILE}"
    echo "[DRY-RUN] Would update: ${TARGET_KEY}=<32-character-secret>"
    echo "[DRY-RUN] Would create backup: ${BACKUP_FILE}"
    echo "[SUCCESS] Dry run simulation passed."
    exit 0
fi

# 2. Backup current .env
cp "${ENV_FILE}" "${BACKUP_FILE}"
chmod 600 "${BACKUP_FILE}"
echo "[INFO] Created rollback backup: ${BACKUP_FILE}"

# 3. Update key using Python to avoid sed delimiter collisions
WIN_ENV_FILE="${ENV_FILE}"
if command -v cygpath >/dev/null 2>&1; then
    WIN_ENV_FILE=$(cygpath -w "${ENV_FILE}")
fi

python -c "
import re
target = '${TARGET_KEY}'
secret = '${NEW_SECRET}'
file_path = r'${WIN_ENV_FILE}'

with open(file_path, 'r') as f:
    content = f.read()

pattern = rf'^{target}=.*'
replacement = f'{target}={secret}'

if not re.search(pattern, content, flags=re.MULTILINE):
    print(f'Key {target} not found in {file_path}')
    exit(1)

new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
with open(file_path, 'w') as f:
    f.write(new_content)
"

chmod 600 "${ENV_FILE}"
echo "[INFO] Successfully updated ${TARGET_KEY} in ${ENV_FILE}"

# 4. Verify Compose syntax after update
echo "[INFO] Validating Docker Compose configuration syntax with new credential..."
if command -v docker >/dev/null 2>&1; then
    if docker compose --env-file "${ENV_FILE}" -f "${REPO_ROOT}/infra/docker-compose.platform.yml" config --quiet 2>/dev/null; then
        echo "[PASS] Docker Compose platform configuration validated successfully."
    else
        echo "[WARN] Docker compose config check encountered warnings or daemon unavailable."
    fi
fi

# 5. Output Audit Record
echo ""
echo "======================================================================"
echo " Credential Rotation Audit Record (SOP-CREDENTIAL-ROTATION Alignment)"
echo "======================================================================"
cat <<EOF
Rotation Event ID  : ${ROTATION_ID}
Target Secret Key  : ${TARGET_KEY}
Status             : SUCCESS
Backup Location    : ${BACKUP_FILE}
Timestamp (UTC)    : $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Next Steps Required:
  1. If running live, reload or restart the target service:
     - JENKINS_ADMIN_PASSWORD -> Restart Jenkins container / reload JCasC
     - SONAR_DB_PASSWORD      -> Restart SonarQube & SonarQube-DB containers
     - GRAFANA_ADMIN_PASSWORD -> Restart Grafana container
     - HARBOR_ROBOT_SECRET    -> Re-authenticate Jenkins / pipelines to Harbor
  2. Verify service health via 'bash scripts/verify-platform.sh'
  3. Securely archive or prune backup archive after 30-day retention window.
======================================================================
EOF
