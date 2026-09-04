#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — TLS SAN Certificate Generator
# Generates a Root CA and SAN SSL/TLS certificates for internal platform services:
# - jenkins.<domain>
# - sonarqube.<domain>
# - portainer.<domain>
# - grafana.<domain>
# - harbor.<domain>
# ==============================================================================

set -euo pipefail
export MSYS_NO_PATHCONV=1

DOMAIN="${1:-devops.local}"
TARGET_DIR="${2:-./infra/certs}"
DAYS_VALID=825

echo "======================================================================"
echo " Generating Internal TLS Certificates for domain: *.${DOMAIN}"
echo " Output directory: ${TARGET_DIR}"
echo "======================================================================"

mkdir -p "${TARGET_DIR}"

CA_KEY="${TARGET_DIR}/ca.key"
CA_CRT="${TARGET_DIR}/ca.crt"
SERVER_KEY="${TARGET_DIR}/tls.key"
SERVER_CSR="${TARGET_DIR}/tls.csr"
SERVER_CRT="${TARGET_DIR}/tls.crt"
SAN_CONF="${TARGET_DIR}/openssl-san.cnf"

# ------------------------------------------------------------------------------
# 1. Generate Root CA (if not existing)
# ------------------------------------------------------------------------------
if [[ ! -f "${CA_KEY}" || ! -f "${CA_CRT}" ]]; then
    echo "[INFO] Creating Internal Root CA..."
    openssl genrsa -out "${CA_KEY}" 4096
    openssl req -x509 -new -nodes -key "${CA_KEY}" -sha256 -days 3650 \
        -out "${CA_CRT}" \
        -subj "/C=TH/ST=Bangkok/O=Enterprise DevOps/OU=Platform Engineering/CN=Enterprise DevOps Root CA"
    echo "[INFO] Root CA created: ${CA_CRT}"
else
    echo "[INFO] Existing Root CA found, reusing: ${CA_CRT}"
fi

# ------------------------------------------------------------------------------
# 2. Generate Server Private Key
# ------------------------------------------------------------------------------
echo "[INFO] Generating Server Private Key..."
openssl genrsa -out "${SERVER_KEY}" 2048

# ------------------------------------------------------------------------------
# 3. Create OpenSSL SAN Configuration
# ------------------------------------------------------------------------------
cat << EOF > "${SAN_CONF}"
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = TH
ST = Bangkok
O = Enterprise DevOps
OU = Platform Engineering
CN = *.${DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
DNS.3 = jenkins.${DOMAIN}
DNS.4 = sonarqube.${DOMAIN}
DNS.5 = portainer.${DOMAIN}
DNS.6 = grafana.${DOMAIN}
DNS.7 = harbor.${DOMAIN}
DNS.8 = prometheus.${DOMAIN}
DNS.9 = loki.${DOMAIN}
DNS.10 = localhost
IP.1 = 127.0.0.1
EOF

# ------------------------------------------------------------------------------
# 4. Generate Certificate Signing Request (CSR)
# ------------------------------------------------------------------------------
openssl req -new -key "${SERVER_KEY}" -out "${SERVER_CSR}" -config "${SAN_CONF}"

# ------------------------------------------------------------------------------
# 5. Sign Server Certificate with Root CA
# ------------------------------------------------------------------------------
echo "[INFO] Signing Server Certificate with Root CA..."
openssl x509 -req -in "${SERVER_CSR}" -CA "${CA_CRT}" -CAkey "${CA_KEY}" \
    -CAcreateserial -out "${SERVER_CRT}" -days "${DAYS_VALID}" -sha256 \
    -extfile "${SAN_CONF}" -extensions req_ext

# Clean up CSR & cnf
rm -f "${SERVER_CSR}" "${SAN_CONF}"

# Set read permissions
chmod 644 "${SERVER_CRT}" "${CA_CRT}"
chmod 600 "${SERVER_KEY}" "${CA_KEY}"

echo "======================================================================"
echo "[SUCCESS] Certificates generated successfully in ${TARGET_DIR}:"
echo "  - Root CA Certificate: ${CA_CRT}"
echo "  - Server Certificate:  ${SERVER_CRT}"
echo "  - Server Private Key:  ${SERVER_KEY}"
echo ""
echo "To trust this CA on Linux hosts / Docker engines:"
echo "  sudo cp ${CA_CRT} /usr/local/share/ca-certificates/devops-ca.crt"
echo "  sudo update-ca-certificates"
echo "======================================================================"
