#!/bin/sh
# =========================================================================
# deploy-gitops.sh — pull-based deployment step.
#
# Implements: adr/0010-portainer-gitops-deployment.md
#             docs/05-ci-cd/deployment-repository-standard.md
#
# This script does NOT connect to a runtime host. It updates the desired
# state in the deployment repository, asks Portainer to synchronize, and
# then WAITS FOR CONVERGENCE — which is the part a push-based deployment
# does not need and a pull-based one cannot work without.
#
# Without convergence verification the pipeline cannot answer "did it
# deploy?", and automatic rollback has nothing to trigger on.
#
# On failure it reverts the desired state and pushes again, which is the
# rollback: Portainer converges back to the previous version.
#
# USAGE
#   deploy-gitops.sh --service NAME --version TAG --environment ENV
#
# REQUIRED ENVIRONMENT
#   DEPLOY_REPO_URL      Deployment repository, https form
#   DEPLOY_REPO_TOKEN    Token with write access to it ONLY
#   PORTAINER_WEBHOOK    Stack webhook for this environment
#
# OPTIONAL ENVIRONMENT
#   CONVERGE_TIMEOUT     Seconds to wait for convergence   (default 300)
#   CONVERGE_INTERVAL    Seconds between checks            (default 10)
#   VERSION_PROBE        Command printing the RUNNING version. See below
#   DEPLOY_BRANCH        Branch to commit to               (default main)
#   SKIP_ROLLBACK        Set to 1 to leave a failed deploy in place
#
# EXIT CODES
#   0  deployed and converged
#   1  usage or precondition failure — nothing changed
#   2  push failed — nothing deployed
#   3  did not converge; rolled back
#   4  did not converge; rollback ALSO failed  <- page someone
# =========================================================================

set -eu

# --- defaults ------------------------------------------------------------
CONVERGE_TIMEOUT="${CONVERGE_TIMEOUT:-300}"
CONVERGE_INTERVAL="${CONVERGE_INTERVAL:-10}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-main}"
SKIP_ROLLBACK="${SKIP_ROLLBACK:-0}"
PUSH_RETRIES=5

SERVICE=""
VERSION=""
ENVIRONMENT=""
WORKDIR=""

log()  { echo "[deploy] $*"; }
# $1 = message, $2 = exit code. Uses $1, not $*, or the exit code is
# printed as part of the message.
fail() { echo "[deploy] ERROR: $1" >&2; exit "${2:-1}"; }

cleanup() {
    if [ -n "${WORKDIR}" ] && [ -d "${WORKDIR}" ]; then
        rm -rf "${WORKDIR}"
    fi
}
trap cleanup EXIT

# --- arguments -----------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --service)     SERVICE="$2";     shift 2 ;;
        --version)     VERSION="$2";     shift 2 ;;
        --environment) ENVIRONMENT="$2"; shift 2 ;;
        *) fail "unknown argument: $1" ;;
    esac
done

[ -n "${SERVICE}" ]     || fail "--service is required"
[ -n "${VERSION}" ]     || fail "--version is required"
[ -n "${ENVIRONMENT}" ] || fail "--environment is required"

: "${DEPLOY_REPO_URL:?DEPLOY_REPO_URL is required}"
: "${DEPLOY_REPO_TOKEN:?DEPLOY_REPO_TOKEN is required}"
: "${PORTAINER_WEBHOOK:?PORTAINER_WEBHOOK is required}"

# The tag must be immutable. `latest` here is not merely bad practice:
# Portainer Community Edition cannot force an image re-pull, so a moving tag
# redeploys the OLD image and reports success. See adr/0010.
case "${VERSION}" in
    latest|"")  fail "refusing to deploy '${VERSION}': the tag must be immutable" ;;
esac

# The key this service's tag is stored under, in the environment's env file.
# Convention: SERVICE_NAME uppercased, hyphens to underscores, _VERSION.
#   orders-api  ->  ORDERS_API_VERSION
VERSION_KEY="$(echo "${SERVICE}" | tr '[:lower:]-' '[:upper:]_')_VERSION"

log "service=${SERVICE} version=${VERSION} environment=${ENVIRONMENT} key=${VERSION_KEY}"

