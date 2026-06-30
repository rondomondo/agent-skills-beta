#!/usr/bin/env bash
# seal_secrets.sh - Encrypt secrets into a .secrets.enc file for a skill.
# Run this ONCE locally to store tokens. Never commit .secrets.enc without
# understanding it is AES-256 encrypted; the passphrase is the only protection.
#
# Usage:
#   ./seal_secrets.sh                      # interactive, writes .secrets.enc into same directory as this script
#   create_vars.sh TOKEN | ./seal_secrets.sh   # pipe K=V pairs; passphrase still prompted from terminal

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

guard_no_xtrace

# Wipe temp files and sensitive vars on any exit path (normal, error, Ctrl-C)
trap 'cleanup_tmpfiles; unset _PASS1 _PASS2' EXIT INT TERM

SKILL_DIR="${SCRIPT_DIR}/../.."
OUT_FILE="${SCRIPT_DIR}/.secrets.enc"

echo ""
echo "skill-secrets: seal_secrets.sh"
echo ""
echo "This will encrypt your secrets and write:"
echo "  ${OUT_FILE}"
echo ""
echo "Choose a strong master passphrase. You will need it every"
echo "session to unlock secrets in Claude's sandbox."
echo ""

read_passphrase _PASS1 "Master passphrase: "
read_passphrase _PASS2 "Confirm passphrase: "

if [[ "${_PASS1}" != "${_PASS2}" ]]; then
    unset _PASS1 _PASS2
    die "Passphrases do not match."
fi
unset _PASS2

validate_passphrase "${_PASS1}"

if [[ -t 0 ]]; then
    echo ""
    echo "Enter secrets as NAME=value pairs (one per line)."
    echo "Press Ctrl-D when done."
    echo "Example:  GITHUB_TOKEN=ghp_abc123..."
    echo ""
fi

_JSON="$(build_json)"

_TMPJSON="$(mktemp)"
register_tmpfile "${_TMPJSON}"
printf '%s' "${_JSON}" > "${_TMPJSON}"
unset _JSON

openssl_encrypt "${_TMPJSON}" "${OUT_FILE}" "${_PASS1}"
unset _PASS1
chmod 0600 "${OUT_FILE}"

echo ""
echo "Encrypted secrets written to: ${OUT_FILE}"
echo ""
echo "Next steps:"
echo "  1. Add .secrets.enc to your skill directory (safe to commit)"
echo "  2. Add .gitignore entries for any plaintext drafts you may have made"
echo "  3. Source secrets.sh in your skill script to decrypt at runtime"
echo ""
