#!/usr/bin/env bash
# ==============================================================================
# Enterprise DevOps Blueprint — Host Preparation & Hardening Script
# Target OS: Ubuntu 24.04 LTS (x86_64)
# Implements: docs/02-infrastructure/infrastructure-standard.md
#             docs/03-network/firewall-and-port-matrix.md
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Pre-flight Checks
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root (use sudo)." >&2
   exit 1
fi

echo "======================================================================"
echo " Starting Enterprise DevOps Platform Host Preparation..."
echo " Target OS: Ubuntu 24.04 LTS"
echo "======================================================================"

# ------------------------------------------------------------------------------
# 2. Timezone & Clock Synchronization
# ------------------------------------------------------------------------------
echo "[INFO] Setting timezone to UTC..."
timedatectl set-timezone UTC

echo "[INFO] Ensuring systemd-timesyncd is active..."
apt-get update -y
apt-get install -y --no-install-recommends systemd-timesyncd ca-certificates curl gnupg lsb-release ufw jq
systemctl enable --now systemd-timesyncd
timedatectl set-ntp true

# ------------------------------------------------------------------------------
# 3. Kernel Parameters & System Limits (Required for SonarQube & High Throughput)
# ------------------------------------------------------------------------------
echo "[INFO] Applying kernel tuning parameters in /etc/sysctl.d/99-devops-platform.conf..."
cat << 'EOF' > /etc/sysctl.d/99-devops-platform.conf
# SonarQube bundled Elasticsearch requirement
vm.max_map_count=524288

# File descriptor & watch limits
fs.file-max=131072
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=8192

# Network connection backlog tuning
net.core.somaxconn=1024
EOF

sysctl --system > /dev/null

echo "[INFO] Setting security limits in /etc/security/limits.d/99-devops-platform.conf..."
cat << 'EOF' > /etc/security/limits.d/99-devops-platform.conf
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   4096
*       hard    nproc   4096
root    soft    nofile  65536
root    hard    nofile  65536
EOF

# ------------------------------------------------------------------------------
# 4. Install Docker Engine & Compose v2 Plugin
# ------------------------------------------------------------------------------
if ! command -v docker &> /dev/null; then
    echo "[INFO] Installing Docker Engine from official repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    echo "[INFO] Docker Engine installed successfully."
else
    echo "[INFO] Docker is already installed: $(docker --version)"
fi

# ------------------------------------------------------------------------------
# 5. Configure Docker Daemon (/etc/docker/daemon.json)
# ------------------------------------------------------------------------------
echo "[INFO] Configuring /etc/docker/daemon.json per infrastructure standard..."
mkdir -p /etc/docker

cat << 'EOF' > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "default-address-pools": [
    {
      "base": "10.200.0.0/16",
      "size": 24
    }
  ],
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# ------------------------------------------------------------------------------
# 6. Persistent Directories & Ownership Setup
# ------------------------------------------------------------------------------
PLATFORM_BASE="/opt/devops-platform"
echo "[INFO] Creating persistent storage directories under ${PLATFORM_BASE}..."

mkdir -p "${PLATFORM_BASE}/data/jenkins"
mkdir -p "${PLATFORM_BASE}/data/sonarqube/data"
mkdir -p "${PLATFORM_BASE}/data/sonarqube/extensions"
mkdir -p "${PLATFORM_BASE}/data/sonarqube/logs"
mkdir -p "${PLATFORM_BASE}/data/sonarqube/postgresql"
mkdir -p "${PLATFORM_BASE}/data/portainer"
mkdir -p "${PLATFORM_BASE}/data/prometheus"
mkdir -p "${PLATFORM_BASE}/data/grafana"
mkdir -p "${PLATFORM_BASE}/data/loki"
mkdir -p "${PLATFORM_BASE}/certs"
mkdir -p "${PLATFORM_BASE}/logs/nginx"

# Standard UIDs:
# Jenkins: uid 1000, gid 1000
# SonarQube: uid 1000, gid 1000
# PostgreSQL: uid 999 or 70
# Prometheus: uid 65534 (nobody), gid 65534 (nogroup)
# Grafana: uid 472, gid 472
# Loki: uid 10001, gid 10001
chown -R 1000:1000 "${PLATFORM_BASE}/data/jenkins"
chown -R 1000:1000 "${PLATFORM_BASE}/data/sonarqube"
chown -R 999:999 "${PLATFORM_BASE}/data/sonarqube/postgresql"
chown -R 65534:65534 "${PLATFORM_BASE}/data/prometheus"
chown -R 472:472 "${PLATFORM_BASE}/data/grafana"
chown -R 10001:10001 "${PLATFORM_BASE}/data/loki"

# ------------------------------------------------------------------------------
# 7. Host Firewall (UFW) Baseline
# ------------------------------------------------------------------------------
echo "[INFO] Applying baseline host firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing

# Allow administrative SSH
ufw allow 22/tcp comment "SSH administration"

# Allow Ingress Web Traffic (Reverse Proxy)
ufw allow 80/tcp comment "HTTP reverse proxy"
ufw allow 443/tcp comment "HTTPS reverse proxy"

# Enable UFW non-interactively if not already active
if ! ufw status | grep -q "Status: active"; then
    echo "y" | ufw enable
fi

echo "======================================================================"
echo "[SUCCESS] Host preparation complete!"
echo "Docker status:"
docker info --format 'Docker Version: {{.ServerVersion}}, Storage Driver: {{.Driver}}, Live Restore: {{.LiveRestoreEnabled}}'
echo "Sysctl status: vm.max_map_count = $(sysctl -n vm.max_map_count)"
echo "Base directory: ${PLATFORM_BASE}"
echo "======================================================================"
