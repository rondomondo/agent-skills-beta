# Skill Secrets — SKILL.md Reference Block

Embed this section into any skill's SKILL.md that uses secrets.sh.

---

## Secrets Handling

This skill loads credentials at runtime from an encrypted `.secrets.enc` file
using `secrets.sh`. Follow these rules without exception.

### Claude MUST

- **Source `secrets.sh`, never execute it.** It must run in the current shell
  to export variables:
  ```bash
  SKILL_SECRETS_VARS="GITHUB_TOKEN"
  source "$(dirname "$0")/secrets.sh"
  ```

- **Declare `SKILL_SECRETS_VARS`** before sourcing. List only what this skill
  actually needs, space-separated. This allows the loader to skip decryption
  when they're already in the environment (local dev).

- **Unset the token immediately after use:**
  ```bash
  curl ... -H "Authorization: Bearer $GITHUB_TOKEN" ...
  unset GITHUB_TOKEN
  ```

- **Check the exit code** of `secrets.sh` (it returns 1 on bad passphrase):
  ```bash
  source .../secrets.sh || { echo "Secret load failed" >&2; exit 1; }
  ```

### Claude MUST NOT

- **Never echo, print, or log any secret value.** Not in reasoning, not in
  tool output, not in error messages. If you need to confirm a token is set,
  check it is non-empty only:
  ```bash
  # SAFE
  [[ -n "${GITHUB_TOKEN:-}" ]] && echo "Token: set" || echo "Token: MISSING"
  
  # NEVER DO THIS
  echo "Token is: $GITHUB_TOKEN"
  echo "First chars: ${GITHUB_TOKEN:0:4}..."
  ```

- **Never pass secrets as CLI arguments.** They appear in `ps aux` output and
  shell history. Always use environment variables or stdin.

- **Never include secret values in your response text** — not even to confirm
  they loaded correctly. Reference the variable name only.

- **Never run `set -x`** (bash xtrace) around any section where secret
  variables are in scope. `secrets.sh` handles this internally, but any caller
  script should also guard:
  ```bash
  set +x   # if you had xtrace on
  source .../secrets.sh
  # ... use token ...
  unset MY_TOKEN
  set -x   # restore if needed
  ```

- **Never write secrets to disk** — not to temp files, not to log files, not
  to output artifacts.

### Session behaviour

On first use in a Claude sandbox session, `secrets.sh` will prompt:

```
🔐 Skill secrets required. Enter master passphrase to unlock:
```

The `_SKILL_SECRETS_LOADED=1` guard means subsequent `source secrets.sh` calls
in the same shell session are no-ops — the passphrase is asked exactly once.

If running locally with the real token already exported (e.g. `export
GITHUB_TOKEN=...` in your shell profile), `secrets.sh` detects it and skips
decryption entirely — no prompt, no passphrase needed.

### File layout

```
my-skill/
├── SKILL.md
├── scripts/
│   ├── secrets.sh          ← runtime loader (copy from skill-secrets/)
│   ├── trigger_workflow.sh ← example consumer
│   └── .secrets.enc        ← encrypted blob (safe to commit)
└── seal_secrets.sh         ← run once locally to create .secrets.enc
```

### Creating `.secrets.enc`

Run these commands from the **skill root directory** (the directory containing `SKILL.md`).

**Interactive** - prompts for passphrase then KEY=value pairs via stdin:

```bash
# From skill root:
scripts/secrets/seal_secrets.sh
# Enter passphrase (twice), then KEY=value pairs, Ctrl-D when done
# Writes .secrets.enc
```

**Piped** - supply K=V pairs from a helper script; passphrase is read
interactively from the terminal regardless:

```bash
# From skill root:
scripts/secrets/create_vars.sh MY_GITHUB_TOKEN | scripts/secrets/seal_secrets.sh

# Real-world example using a token already in your environment:
scripts/secrets/create_vars.sh $GITHUB_TOKEN | scripts/secrets/seal_secrets.sh
```

`create_vars.sh` accepts `<token> [repo] [branch]` and writes the
standard `GITHUB_TOKEN`, `GITHUB_REPO`, `GITHUB_BRANCH` lines to stdout.
The passphrase prompt still appears on your terminal - piping only
replaces the K=V entry step.

The encrypted file uses AES-256-CBC, PBKDF2 with 200,000 iterations.
It is safe to commit — security depends entirely on the strength of the
master passphrase, which never leaves your local machine.
