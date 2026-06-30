#!/usr/bin/env bash
# secrets.sh - Runtime secrets loader for skills running in the Anthropic Claude sandbox.
#
# WHY THIS EXISTS
# Skills run inside a sandboxed environment where real environment variables
# (e.g. GITHUB_TOKEN, SLACK_TOKEN, AWS_ACCESS_KEY_ID) are not available.
# This script bridges that gap: it decrypts a local .secrets.enc file and
# exports the secrets into the current shell session so skill scripts can
# interact with external services (GitHub, Slack, AWS, etc.) without storing
# plaintext credentials anywhere on disk.
#
# IMPORTANT: SOURCE this file - do not execute it. Requires bash 4+.
# If your login shell is zsh, this script bridges to bash automatically.
#
# HOW IT WORKS
#   1. If all required vars are already set in the environment, skip decryption.
#   2. Otherwise locate .secrets.enc via (in order):
#        a. SKILL_SECRETS_FILE env var (explicit path)
#        b. Piped stdin (source secrets.sh < .secrets.enc)
#        c. Walk up from CWD until .secrets.enc is found
#        d. Same directory as this script
#   3. Prompt once for the master passphrase, decrypt, and export all secrets.
#   4. Unset the passphrase and plaintext buffer immediately after.
#
# USAGE
#   SKILL_SECRETS_VARS="GITHUB_TOKEN SLACK_TOKEN"   # declare what you need
#   source "$(dirname "$0")/secrets.sh"
#   # $GITHUB_TOKEN and $SLACK_TOKEN are now available
#
# ALTERNATIVE INVOCATIONS
#   source scripts/secrets/secrets.sh < .secrets.enc
#   SKILL_SECRETS_FILE=~/.secrets.enc source scripts/secrets/secrets.sh
#   SKILL_SECRETS_RELOAD=1 source scripts/secrets/secrets.sh
#
# SECURITY PROPERTIES
#   - Passphrase never passed as a CLI arg (uses env:OPENSSL_PASS, unexported)
#   - Passphrase variable unset immediately after use
#   - Decrypted JSON held in a variable only long enough to parse, then unset
#   - No temp files during decryption (all in-memory via process substitution)
#   - set -x safe: xtrace is suppressed around sensitive sections

# If sourced from zsh, bridge via a bash subshell and import the exported vars
if [ -n "${ZSH_VERSION:-}" ]; then
    _ss_self="${${(%):-%x}:A}"
    _ss_tmp="$(mktemp)"
    SKILL_SECRETS_RELOAD="${SKILL_SECRETS_RELOAD:-}" \
    SKILL_SECRETS_FILE="${SKILL_SECRETS_FILE:-}" \
    SKILL_SECRETS_VARS="${SKILL_SECRETS_VARS:-}" \
        bash -c "source '${_ss_self}' && export -p" 2>&1 1>"${_ss_tmp}"
    _ss_rc=$?
    if [[ ${_ss_rc} -eq 0 ]]; then
        while IFS= read -r _ss_line; do
            [[ "${_ss_line}" == declare\ -x\ _* ]] && continue
            [[ "${_ss_line}" == declare\ -x\ BASH* ]] && continue
            if [[ "${_ss_line}" == declare\ -x\ *=* ]]; then
                _ss_key="${_ss_line#declare -x }"
                _ss_key="${_ss_key%%=*}"
                _ss_val="${_ss_line#*=\"}"
                _ss_val="${_ss_val%\"}"
                export "${_ss_key}"="${_ss_val}"
            fi
        done < "${_ss_tmp}"
        _SKILL_SECRETS_LOADED=1
    else
        cat "${_ss_tmp}" >&2
    fi
    rm -f "${_ss_tmp}"
    _ss_ret=${_ss_rc}
    unset _ss_self _ss_tmp _ss_rc _ss_line _ss_key _ss_val
    return ${_ss_ret}
fi