# --- clone ---------------------------------------------------------------
WORKDIR="$(mktemp -d)"

# set +x so the token is not echoed. Jenkins runs sh with -x in many
# configurations, which would place the token in a build log that is widely
# readable and long-lived.
set +x
AUTH_URL="$(echo "${DEPLOY_REPO_URL}" | sed "s|https://|https://x-access-token:${DEPLOY_REPO_TOKEN}@|")"
git clone --depth 1 --branch "${DEPLOY_BRANCH}" "${AUTH_URL}" "${WORKDIR}/repo" >/dev/null 2>&1 \
    || fail "cannot clone the deployment repository" 1
set -x 2>/dev/null || true
set +x

cd "${WORKDIR}/repo"
git config user.name  "ci-deploy"
git config user.email "ci-deploy@example.internal"   # TBD

ENV_FILE="${ENVIRONMENT}/stack.env"
[ -f "${ENV_FILE}" ] || fail "${ENV_FILE} not found in the deployment repository" 1

# --- read the current value ---------------------------------------------
# The previous version IS the rollback target, and it is captured BEFORE any
# change — determining it afterwards, from a system that may already be
# failing, is how rollbacks get stuck.
PREVIOUS="$(grep "^${VERSION_KEY}=" "${ENV_FILE}" | head -1 | cut -d= -f2- || true)"
[ -n "${PREVIOUS}" ] || fail "${VERSION_KEY} not found in ${ENV_FILE}" 1

log "previous=${PREVIOUS}"

if [ "${PREVIOUS}" = "${VERSION}" ]; then
    log "already at ${VERSION}; skipping commit, still verifying convergence"
    SKIP_COMMIT=1
else
    SKIP_COMMIT=0
fi

# --- update -------------------------------------------------------------
if [ "${SKIP_COMMIT}" = "0" ]; then
    # Anchored replacement of one key. sed on YAML would be fragile; on a
    # KEY=VALUE file with an anchored pattern it is exact — and the result is
    # verified below rather than assumed.
    TMP="$(mktemp)"
    sed "s|^${VERSION_KEY}=.*$|${VERSION_KEY}=${VERSION}|" "${ENV_FILE}" > "${TMP}"
    mv "${TMP}" "${ENV_FILE}"

    # Verify the write did exactly what was intended. A sed edit that is
    # checked afterwards is safe; one that is assumed is not.
    WROTE="$(grep "^${VERSION_KEY}=" "${ENV_FILE}" | head -1 | cut -d= -f2-)"
    [ "${WROTE}" = "${VERSION}" ] \
        || fail "write verification failed: expected ${VERSION}, file contains ${WROTE}" 1

    # Exactly one line for this key, so nothing shadows it.
    COUNT="$(grep -c "^${VERSION_KEY}=" "${ENV_FILE}")"
    [ "${COUNT}" = "1" ] || fail "${VERSION_KEY} appears ${COUNT} times in ${ENV_FILE}" 1

    # The commit message IS the deployment record. Git history in this
    # repository is the audit trail — see adr/0010.
    git add "${ENV_FILE}"
    git commit --quiet -m "deploy(${ENVIRONMENT}): ${SERVICE} ${PREVIOUS} -> ${VERSION}" \
                       -m "service:  ${SERVICE}" \
                       -m "from:     ${PREVIOUS}" \
                       -m "to:       ${VERSION}" \
                       -m "pipeline: ${BUILD_URL:-unknown}"

    # Retry on conflict. Two pipelines can update this repository at the same
    # moment; a rebase resolves it because they touch different keys.
    i=1
    while [ "${i}" -le "${PUSH_RETRIES}" ]; do
        if git push --quiet origin "HEAD:${DEPLOY_BRANCH}" 2>/dev/null; then
            log "pushed (attempt ${i})"
            break
        fi
        if [ "${i}" = "${PUSH_RETRIES}" ]; then
            fail "push failed after ${PUSH_RETRIES} attempts; nothing deployed" 2
        fi
        log "push rejected, rebasing (attempt ${i})"
        git fetch --quiet origin "${DEPLOY_BRANCH}"
        git rebase --quiet "origin/${DEPLOY_BRANCH}" || fail "rebase conflict; resolve manually" 2
        i=$((i + 1))
    done
