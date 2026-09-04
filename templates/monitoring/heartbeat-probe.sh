#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Prometheus External Heartbeat Probe
# Implements: templates/monitoring/dead-mans-snitch.md
# ==============================================================================

set -euo pipefail

PROMETHEUS_URL="http://localhost:9090/-/healthy"
SNITCH_URL=""
TIMEOUT=5

usage() {
    cat <<EOF
Usage: $(basename "$0") --snitch-url <url> [OPTIONS]

Checks Prometheus health and signals an external Dead Man's Snitch service.

Options:
  -s, --snitch-url <url>      External heartbeat receiver URL (Healthchecks.io / Uptime Kuma)
  -p, --prometheus-url <url>  Internal Prometheus health endpoint [default: http://localhost:9090/-/healthy]
  -t, --timeout <seconds>     Probe timeout in seconds [default: 5]
  -h, --help                  Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--snitch-url)
            SNITCH_URL="$2"
            shift 2
            ;;
        -p|--prometheus-url)
            PROMETHEUS_URL="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
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

if [[ -z "${SNITCH_URL}" ]]; then
    echo "ERROR: --snitch-url is required." >&2
    exit 1
fi

# 1. Probe Prometheus healthy endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "${TIMEOUT}" --max-time "${TIMEOUT}" "${PROMETHEUS_URL}" || echo "000")

if [[ "${HTTP_STATUS}" == "200" ]]; then
    # 2. Ping external snitch
    PING_RESP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "${TIMEOUT}" --max-time "${TIMEOUT}" "${SNITCH_URL}" || echo "000")
    if [[ "${PING_RESP}" =~ ^2 ]]; then
        echo "[HEARTBEAT OK] Prometheus healthy, snitch pinged successfully (HTTP ${PING_RESP})."
        exit 0
    else
        echo "[WARN] Prometheus is healthy, but failed to ping snitch (HTTP ${PING_RESP})." >&2
        exit 2
    fi
else
    echo "[CRITICAL] Prometheus health check failed (HTTP ${HTTP_STATUS}). Snitch not pinged to trigger alert." >&2
    exit 1
fi