# Enforce bash for all other non-bash shells
if [ -z "${BASH_VERSION:-}" ]; then
    echo "ERROR: secrets.sh must be sourced from bash or zsh." >&2
    return 1 2>/dev/null || exit 1
fi

# Guard: don't source twice (override with SKILL_SECRETS_RELOAD=1)
if [[ "${_SKILL_SECRETS_LOADED:-}" == "1" && "${SKILL_SECRETS_RELOAD:-}" != "1" ]]; then
    echo "secrets.sh: already loaded. To force a reload: SKILL_SECRETS_RELOAD=1 source scripts/secrets/secrets.sh" >&2
    return 1
fi
unset SKILL_SECRETS_RELOAD _SKILL_SECRETS_LOADED

_SECRETS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers (die, read_passphrase, openssl_decrypt, etc.)
# shellcheck source=./_lib.sh
source "${_SECRETS_SCRIPT_DIR}/_lib.sh"

# Caller sets SKILL_SECRETS_VARS before sourcing, e.g.:
#   SKILL_SECRETS_VARS="GITHUB_TOKEN OTHER_SECRET"
# If not set, we decrypt and export everything in the file.
_SECRETS_VARS="${SKILL_SECRETS_VARS:-}"

# Check if all required vars are already in environment
_secrets_all_present=1
if [[ -n "${_SECRETS_VARS}" ]]; then
    for _secrets_var in ${_SECRETS_VARS}; do
        if [[ -z "${!_secrets_var:-}" ]]; then
            _secrets_all_present=0
            break
        fi
    done
else
    _secrets_all_present=0
fi
if [[ "${_secrets_all_present}" == "1" ]]; then
    echo "secrets.sh: all required vars already present in environment -- skipping decryption." >&2
    unset _secrets_all_present _SECRETS_VARS _secrets_var _SECRETS_SCRIPT_DIR SKILL_SECRETS_FILE SKILL_SECRETS_VARS
    _SKILL_SECRETS_LOADED=1
    return 0
fi
unset _secrets_all_present

# Resolve the encrypted secrets file -- four fallback strategies
_SECRETS_FILE=""
_SECRETS_STDIN=0

if [[ -n "${SKILL_SECRETS_FILE:-}" ]]; then
    _SECRETS_FILE="${SKILL_SECRETS_FILE}"
    if [[ ! -f "${_SECRETS_FILE}" ]]; then
        echo "ERROR: secrets.sh -- SKILL_SECRETS_FILE not found: ${_SECRETS_FILE}" >&2
        unset _SECRETS_SCRIPT_DIR _SECRETS_FILE _SECRETS_VARS _secrets_var _SECRETS_STDIN SKILL_SECRETS_FILE SKILL_SECRETS_VARS
        return 1
    fi
elif [[ ! -t 0 ]]; then
    _SECRETS_STDIN=1
    _SECRETS_FILE="-"
else
    _secrets_search_dir="${PWD}"
    while [[ "${_secrets_search_dir}" != "/" ]]; do
        if [[ -f "${_secrets_search_dir}/.secrets.enc" ]]; then
            _SECRETS_FILE="${_secrets_search_dir}/.secrets.enc"
            break
        fi
        _secrets_search_dir="$(dirname "${_secrets_search_dir}")"
    done
    unset _secrets_search_dir
    if [[ -z "${_SECRETS_FILE}" ]]; then
        _SECRETS_FILE="${_SECRETS_SCRIPT_DIR}/.secrets.enc"
    fi
    if [[ ! -f "${_SECRETS_FILE}" ]]; then
        echo "ERROR: secrets.sh -- .secrets.enc not found. Set SKILL_SECRETS_FILE, pipe via stdin, or place .secrets.enc in the skill root." >&2
        echo "Run seal_secrets.sh to create it." >&2
        unset _SECRETS_SCRIPT_DIR _SECRETS_FILE _SECRETS_VARS _secrets_var _SECRETS_STDIN SKILL_SECRETS_FILE SKILL_SECRETS_VARS
        return 1
    fi
fi

