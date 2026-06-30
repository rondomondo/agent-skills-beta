#!/usr/bin/env bash
# trigger_workflow.sh -- Example skill script: triggers a GitHub Actions workflow.
# Demonstrates safe secret loading via secrets.sh.
#
# Usage:
#   ./trigger_workflow.sh <owner/repo> <workflow-file> [ref]
#   ./trigger_workflow.sh myorg/myrepo deploy.yml main

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Set DEBUG=true/1 to enable verbose logging via the log() helpers.
USE_LOGGING="${DEBUG:-false}"
case "${USE_LOGGING}" in
  true|1)  USE_LOGGING=true  ;;
  false|0) USE_LOGGING=false ;;
  *) printf "ERROR: DEBUG must be true/false/1/0, got '%s'\n" "${USE_LOGGING}" >&2; exit 1 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ok()   { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${GREEN}${*}${RESET}\n"  >&2; return 0; }
warn() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${YELLOW}${*}${RESET}\n" >&2; return 0; }
fail() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${RED}${*}${RESET}\n"    >&2; return 0; }
log()  { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${CYAN}${*}${RESET}\n"   >&2; return 0; }

# Wipe temp files and unset token on any exit path (normal, error, Ctrl-C)
trap 'cleanup_tmpfiles; unset GITHUB_TOKEN' EXIT INT TERM

REPO="${1:?Usage: $0 <owner/repo> <workflow> [ref]}"
WORKFLOW="${2:?Workflow filename required}"
REF="${3:-main}"

# Declare which vars this skill needs; secrets.sh skips decryption if they are
# already in the environment (e.g. local dev with GITHUB_TOKEN exported).
SKILL_SECRETS_VARS="GITHUB_TOKEN"
# shellcheck source=./secrets.sh
source "${SCRIPT_DIR}/secrets.sh" || die "Secret load failed."

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    die "GITHUB_TOKEN not available after secret load."
fi

echo "Triggering: ${REPO} / ${WORKFLOW} @ ${REF}"

_GH_RESP_FILE="$(mktemp)"
register_tmpfile "${_GH_RESP_FILE}"

HTTP_STATUS=$(curl -s -o "${_GH_RESP_FILE}" -w "%{http_code}" \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches" \
    -d "{\"ref\":\"${REF}\"}")

unset GITHUB_TOKEN

case "${HTTP_STATUS}" in
    204)
        echo "Workflow triggered successfully (HTTP 204)."
        ;;
    404)
        echo "ERROR: Repo or workflow not found (HTTP 404). Check ${REPO} / ${WORKFLOW}" >&2
        cat "${_GH_RESP_FILE}" >&2
        exit 1
        ;;
    422)
        echo "ERROR: Validation failed (HTTP 422). Is '${REF}' a valid ref?" >&2
        cat "${_GH_RESP_FILE}" >&2
        exit 1
        ;;
    *)
        echo "ERROR: Unexpected HTTP ${HTTP_STATUS}" >&2
        cat "${_GH_RESP_FILE}" >&2
        exit 1
        ;;
esac
