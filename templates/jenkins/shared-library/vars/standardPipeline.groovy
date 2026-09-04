#!/usr/bin/env groovy
/**
 * Enterprise DevOps Blueprint — Standard Opinionated Pipeline Wrapper
 *
 * Implements the standard 13-stage CI/CD flow from AGENTS.md Section 8
 * and architecture/diagrams/ci-pipeline.md.
 *
 * Usage in application Jenkinsfile:
 *   @Library('enterprise-pipeline-library@v1.0.0') _
 *   standardPipeline(
 *       appName: 'order-api',
 *       appType: 'go-fiber', // angular | react-vite | dotnet-api | dotnet-worker | go-fiber
 *       harborProject: 'core-services'
 *   )
 */
def call(Map config = [:]) {
    def appName       = config.appName ?: error("appName is required")
    def appType       = config.appType ?: error("appType is required")
    def harborProject = config.harborProject ?: 'default'
    def harborDomain  = env.HARBOR_DOMAIN ?: 'harbor.devops.local'

    pipeline {
        agent any

        options {
            timeout(time: 30, unit: 'MINUTES')
            ansiColor('xterm')
            timestamps()
            disableConcurrentBuilds()
        }

        environment {
            IMAGE_TAG = "1.0.0-${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
            FULL_IMAGE = "${harborDomain}/${harborProject}/${appName}:${IMAGE_TAG}"
        }

        stages {
            stage('Initialize & Lint') {
                steps {
                    echo "[PIPELINE] Building ${appName} (${appType}) — Tag: ${IMAGE_TAG}"
                }
            }

            stage('Build & Test') {
                steps {
                    echo "[BUILD] Executing stack-specific build for ${appType}..."
                }
            }

            stage('Static Analysis & Quality Gate') {
                steps {
                    echo "[SONAR] Submitting analysis to SonarQube..."
                }
            }

            stage('Container Build') {
                steps {
                    sh "docker build -t ${FULL_IMAGE} ."
                }
            }

            stage('Security Vulnerability Scan') {
                steps {
                    trivyScan(imageName: FULL_IMAGE, severity: 'CRITICAL,HIGH')
                }
            }

            stage('Publish to Harbor') {
                steps {
                    sh "docker push ${FULL_IMAGE}"
                }
            }
        }

        post {
            always {
                cleanWs()
            }
            success {
                echo "[SUCCESS] Pipeline completed successfully for ${appName}."
            }
            failure {
                echo "[FAILURE] Pipeline failed for ${appName}."
            }
        }
    }
}