# Disable xtrace around the sensitive section so the passphrase never hits logs
{ _secrets_xtrace=0; [[ "${-}" == *x* ]] && _secrets_xtrace=1 && set +x; }

# Guard against mid-execution signals leaving plaintext vars in the environment.
# Save the caller's EXIT trap so we can restore it after the sensitive section.
_secrets_old_exit_trap="$(trap -p EXIT)"
_secrets_old_int_trap="$(trap -p INT)"
_secrets_old_term_trap="$(trap -p TERM)"
trap 'unset _SECRETS_PASS _SECRETS_JSON _secrets_stripped' EXIT INT TERM

echo "" >&2
echo "Skill secrets required. Enter master passphrase to unlock:" >&2
read_passphrase _SECRETS_PASS

_SECRETS_JSON="$(openssl_decrypt "${_SECRETS_FILE}" "${_SECRETS_PASS}")"
_secrets_rc=$?
unset _SECRETS_PASS

# Restore caller's traps now that the passphrase is gone
eval "${_secrets_old_exit_trap:-trap - EXIT}"
eval "${_secrets_old_int_trap:-trap - INT}"
eval "${_secrets_old_term_trap:-trap - TERM}"
unset _secrets_old_exit_trap _secrets_old_int_trap _secrets_old_term_trap

if [[ ${_secrets_rc} -ne 0 ]] || [[ -z "${_SECRETS_JSON}" ]]; then
    echo "ERROR: Decryption failed -- wrong passphrase or corrupted .secrets.enc" >&2
    unset _SECRETS_JSON _secrets_rc _SECRETS_FILE _SECRETS_SCRIPT_DIR _SECRETS_VARS _secrets_var _SECRETS_STDIN SKILL_SECRETS_FILE SKILL_SECRETS_VARS
    [[ "${_secrets_xtrace}" == "1" ]] && set -x
    unset _secrets_xtrace
    return 1
fi
unset _secrets_rc

# Parse flat JSON object {"KEY":"value",...} and export each key
_secrets_stripped="${_SECRETS_JSON#\{}"
_secrets_stripped="${_secrets_stripped%\}}"
unset _SECRETS_JSON

_secrets_loaded=0
IFS=',' read -ra _secrets_pairs <<< "${_secrets_stripped}"
unset _secrets_stripped
_secrets_total=${#_secrets_pairs[@]}

for _secrets_pair in "${_secrets_pairs[@]}"; do
    _secrets_pair="${_secrets_pair#"${_secrets_pair%%[! ]*}"}"
    _secrets_key="${_secrets_pair#\"}"
    _secrets_key="${_secrets_key%%\"*}"
    _secrets_val="${_secrets_pair#*:\"}"
    _secrets_val="${_secrets_val%\"}"
    if [[ -n "${_secrets_key}" ]]; then
        if [[ -n "${!_secrets_key:-}" ]]; then
            echo "  warning: ${_secrets_key} was already set in environment -- overriding" >&2
        fi
        export "${_secrets_key}"="${_secrets_val}"
        (( _secrets_loaded++ )) || true
    fi
    unset _secrets_key _secrets_val _secrets_pair
done
unset _secrets_pairs

[[ "${_secrets_xtrace}" == "1" ]] && set -x
unset _secrets_xtrace

echo "  ${_secrets_loaded} secret(s) loaded." >&2

if ([[ "${IS_SANDBOX:-no}" == "yes" ]] || [[ "${IS_SANDBOX:-no}" == "1" ]] || [[ "${IS_SANDBOX:-no}" == "true" ]]) && (( _secrets_loaded == _secrets_total )); then
    export IS_SANDBOX_DECRYPTED=1
fi

unset _secrets_loaded _secrets_total _SECRETS_FILE _SECRETS_SCRIPT_DIR _SECRETS_VARS _secrets_var _SECRETS_STDIN SKILL_SECRETS_FILE SKILL_SECRETS_VARS
_SKILL_SECRETS_LOADED=1
