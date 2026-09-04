#!/usr/bin/env groovy
/**
 * Enterprise DevOps Blueprint — Reusable Trivy Vulnerability Scan Step
 *
 * Scans container images for vulnerabilities, generates SARIF/JSON reports,
 * and enforces quality gate exit codes.
 *
 * Parameters:
 *   - imageName: Full container image name and tag (e.g. harbor.devops.local/core/api:1.0.0)
 *   - severity: Comma-separated severity list (default: 'CRITICAL,HIGH')
 *   - exitCode: Exit code when vulnerabilities found (0 = warn, 1 = block, default: 1)
 */
def call(Map config = [:]) {
    def imageName = config.imageName ?: error("imageName parameter is required for trivyScan")
    def severity  = config.severity ?: 'CRITICAL,HIGH'
    def exitCode  = config.exitCode != null ? config.exitCode : 1

    echo "[SECURITY] Running Trivy vulnerability scan on ${imageName} (Severity: ${severity})..."

    sh """
        trivy image \
            --severity "${severity}" \
            --exit-code ${exitCode} \
            --no-progress \
            --format table \
            "${imageName}"
    """
}
