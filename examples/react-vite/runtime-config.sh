#!/bin/sh
# ==============================================================================
# Enterprise DevOps Blueprint — React Runtime Config Injector
# Generates /usr/share/nginx/html/runtime-config.js from environment variables
# at container boot time.
# ==============================================================================

cat <<EOF > /usr/share/nginx/html/runtime-config.js
window.__RUNTIME_CONFIG__ = {
  apiBaseUrl: "${API_BASE_URL:-http://localhost:8080}",
  environment: "${ENVIRONMENT:-dev}",
  enableDiagnostics: ${ENABLE_DIAGNOSTICS:-false},
  version: "${APP_VERSION:-unknown}"
};
EOF

echo "[INFO] Generated /usr/share/nginx/html/runtime-config.js with ENVIRONMENT=${ENVIRONMENT:-dev}"
