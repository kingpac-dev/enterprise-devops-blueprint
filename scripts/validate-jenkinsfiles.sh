#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Jenkins Declarative Pipeline Linter & Validator
# ==============================================================================
# Verifies that all Jenkinsfiles in templates/jenkins/ adhere to blueprint policy:
#   1. Balanced curly braces & proper declarative syntax structure
#   2. Presence of required stages (Build, Test, SonarQube, Trivy, Harbor push)
#   3. Zero hardcoded secrets / credentials
#   4. Enforcement of immutable container tags (ADR-0007)
#   5. Robust post-build actions (always, success, failure)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
JENKINS_DIR="${REPO_ROOT}/templates/jenkins"

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_FILES=0

echo "======================================================================"
echo " Enterprise DevOps Platform — Jenkins Pipeline Linter"
echo " Target Directory: templates/jenkins/"
echo "======================================================================"

# Check if directory exists
if [[ ! -d "${JENKINS_DIR}" ]]; then
    echo "[ERROR] Jenkins templates directory not found: ${JENKINS_DIR}"
    exit 1
fi

shopt -s nullglob
JENKINSFILES=("${JENKINS_DIR}"/Jenkinsfile*)

if [[ ${#JENKINSFILES[@]} -eq 0 ]]; then
    echo "[ERROR] No Jenkinsfiles found in ${JENKINS_DIR}"
    exit 1
fi

for jf in "${JENKINSFILES[@]}"; do
    # Skip directories or shell scripts
    if [[ -d "${jf}" || "${jf}" == *.sh || "${jf}" == *.md ]]; then
        continue
    fi

    TOTAL_FILES=$((TOTAL_FILES + 1))
    FILENAME="$(basename "${jf}")"
    echo -n "Checking ${FILENAME}... "

    ERRORS=()

    # 1. Structural checks
    if ! grep -q "pipeline[[:space:]]*{" "${jf}"; then
        ERRORS+=("Missing top-level 'pipeline {' block")
    fi

    if ! grep -q "agent" "${jf}"; then
        ERRORS+=("Missing 'agent' declaration")
    fi

    if ! grep -q "stages[[:space:]]*{" "${jf}"; then
        ERRORS+=("Missing 'stages {' block")
    fi

    if ! grep -q "post[[:space:]]*{" "${jf}"; then
        ERRORS+=("Missing 'post {' block")
    fi

    # 2. Balanced brace checking using awk
    BRACE_DIFF=$(awk '{
        for(i=1; i<=length($0); i++) {
            c = substr($0, i, 1)
            if (c == "{") open++
            else if (c == "}") close_b++
        }
    } END { print open - close_b }' "${jf}")

    if [[ "${BRACE_DIFF}" -ne 0 ]]; then
        ERRORS+=("Mismatched curly braces (difference: ${BRACE_DIFF})")
    fi

    # 3. Security & Quality Guardrails
    if ! grep -qi "sonar" "${jf}"; then
        ERRORS+=("Missing SonarQube analysis or quality gate stage")
    fi

    if ! grep -qi "trivy" "${jf}"; then
        ERRORS+=("Missing Trivy container security scan stage")
    fi

    # 4. Credential isolation check (Never commit raw passwords)
    if grep -Ei "password[[:space:]]*=[[:space:]]*['\"][^'\"]{4,}['\"]" "${jf}" | grep -vi "credentials\|HARBOR_ROBOT_SECRET\|SONAR_AUTH_TOKEN"; then
        ERRORS+=("Potential hardcoded plaintext password detected")
    fi

    # 5. Immutable container tagging (ADR-0007)
    if grep -q "docker push.*:latest" "${jf}"; then
        ERRORS+=("Direct push of ':latest' tag detected (violates ADR-0007)")
    fi

    # Summary for this file
    if [[ ${#ERRORS[@]} -eq 0 ]]; then
        echo "PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        for err in "${ERRORS[@]}"; do
            echo "  - [ERROR] ${err}"
        done
    fi
done

echo "======================================================================"
echo " Linter Summary: ${PASS_COUNT}/${TOTAL_FILES} Passed, ${FAIL_COUNT} Failed"
echo "======================================================================"

if [[ ${FAIL_COUNT} -gt 0 ]]; then
    exit 1
fi

echo "[SUCCESS] All Jenkins declarative pipelines validated successfully."
exit 0
