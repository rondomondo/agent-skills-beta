---
name: sanitise-ascii
description: Sanitise non-ASCII characters from Markdown and SKILL files before they might be added to Agents, Harnesses, GitHub etc. General sharing. Use this skill whenever the user wants to check or clean .md files for non-ASCII, typographic, or mojibake characters. Trigger on "sanitise", "sanitize", "ascii clean", "check for non-ascii", "clean before push", "strip unicode", or any request to prepare skill/markdown files for Remote Agent use, GitHub or other sharing. Also trigger proactively at the end of any workflow that produces or edits .md files if the user has asked for ASCII-clean output.
---

# ASCII Sanitise Skill

Ensures Markdown and SKILL.md files contain only ASCII characters before they
are committed or shared. Auto-fixes known typographic characters; flags anything
it cannot fix.

## Tools

Two deliverables live in the repo root (or `~/.git-hooks/` for global use):

| File                        | Purpose                                        |
| --------------------------- | ---------------------------------------------- |
| `sanitise-ascii.py`         | Standalone script -- run manually or from CI   |
| `pre-commit-sanitise-ascii` | Git hook -- runs automatically on every commit |

---

## Running manually

The script requires Python. Use whichever invocation works in your environment:

```bash
# Fix a specific file
./sanitise-ascii.py path/to/SKILL.md        # if executable bit is set
python3 sanitise-ascii.py path/to/SKILL.md  # explicit python3
python sanitise-ascii.py path/to/SKILL.md   # on systems where python = python3

# Fix all .md files under a directory
./sanitise-ascii.py --dir ./skills

# Check only (no writes) -- exits 1 if non-ASCII found
./sanitise-ascii.py --check path/to/SKILL.md

# Allow emoji (checkmarks, crosses) through without flagging
./sanitise-ascii.py --allow-emoji path/to/SKILL.md
```

The script has a `#!/usr/bin/env python3` shebang, so `chmod +x sanitise-ascii.py` and running it directly is the most portable option.

---

## Installing the pre-commit hook

### Single repo

```bash
cp .githooks/pre-commit-sanitise-ascii /path/to/repo/.git/hooks/
chmod +x /path/to/repo/.git/hooks/pre-commit-sanitise-ascii
cp scripts/sanitise-ascii.py /path/to/repo/sanitise-ascii.py
```

### All repos (global)

```bash
mkdir -p ~/.githooks
cp .githooks/pre-commit-sanitise-ascii ~/.githooks/
chmod +x ~/.githooks/pre-commit-sanitise-ascii
git config --global core.hooksPath ~/.githooks

# Put the script somewhere on PATH, e.g.:
cp scripts/sanitise-ascii.py /usr/local/bin/sanitise-ascii.py
```

The hook finds `sanitise-ascii.py` by looking in:

1. Repo root
2. Hooks directory
3. `PATH`

If it cannot find the script it warns and allows the commit through (non-blocking
degradation).

---

## What gets fixed automatically

| Codepoint | Name                | Replaced with |
| --------- | ------------------- | ------------- |
| U+2013    | en dash             | `-`           |
| U+2014    | em dash             | `--`          |
| U+2018/19 | curly single quotes | `'`           |
| U+201C/D  | curly double quotes | `"`           |
| U+2026    | ellipsis            | `...`         |
| U+00A0    | non-breaking space  | ` `           |
| U+2022    | bullet              | `-`           |
| U+2192    | right arrow         | `->`          |
| U+2190    | left arrow          | `<-`          |
| U+00AE    | registered          | `(R)`         |
| U+00A9    | copyright           | `(C)`         |
| U+2122    | trademark           | `(TM)`        |

See `REPLACEMENTS` dict in `sanitise-ascii.py` for the full map.

---

## What is NOT auto-fixed

- Characters not in the replacement map
- Emoji (✅ ❌) -- flagged unless `--allow-emoji` is passed
- Actual language characters (accented letters etc.) -- these are flagged as WARNs
  and block the commit until resolved manually

---

## Mojibake note

This can be tricky. The â character (and similar) is not itself a problem -- it is a symptom of
UTF-8 content being read as Latin-1. The root cause is the source character
(e.g. an en dash, U+2013, encoded as 0xE2 0x80 0x93 in UTF-8). Fixing the
source character eliminates the mojibake wherever it appears downstream.

---

## Adding to CI

```yaml
# GitHub Actions example
- name: Check ASCII cleanliness
  run: ./sanitise-ascii.py --check --dir ./skills
```

---

## Extending the fix map

Edit `REPLACEMENTS` in `sanitise-ascii.py`. Each entry is:

```python
"\uXXXX": "ascii-equivalent",
```

Run `python3 sanitise-ascii.py --check <file>` to discover new offenders --
it prints the Unicode codepoint and surrounding context for each unfixed character.