fi

# --- trigger -------------------------------------------------------------
set +x
log "calling the Portainer webhook"
curl --fail --silent --show-error --request POST "${PORTAINER_WEBHOOK}" >/dev/null \
    || log "WARNING: webhook call failed. Portainer will still converge on its polling interval, so continuing to wait."

# --- wait for convergence ------------------------------------------------
# THIS IS THE STEP THAT DOES NOT EXIST IN A PUSH MODEL.
#
# "The pipeline finished" and "the host converged" are different moments.
# Without waiting here there is nothing to verify and automatic rollback has
# no trigger.
#
# VERSION_PROBE must print the version currently RUNNING. It is supplied by
# the caller because the right probe differs per platform — see
# docs/05-ci-cd/deployment-repository-standard.md for the options and their
# trade-offs.
if [ -z "${VERSION_PROBE:-}" ]; then
    log "WARNING: VERSION_PROBE is not set. Convergence is NOT verified."
    log "WARNING: this deployment's outcome is unknown and will be recorded as success."
    exit 0
fi

log "waiting for convergence (timeout ${CONVERGE_TIMEOUT}s)"
ELAPSED=0
CONVERGED=0
while [ "${ELAPSED}" -lt "${CONVERGE_TIMEOUT}" ]; do
    RUNNING="$(sh -c "${VERSION_PROBE}" 2>/dev/null || true)"
    if [ "${RUNNING}" = "${VERSION}" ]; then
        CONVERGED=1
        log "converged after ${ELAPSED}s: running ${RUNNING}"
        break
    fi
    log "  ${ELAPSED}s: running='${RUNNING}' want='${VERSION}'"
    sleep "${CONVERGE_INTERVAL}"
    ELAPSED=$((ELAPSED + CONVERGE_INTERVAL))
done

if [ "${CONVERGED}" = "1" ]; then
    log "SUCCESS ${SERVICE} ${VERSION} in ${ENVIRONMENT}"
    exit 0
fi

# --- rollback ------------------------------------------------------------
log "DID NOT CONVERGE within ${CONVERGE_TIMEOUT}s"

if [ "${SKIP_COMMIT}" = "1" ]; then
    fail "no change was made, so there is nothing to roll back. The running version does not match the desired state — investigate." 3
fi

if [ "${SKIP_ROLLBACK}" = "1" ]; then
    fail "SKIP_ROLLBACK is set; leaving ${VERSION} as the desired state" 3
fi

log "rolling back to ${PREVIOUS}"

TMP="$(mktemp)"
sed "s|^${VERSION_KEY}=.*$|${VERSION_KEY}=${PREVIOUS}|" "${ENV_FILE}" > "${TMP}"
mv "${TMP}" "${ENV_FILE}"

git add "${ENV_FILE}"
git commit --quiet -m "rollback(${ENVIRONMENT}): ${SERVICE} ${VERSION} -> ${PREVIOUS}" \
                   -m "reason:   did not converge within ${CONVERGE_TIMEOUT}s" \
                   -m "pipeline: ${BUILD_URL:-unknown}"

i=1
while [ "${i}" -le "${PUSH_RETRIES}" ]; do
    if git push --quiet origin "HEAD:${DEPLOY_BRANCH}" 2>/dev/null; then
        break
    fi
    if [ "${i}" = "${PUSH_RETRIES}" ]; then
        # The desired state still names a version that did not converge, and
        # the pipeline could not correct it. This needs a person.
        fail "ROLLBACK PUSH FAILED. Desired state still names ${VERSION}. Manual intervention required." 4
    fi
    git fetch --quiet origin "${DEPLOY_BRANCH}"
    git rebase --quiet "origin/${DEPLOY_BRANCH}" || fail "ROLLBACK REBASE CONFLICT. Manual intervention required." 4
    i=$((i + 1))
done

curl --fail --silent --show-error --request POST "${PORTAINER_WEBHOOK}" >/dev/null || true

log "rolled back to ${PREVIOUS}. Recovery is NOT yet verified — the caller must confirm it."
exit 3
