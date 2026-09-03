#!/bin/sh
# Writes runtime configuration for a React + Vite application at container
# start.
#
# WHY THIS EXISTS
#
# Vite substitutes `import.meta.env.VITE_*` at BUILD time. A stock setup
# produces a different bundle per environment, so the artifact deployed to
# production is not the artifact UAT verified — which breaks the promotion
# model the whole delivery design rests on.
#
# The application must fetch /config.json during bootstrap rather than
# reading import.meta.env for anything environment-specific.
#
# Runs from /docker-entrypoint.d/ before nginx starts. The base image
# executes these scripts and then execs nginx, so signal handling is
# unaffected.

set -eu

CONFIG_DIR="/usr/share/nginx/html"
CONFIG_FILE="${CONFIG_DIR}/config.json"

# ADJUST: the values your application needs.
#
# NEVER place a secret here — this file is served to the browser, so
# anything in it is public. An API key that the browser needs is a key that
# the browser's user has.
#
# Required values fail the container start rather than falling back to a
# default. A default that points at the wrong environment starts
# successfully and is discovered later, as incorrect behaviour.
: "${API_BASE_URL:?API_BASE_URL is required}"
: "${ENVIRONMENT:?ENVIRONMENT is required}"

# Optional values, with safe defaults. Written as explicit tests rather than
# ${VAR:=default}, because a default containing braces is ambiguous to the
# shell's parameter-expansion parser.
LOG_LEVEL="${LOG_LEVEL:-warn}"
APP_VERSION="${APP_VERSION:-unknown}"
if [ -z "${FEATURE_FLAGS:-}" ]; then
    FEATURE_FLAGS='{}'
fi

mkdir -p "${CONFIG_DIR}"

cat > "${CONFIG_FILE}" <<EOF
{
  "apiBaseUrl": "${API_BASE_URL}",
  "environment": "${ENVIRONMENT}",
  "logLevel": "${LOG_LEVEL}",
  "appVersion": "${APP_VERSION}",
  "featureFlags": ${FEATURE_FLAGS}
}
EOF

echo "runtime-config: wrote ${CONFIG_FILE} for environment ${ENVIRONMENT}"
