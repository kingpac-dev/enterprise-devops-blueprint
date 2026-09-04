#!/usr/bin/env groovy
/**
 * Enterprise DevOps Blueprint — Reusable GitOps Deployment Step
 *
 * Implements ADR-0010 pull-based deployment:
 * Updates deployment repository manifest, triggers Portainer webhook,
 * asynchronously polls health endpoint, and triggers automatic rollback on failure.
 *
 * Parameters:
 *   - environment: 'dev', 'uat', or 'prod'
 *   - manifestPath: Path to compose.yml inside deployment repo
 *   - imageTag: Immutable release tag to deploy
 *   - webhookUrl: Portainer Stack update webhook URL
 *   - healthUrl: Public/internal service health check endpoint
 */
def call(Map config = [:]) {
    def envName      = config.environment ?: error("environment parameter is required")
    def manifestPath = config.manifestPath ?: error("manifestPath parameter is required")
    def imageTag     = config.imageTag ?: error("imageTag parameter is required")
    def webhookUrl   = config.webhookUrl ?: env.PORTAINER_WEBHOOK_URL
    def healthUrl    = config.healthUrl ?: ""

    echo "[GITOPS] Initiating pull-based deployment to ${envName} (Tag: ${imageTag})..."

    sh """
        bash ./templates/jenkins/deploy-gitops.sh \
            --env "${envName}" \
            --manifest "${manifestPath}" \
            --tag "${imageTag}" \
            --webhook "${webhookUrl}" \
            --health-url "${healthUrl}"
    """
}
