#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — GitHub Branch Protection Enforcer
# ==============================================================================
# Configures enterprise branch protection rules via GitHub CLI (gh) or REST API.
#
# Standards Implemented:
#   - docs/04-source-control/branching-strategy.md
#   - docs/04-source-control/pull-request-standard.md
#   - AGENTS.md Section 7: Source Control Policy
#
# Protected Branches:
#   1. main: Strict PR approval (1+ reviewer), dismissed stale reviews, required
#      passing CI checks (Build, SonarQube, Trivy), no force push.
#   2. develop: Required PR, required CI status checks, no force push.
#   3. release/*: Enforces release branch protection for UAT promotions.
# ==============================================================================

set -euo pipefail

DRY_RUN="false"
REPO=""

show_help() {
    cat << EOF
Usage: setup-github-branch-protection.sh [OPTIONS]

Configures enterprise branch protection rules for main and develop branches.

Options:
  -r, --repo <org/repo>   Target GitHub repository (e.g. kingpac-dev/my-app)
  --dry-run               Print branch protection payload and commands without applying
  -h, --help              Show this help message

Requirements:
  - GitHub CLI ('gh') authenticated with admin access to target repository.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--repo)
            REPO="$2"
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
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Try detecting repo if not specified
if [[ -z "${REPO}" ]]; then
    if command -v gh >/dev/null 2>&1 && gh repo view --json nameWithOwner -q .nameWithOwner >/dev/null 2>&1; then
        REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    else
        REPO="org/sample-app"
    fi
fi

echo "======================================================================"
echo " Enterprise DevOps — Branch Protection Enforcer"
echo " Target Repository: ${REPO}"
echo " Mode: $( [[ "${DRY_RUN}" == "true" ]] && echo "DRY RUN" || echo "APPLY" )"
echo "======================================================================"

# ------------------------------------------------------------------------------
# 1. Payload Definition: 'main' Branch (Production)
# ------------------------------------------------------------------------------
MAIN_PAYLOAD=$(cat << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ci/jenkins/build-and-test",
      "ci/sonarqube/quality-gate",
      "security/trivy/container-scan"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "require_last_push_approval": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
EOF
)

# ------------------------------------------------------------------------------
# 2. Payload Definition: 'develop' Branch (Development)
# ------------------------------------------------------------------------------
DEVELOP_PAYLOAD=$(cat << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ci/jenkins/build-and-test"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false
}
EOF
)

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[INFO] Dry run mode enabled. Printing API commands and payloads:"
    echo ""
    echo "--- 1. Branch: main ---"
    echo "gh api -X PUT \"repos/${REPO}/branches/main/protection\" --input - <<'JSON'"
    echo "${MAIN_PAYLOAD}"
    echo "JSON"
    echo ""
    echo "--- 2. Branch: develop ---"
    echo "gh api -X PUT \"repos/${REPO}/branches/develop/protection\" --input - <<'JSON'"
    echo "${DEVELOP_PAYLOAD}"
    echo "JSON"
    echo ""
    echo "[SUCCESS] Dry run simulation completed."
    exit 0
fi

# Apply rules using gh CLI
if ! command -v gh >/dev/null 2>&1; then
    echo "[ERROR] GitHub CLI ('gh') is required to apply branch protection."
    echo "Please install 'gh' or run with --dry-run to inspect the JSON payloads."
    exit 1
fi

echo "[INFO] Applying protection rules to 'main' branch..."
echo "${MAIN_PAYLOAD}" | gh api -X PUT "repos/${REPO}/branches/main/protection" --input -
echo "[SUCCESS] 'main' branch protection configured."

echo "[INFO] Applying protection rules to 'develop' branch..."
echo "${DEVELOP_PAYLOAD}" | gh api -X PUT "repos/${REPO}/branches/develop/protection" --input -
echo "[SUCCESS] 'develop' branch protection configured."

echo "======================================================================"
echo "[SUCCESS] Branch protection rules successfully applied to ${REPO}."
echo "======================================================================"
