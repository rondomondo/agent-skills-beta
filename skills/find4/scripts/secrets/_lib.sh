#!/usr/bin/env bash
# _lib.sh -- Shared helpers for the skill-secrets toolkit.
# SOURCE this file; do not execute it directly. Requires bash 4+.
#
# Provides:
#   die MESSAGE [EXIT_CODE]           -- print to stderr and exit
#   guard_no_xtrace                   -- abort if set -x is active
#   validate_passphrase PASS          -- enforce minimum length
#   read_passphrase VAR_NAME [PROMPT] -- read silently into named variable
#   openssl_encrypt IN OUT PASS       -- AES-256-CBC PBKDF2 encrypt file
#   openssl_decrypt IN PASS           -- AES-256-CBC PBKDF2 decrypt to stdout
#   build_json                        -- read KEY=value pairs from stdin; print JSON
#   register_tmpfile FILE             -- track a temp file for cleanup on exit
#   cleanup_tmpfiles                  -- zero-wipe and remove all registered temp files
#
# Trap pattern for executed scripts (not sourced):
#   trap 'cleanup_tmpfiles; unset MY_SENSITIVE_VAR' EXIT INT TERM

_LIB_MIN_PASS_LEN=6
_LIB_OPENSSL_CIPHER="-aes-256-cbc"
_LIB_OPENSSL_KDF="-pbkdf2 -iter 200000"

_LIB_TMPFILES=()

die() {
    local msg="${1:-Fatal error}"
    local code="${2:-1}"
    echo "ERROR: ${msg}" >&2
    exit "${code}"
}

guard_no_xtrace() {
    if [[ "${-}" == *x* ]]; then
        die "Do not run this script with 'set -x' or 'bash -x'. Aborting."
    fi
}

validate_passphrase() {
    local pass="${1}"
    if [[ ${#pass} -lt ${_LIB_MIN_PASS_LEN} ]]; then
        die "Passphrase must be at least ${_LIB_MIN_PASS_LEN} characters."
    fi
}

read_passphrase() {
    if [[ -n "${SKILL_PASSPHRASE:-}" ]]; then
        printf -v "${1}" '%s' "${SKILL_PASSPHRASE}"
        unset SKILL_PASSPHRASE
        return 0
    fi
    local _var_name="${1:?read_passphrase: variable name required}"
    local _prompt="${2:-Master passphrase: }"
    local _tmp
    read -r -s -p "${_prompt}" _tmp < /dev/tty
    echo "" >&2
    printf -v "${_var_name}" '%s' "${_tmp}"
    unset _tmp
}

openssl_encrypt() {
    local in_file="${1:?openssl_encrypt: input file required}"
    local out_file="${2:?openssl_encrypt: output file required}"
    local pass="${3:?openssl_encrypt: passphrase required}"
    OPENSSL_PASS="${pass}" openssl enc \
        ${_LIB_OPENSSL_CIPHER} ${_LIB_OPENSSL_KDF} \
        -pass env:OPENSSL_PASS \
        -a \
        -in "${in_file}" \
        -out "${out_file}" \
        2>/dev/null
}

# Decrypt $1 (file path or "-" for stdin) using passphrase in $2; print plaintext to stdout.
# Returns openssl exit code -- caller must check it.
openssl_decrypt() {
    local in_file="${1:?openssl_decrypt: input file required}"
    local pass="${2:?openssl_decrypt: passphrase required}"
    local in_flag
    [[ "${in_file}" == "-" ]] && in_flag="/dev/stdin" || in_flag="${in_file}"
    OPENSSL_PASS="${pass}" openssl enc \
        -d ${_LIB_OPENSSL_CIPHER} ${_LIB_OPENSSL_KDF} \
        -pass env:OPENSSL_PASS \
        -a \
        -in "${in_flag}" \
        2>/dev/null
}

# Read KEY=value pairs from stdin (silently); print a flat JSON object to stdout.
# Keys and values must not contain double-quotes or newlines.
build_json() {
    local -A _kv
    local _key _val
    while IFS='=' read -r -s _key _val; do
        [[ -z "${_key}" ]] && continue
        _kv["${_key}"]="${_val}"
        echo "  + ${_key} stored" >&2
    done
    local _json="{"
    local _first=1
    for _key in "${!_kv[@]}"; do
        [[ ${_first} -eq 0 ]] && _json+=","
        _json+="\"${_key}\":\"${_kv[${_key}]}\""
        _first=0
    done
    _json+="}"
    echo "${_json}"
    unset _kv _key _val _json _first
}

register_tmpfile() {
    local f="${1:?register_tmpfile: file path required}"
    _LIB_TMPFILES+=("${f}")
}

# Zero-wipe and remove all registered temp files.
# Attached to EXIT INT TERM in executed scripts via:
#   trap 'cleanup_tmpfiles' EXIT INT TERM
cleanup_tmpfiles() {
    local f
    for f in "${_LIB_TMPFILES[@]:-}"; do
        [[ -z "${f}" || ! -f "${f}" ]] && continue
        dd if=/dev/zero of="${f}" bs=1 count="$(wc -c < "${f}")" conv=notrunc 2>/dev/null || true
        rm -f "${f}"
    done
    _LIB_TMPFILES=()
}
