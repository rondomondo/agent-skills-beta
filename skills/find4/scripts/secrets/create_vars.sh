#!/usr/bin/env bash
set -euo pipefail


# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Set DEBUG=true/1 to enable verbose logging via the log() helpers.
USE_LOGGING="${DEBUG:-true}"
case "${USE_LOGGING}" in
  true|1)  USE_LOGGING=true  ;;
  false|0) USE_LOGGING=false ;;
  *) printf "ERROR: DEBUG must be true/false/1/0, got '%s'\n" "${USE_LOGGING}" >&2; exit 1 ;;
esac
SCRIPT_NAME=$(basename "$0")

ok()   { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${GREEN}${*}${RESET}\n"  >&2; return 0; }
warn() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${YELLOW}${*}${RESET}\n" >&2; return 0; }
fail() { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${RED}${*}${RESET}\n"    >&2; return 0; }
log()  { ${USE_LOGGING} && printf "${BOLD}[$SCRIPT_NAME]${RESET} ${CYAN}${*}${RESET}\n"   >&2; return 0; }


DEFAULT_GITHUB_REPO="rondomondo/agent-skills-beta"
DEFAULT_GITHUB_BRANCH="feature-secrets-games"

usage() {
  cat <<EOF
Usage: $(basename "$0") <github-token> [repo] [branch] [test,dev,...]

  Writes GitHub Actions variable definitions to stdout
  repo   default: ${DEFAULT_GITHUB_REPO}
  branch default: ${DEFAULT_GITHUB_BRANCH}
EOF
}

if [[ $# -lt 1 ]]; then
    usage
    exit
fi

GITHUB_TOKEN="$1"
GITHUB_REPO="${2:-${DEFAULT_GITHUB_REPO}}"
GITHUB_BRANCH="${3:-${DEFAULT_GITHUB_BRANCH}}"

GITHUB_BRANCH_GAMES_PROD="${GITHUB_BRANCH}-prod"
GITHUB_BRANCH_GAMES_TEST="${GITHUB_BRANCH}-test"
GITHUB_BRANCH_GAMES_DEV="${GITHUB_BRANCH}-dev"
GITHUB_BRANCH_GAMES_DAVE="${GITHUB_BRANCH}-dave"




if [[ -z "$GITHUB_TOKEN" ]]; then
    fail "Error: GITHUB_TOKEN must not be empty."
    exit 1
fi

cat <<EOF
GITHUB_TOKEN=${GITHUB_TOKEN}
GITHUB_REPO=${GITHUB_REPO}
GITHUB_BRANCH=${GITHUB_BRANCH}
GITHUB_BRANCH_GAMES_PROD=${GITHUB_BRANCH_GAMES_PROD}
GITHUB_BRANCH_GAMES_TEST=${GITHUB_BRANCH_GAMES_TEST}
GITHUB_BRANCH_GAMES_DEV=${GITHUB_BRANCH_GAMES_DEV}
GITHUB_BRANCH_GAMES_DAVE=${GITHUB_BRANCH_GAMES_DAVE}
EOF
