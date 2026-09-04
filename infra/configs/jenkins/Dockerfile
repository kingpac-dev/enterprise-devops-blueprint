# ==============================================================================
# Enterprise DevOps Blueprint — Custom Jenkins Controller Image
# Implements: docs/05-ci-cd/jenkins-architecture.md
# ==============================================================================

FROM jenkins/jenkins:2.440.3-lts-jdk17

USER root

# Install system dependencies, Docker CLI, and Trivy
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        jq \
        git && \
    # Add Docker official repo for CLI tools
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Add Aquasecurity repo for Trivy
    curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" | \
    tee /etc/apt/sources.list.d/trivy.list > /dev/null && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        docker-ce-cli \
        trivy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add jenkins user to docker group (GID will map to host docker socket)
RUN groupadd -g 999 docker || true && usermod -aG docker jenkins

# Copy pinned plugin list and install via plugin manager
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Return to jenkins user
USER jenkins

# Disable setup wizard since configuration is managed via JCasC
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dorg.apache.commons.jelly.tags.core.expr.InstantExpression.CACHE_SIZE=1000"
ENV CASC_JENKINS_CONFIG="/var/jenkins_home/casc_configs/jenkins.yaml"
