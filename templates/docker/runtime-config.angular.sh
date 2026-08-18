#!/bin/sh
# Writes runtime configuration for an Angular application at container start.
#
# This is what makes build-once promotion possible for a frontend. A naive
# Angular build substitutes environment values at COMPILE time, which produces
# a different artifact per environment and breaks the promotion model.
#
# The application must fetch assets/config.json during bootstrap rather than
# importing a compiled environment file.
#
# Runs from /docker-entrypoint.d/ before nginx starts. The base image executes
# these scripts and then execs nginx, so signal handling is unaffected.

set -eu

CONFIG_DIR="/usr/share/nginx/html/assets"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# ADJUST: the values your application needs. Add here and read from
# config.json in the application. Never place a secret here — this file is
# served to the browser, so anything in it is public.
#
# Required values fail the container start rather than falling back to a
# default. A default that points at the wrong environment starts
# successfully and is discovered later, as incorrect behaviour.
: "${API_BASE_URL:?API_BASE_URL is required}"
: "${ENVIRONMENT:?ENVIRONMENT is required}"

# Optional values, with safe defaults. Written as an explicit test rather
# than ${VAR:=default}, because a default containing braces is ambiguous to
# the shell's parameter-expansion parser.
LOG_LEVEL="${LOG_LEVEL:-warn}"
if [ -z "${FEATURE_FLAGS:-}" ]; then
    FEATURE_FLAGS='{}'
fi

mkdir -p "${CONFIG_DIR}"

cat > "${CONFIG_FILE}" <<EOF
{
  "apiBaseUrl": "${API_BASE_URL}",
  "environment": "${ENVIRONMENT}",
  "logLevel": "${LOG_LEVEL}",
  "featureFlags": ${FEATURE_FLAGS}
}
EOF

# Fail fast rather than serving a wrong configuration. A missing required
# value must stop the container, not fall back to a default that might point
# at the wrong environment.
echo "runtime-config: wrote ${CONFIG_FILE} for environment ${ENVIRONMENT}"
