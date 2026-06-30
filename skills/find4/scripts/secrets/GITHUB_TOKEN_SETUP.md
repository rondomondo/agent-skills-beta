# Creating a Scoped GitHub Personal Access Token

> **Purpose:** Grant write access to the `games-drop` branch of `rondomondo/agent-skills-beta`  
> **Token type:** Fine-grained Personal Access Token (recommended over classic PATs)

---

## Prerequisites

- A GitHub account that has write access to the `rondomondo/agent-skills-beta` repository
- You must be logged in to GitHub in your browser

---

## Step-by-Step Instructions

### Step 1 — Open the token creation page

Navigate directly to [the token create page]

```
https://github.com/settings/personal-access-tokens/new
```

Or navigate manually:

1. Click your **profile avatar** (top-right corner of GitHub)
2. Click **Settings**
3. Scroll down in the left sidebar → click **Developer settings**
4. In the left sidebar → **Personal access tokens** → **Fine-grained tokens**
5. Click **Generate new token**

---

### Step 2 — Fill in token metadata

| Field | What to enter |
|---|---|
| **Token name** | Something descriptive, e.g. `agent-skills-beta-games-drop-write` |
| **Expiration** | Choose a sensible duration — 90 days is a good default. Max is 366 days. |
| **Description** | *(Optional)* e.g. `Write access to games-drop branch for game JSON drops` |

---

### Step 3 — Set the resource owner

Under **Resource owner**, select `rondomondo`.

> If this is your personal account, it will be pre-selected. If `rondomondo` is an organisation, it must have opted in to fine-grained PATs — check with the org admin if it doesn't appear.

---

### Step 4 — Restrict to a single repository

Under **Repository access**, select:

- ☑️ **Only select repositories**
- Then pick **`rondomondo/agent-skills-beta`** from the dropdown

> Do **not** choose "All repositories" — keep it scoped.

---

### Step 5 — Set permissions (the critical part)

Expand **Repository permissions** and set the following. Leave everything else at `No access`.

| Permission | Required level |
|---|---|
| **Contents** | **Read and write** |
| **Metadata** | **Read-only** ← GitHub sets this automatically; it is mandatory |

That's the complete set. You do **not** need Actions, Pull requests, Workflows, or Secrets for pushing files to a branch.

> **Note on branch-level scoping:** Fine-grained PATs cannot be restricted to a specific branch — `Contents: read/write` grants push access to all branches in the repo. If you need to restrict who can push to `games-drop` specifically, use a **branch protection rule** on the repository (Settings → Branches → Add rule), which is independent of the token.

---

### Step 6 — Generate and save the token

Click **Generate token**.

> ⚠️ **Copy the token immediately.** GitHub will only show it once. Store it somewhere safe — a password manager, AWS SSM, or a `.env` file that is gitignored.

Your token will look like:

```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Using the Token

### Git over HTTPS

```bash
# Set the remote URL to include the token
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/rondomondo/agent-skills-beta.git

# Push to the games-drop branch
git push origin games-drop
```

### As an environment variable

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Then use with the GitHub CLI:

```bash
gh auth login --with-token <<< "$GITHUB_TOKEN"

# Verify access
gh api repos/rondomondo/agent-skills-beta/branches --jq '.[].name'
```

Or with `curl` directly:

```bash
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/repos/rondomondo/agent-skills-beta/branches
```

### In a script (recommended pattern)

Store the token in a `.env` file (never commit this):

```bash
# .env  ← add this to .gitignore
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Load it at runtime:

```bash
source .env
git push origin games-drop
```

---

## Security Notes

- **Never commit the token** to any repository, including this one
- Add `.env` and any file containing the raw token to `.gitignore`
- Rotate the token before expiry — set a calendar reminder
- If the token is accidentally exposed, revoke it immediately at:  
  `https://github.com/settings/personal-access-tokens`
- Fine-grained tokens are tied to your user account — if you lose access to the repo, the token stops working

---

## Revoking a Token

> **If a token is exposed or compromised, revoke it immediately -- before doing anything else.**

Revoke any [Personal Access Token] at:

```
https://github.com/settings/personal-access-tokens
```

Steps:

1. Navigate to [your fine-grained tokens list](https://github.com/settings/personal-access-tokens)
2. Find the token by name (e.g. `agent-skills-beta-games-drop-write`)
3. Click the **...** menu on the right → **Revoke**
4. Confirm revocation

Once revoked, any request using that token will receive a `401 Unauthorized` response immediately. There is no grace period.

After revoking:

- Generate a replacement token following the steps above
- Update any scripts, `.env` files, or CI secrets that held the old token
- If the token was committed to a repository, treat the repository as compromised -- rotate all other secrets in it and audit the git history

---

## Installing the GitHub CLI (`gh`)

The `gh` CLI is used in the examples above to verify token access and interact with the GitHub API.

### macOS

```bash
brew install gh
```

### Linux (Debian / Ubuntu)

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
     | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
     | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
```

### Linux (Fedora / RHEL / CentOS)

```bash
sudo dnf install 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install gh
```

### Windows

```powershell
winget install --id GitHub.cli
```

Or via [Scoop](https://scoop.sh):

```powershell
scoop install gh
```

After installing, verify with:

```bash
gh --version
```

See the [official install docs](https://github.com/cli/cli#installation) for other platforms and package managers.

---

## Cannot Be Done via Terraform

The GitHub Terraform provider does **not** support creating PATs — this is a deliberate GitHub API restriction. PAT creation requires interactive browser authentication and cannot be automated via API. The token must always be created manually through the UI above.

What Terraform *can* do is consume the token as a credential and manage repo resources (branch protection rules, secrets, webhooks, etc.) once you have it.

---

## Quick Reference

```
Repo:        rondomondo/agent-skills-beta
Branch:      games-drop
Token type:  Fine-grained PAT
Permissions: Contents = Read and Write
             Metadata = Read-only (auto)
Scope:       Single repository only
```


[the token create page]: (https://github.com/settings/personal-access-tokens/new)

[PAT]: (https://github.com/settings/personal-access-tokens/new)

[Personal Access Token]: (https://github.com/settings/personal-access-tokens/new)
