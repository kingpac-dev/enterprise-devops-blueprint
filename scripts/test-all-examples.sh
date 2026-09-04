#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Comprehensive Examples Test Suite Runner
# Validates all 5 application reference stacks mandated by AGENTS.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"

TOTAL_SUITES=5
PASSED_SUITES=0
FAILED_SUITES=0

echo "======================================================================"
echo " Enterprise DevOps Blueprint — Reference Application Verification"
echo " Testing all 5 stacks: Angular, React+Vite, .NET API, Go Fiber, Worker"
echo "======================================================================"

run_suite() {
    local name="$1"
    local dir="$2"
    local cmd="$3"

    echo ""
    echo ">>> Running Suite: ${name} in ${dir}..."
    local start_ts
    start_ts=$(date +%s)
    
    if (cd "${dir}" && eval "${cmd}"); then
        local end_ts
        end_ts=$(date +%s)
        local duration=$((end_ts - start_ts))
        echo "[PASS] ${name} succeeded (${duration}s)"
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        local end_ts
        end_ts=$(date +%s)
        local duration=$((end_ts - start_ts))
        echo "[FAIL] ${name} failed (${duration}s)" >&2
        FAILED_SUITES=$((FAILED_SUITES + 1))
    fi
}

# 1. Angular Frontend Typecheck
run_suite "Angular Frontend (Typecheck)" \
    "${EXAMPLES_DIR}/angular" \
    "npm run typecheck"

# 2. React + Vite Frontend Unit Tests & Build
run_suite "React + Vite Frontend (Vitest & Build)" \
    "${EXAMPLES_DIR}/react-vite" \
    "npm test -- --run && npm run build"

# 3. .NET Web API Unit Tests
run_suite ".NET Web API (Orders.Api.Tests)" \
    "${EXAMPLES_DIR}/dotnet-api" \
    "dotnet test tests/Orders.Api.Tests --nologo -v q"

# 4. .NET Worker Service Unit Tests
run_suite ".NET Worker Service (Orders.Worker.Tests)" \
    "${EXAMPLES_DIR}/dotnet-worker" \
    "dotnet test tests/Orders.Worker.Tests --nologo -v q"

# 5. Go Fiber Web API Unit Tests
run_suite "Go Fiber Web API (go test)" \
    "${EXAMPLES_DIR}/go-fiber" \
    "go test ./..."

# Summary
echo ""
echo "======================================================================"
echo " Application Verification Summary"
echo " Passed : ${PASSED_SUITES}/${TOTAL_SUITES}"
echo " Failed : ${FAILED_SUITES}/${TOTAL_SUITES}"
echo "======================================================================"

if [[ "${FAILED_SUITES}" -eq 0 ]]; then
    echo "[SUCCESS] All 5 application reference stacks verified and operational!"
    exit 0
else
    echo "[FAILURE] Some application stacks failed verification." >&2
    exit 1
fi
