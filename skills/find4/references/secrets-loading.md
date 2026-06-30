# Secrets Loading

The skill needs `GITHUB_TOKEN`, `GITHUB_REPO`, and `GITHUB_BRANCH` to push games in Step 9.
These are stored encrypted in `$FIND4_SCRIPTS/secrets/.secrets.enc` relative to the skill root.

## Check whether secrets are already present or decrypted

```bash
[[ -n "${IS_SANDBOX_DECRYPTED:-}" ]] \
  && echo "Secrets already decrypted — skipping." \
  || echo "Secrets needed."
```

If it is set, skip the rest of this step.

```bash
[[ -n "${GITHUB_TOKEN:-}" && -n "${GITHUB_REPO:-}" && -n "${GITHUB_BRANCH:-}" ]] \
  && echo "Secrets already in environment — skipping." \
  || echo "Secrets needed."
```

If all three are already set, skip the rest of this step.

`.secrets.enc` lives alongside `secrets.sh` in `${SKILL_DIR}/scripts/secrets/`.

## If `.secrets.enc` is present in `${SKILL_DIR}/scripts/secrets/` — ask the user for the passphrase

Tell the user:

> "This skill needs a passphrase to decrypt stored credentials (GITHUB_TOKEN, GITHUB_REPO, GITHUB_BRANCH).
> Please provide your master passphrase."

Wait for the user's reply. Then load secrets using the **bash heredoc pattern** — this is mandatory. The sandbox shell is `/bin/sh` which does not support `source` or `[[`. The heredoc runs the block in a real bash process and the inline `read_passphrase` override bypasses the TTY so the passphrase can be supplied via env var.

`.secrets.enc` lives alongside `secrets.sh` in `${SKILL_DIR}/scripts/secrets/` — point `SKILL_SECRETS_FILE` there explicitly.

```bash
bash << 'EOF'
export SKILL_SECRETS_FILE="${SKILL_DIR}/scripts/secrets/.secrets.enc"
export SKILL_SECRETS_VARS="GITHUB_TOKEN GITHUB_REPO GITHUB_BRANCH"
read_passphrase() {
    local _var_name="${1:?read_passphrase: variable name required}"
    printf -v "${_var_name}" '%s' "${SKILL_PASSPHRASE}"
    unset SKILL_PASSPHRASE
}
export SKILL_PASSPHRASE="<passphrase-from-user>"
source "${SKILL_DIR}/scripts/secrets/secrets.sh"
[[ -n "${GITHUB_TOKEN:-}" ]] && echo "TOKEN SET (${#GITHUB_TOKEN} chars)" || echo "TOKEN NOT SET"
echo "REPO: $GITHUB_REPO"
echo "BRANCH: $GITHUB_BRANCH"
EOF
```

**Why this works:** The bash heredoc (`bash << 'EOF'`) spawns a real bash process, making `source` and `[[` available. The inline `read_passphrase` function shadows the one in `_lib.sh`, reading from `$SKILL_PASSPHRASE` instead of the TTY. Variables exported inside the heredoc's subshell do not survive to the parent — but since each `bash_tool` call is a fresh shell anyway, secrets must be re-exported at the top of every tool call that needs them (Step 9).

Capture and re-export pattern for subsequent calls:

```bash
# At the top of any bash_tool block that needs secrets, repeat the heredoc load.
# Do not attempt to pass secrets between bash_tool calls via variables — they don't persist, ever.
# Tell the user that this is happening
```

If decryption fails (wrong passphrase), ask the user to try again. After two failures, warn and skip Step 9.

## If `.secrets.enc` is absent

Warn the user that Step 9 (GitHub push) will be skipped. Continue without secrets.

## Security rules — follow without exception

- **Never echo, log, or include any secret value in your response text.** Reference the variable name only.
- **Never pass secrets as CLI arguments.** Use environment variables only.
- **Never write secrets to disk** — not to temp files, not to log files.
- **Never run `set -x`** while secret variables are in scope.
- Unset `GITHUB_TOKEN` immediately after the `git push` in Step 9 completes.
