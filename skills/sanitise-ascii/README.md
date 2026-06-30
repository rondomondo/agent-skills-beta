# sanitise-ascii

Detects and auto-fixes non-ASCII characters in text files before they cause silent failures in
pipelines, version control systems, and tools that expect plain ASCII. Works across Markdown, YAML,
TOML, JSON, shell scripts, Python files, and more -- anything that shouldn't carry typographic Unicode.

---

> **Try it now -- just say one of these to your agent:**
> - *Check these files for non-ASCII characters*
> - *Sanitise all the markdown in this directory*
> - *Clean this before I push it to GitHub*
> - *Run /sanitise-ascii on this skill*

---

## Why sanitise text files?

When you write or edit text files using word processors, web browsers, Notion, Confluence, or any
AI assistant, you almost certainly end up with typographic Unicode: smart quotes, en dashes, curly
apostrophes, non-breaking spaces, and ellipsis characters. These look identical to their ASCII
equivalents on screen but break things silently downstream.

**The failure mode nobody notices until it's too late.** A YAML config with a curly apostrophe in
a string value parses fine locally, then fails in CI. A shell script with a non-breaking space in
a variable assignment produces a cryptic error. A Markdown file with en dashes gets mangled by a
static site generator. A SKILL.md with smart quotes causes an AI agent to misread tool descriptions.
None of these are obvious at the time of writing -- they surface hours or days later.

**Mojibake compounds the problem.** If a file with UTF-8 Unicode (e.g. an en dash, encoded as
`0xE2 0x80 0x93`) gets read by a tool that assumes Latin-1, you see `a` instead. The symptoms look
random. The fix is to go back to the source character and replace it with its ASCII equivalent --
which is exactly what this tool does.

**What the tool covers:**

| Problem | Example | Fix |
|---------|---------|-----|
| Smart quotes from word processors | `"hello"` (U+201C/D) | `"hello"` |
| Apostrophes from autocorrect | `it's` (U+2019) | `it's` |
| En/em dashes from editors | `a -- b` (U+2013) | `a - b` |
| Ellipsis character | `wait...` (U+2026) | `wait...` |
| Non-breaking spaces (invisible) | `foo bar` (U+00A0) | `foo bar` |
| Box-drawing runs in comments | `# ----` (U+2500+) | `# ----` |
| Bullets and arrows | `* ->` (U+2022, U+2192) | `* ->` |
| Trademark / copyright / registered | `(TM)` (U+2122) | `(TM)` |
| Mojibake symptoms | `a-` (UTF-8 read as Latin-1) | fix source character |

**Safe by default.** Check mode never writes. You must explicitly pass `--fix` (or `SANITISE_ACTION=fix`)
to allow any file to be modified. Clean files are always left untouched.

**Comprehensive file type support.** The `--dir` flag scans an entire directory tree for:
`*.md`, `*.txt`, `*.rst`, `*.yaml`, `*.yml`, `*.json`, `*.jsonl`, `*.toml`, `*.sh`, `*.py`, `*akefile`

---

## Quick Start

```bash
# Check a single file (no writes)
sanitise-ascii README.md

# Auto-fix in place
sanitise-ascii --fix README.md

# Check everything under a directory
sanitise-ascii --dir ./skills

# Fix everything under a directory
sanitise-ascii --fix --dir ./skills
```

### Install to PATH

```bash
make install        # copies to /usr/local/bin, callable as `sanitise-ascii`
make uninstall      # removes it
```

Or invoke directly without installing:

```bash
python3 scripts/sanitise-ascii.py --fix path/to/file.md
```

No dependencies. Requires only Python 3.9+ (stdlib only). Runs on macOS, Linux, and WSL.

---

## CLI Reference

```
usage: sanitise-ascii [--check | --fix] [--dir PATH] [--allow-emoji] [--quiet] [files ...]
```

| Flag | Description |
|------|-------------|
| `--check` | Check only, report issues, no writes (default) |
| `--fix` | Auto-fix known characters in place |
| `--dir PATH` | Recursively process all supported file types under PATH |
| `--allow-emoji` | Treat emoji as acceptable; do not flag or fix them |
| `--quiet` | Suppress OK messages for files that are already clean |

**Environment variable:** `SANITISE_ACTION=check|fix` sets the default mode; CLI flags override it.

**Exit codes:** `0` = all files clean (or all successfully fixed), `1` = unfixable characters remain.

---

## Output Format

The script writes all output to stderr so stdout stays clean for pipeline use.

```
sanitise-ascii [CHECK] - 3 file(s)
  OK    skills/find4/SKILL.md
  FIX   skills/inspect-sandbox/README.md:42: U+2013 ('-') -> '-' x3
  WARN  skills/myskill/AGENT.md:15: U+00E2 not in fix map | ...surrounding context...

Non-ASCII characters found. Run with --fix to auto-fix.
```

| Prefix | Meaning |
|--------|---------|
| `OK` | File is clean |
| `FIX` | Character replaced; shows line number, codepoint, replacement, and count |
| `WARN` | Character not in fix map; shows context for manual resolution |
| `SKIP` | File was skipped (e.g. the script refused to modify itself) |
| `ERROR` | File is not valid UTF-8 |

---

## What Gets Fixed Automatically

| Codepoint | Name | Replaced with |
|-----------|------|---------------|
| U+2013 | en dash | `-` |
| U+2014 | em dash | `--` |
| U+2018/19 | curly single quotes | `'` |
| U+201C/D | curly double quotes | `"` |
| U+2026 | ellipsis | `...` |
| U+00A0 | non-breaking space | ` ` |
| U+2022 | bullet | `-` |
| U+2192 | right arrow | `->` |
| U+2190 | left arrow | `<-` |
| U+00AE | registered | `(R)` |
| U+00A9 | copyright | `(C)` |
| U+2122 | trademark | `(TM)` |
| U+00B1 | plus-minus | `+/-` |
| U+00B0 | degree | ` deg` |
| U+FE0F | variation selector | (dropped) |
| U+FEFF | BOM / zero-width no-break space | (dropped) |
| U+200B | zero-width space | (dropped) |
| U+2500+ | box-drawing dashes on comment lines | `-` |

See the `REPLACEMENTS` dict in `scripts/sanitise-ascii.py` for the full map.

---

## What is NOT Auto-Fixed

- Characters not in the replacement map -- flagged as `WARN`, require manual review
- Emoji (U+2600-U+27BF, U+1F300-U+1FAFF) -- flagged unless `--allow-emoji` is passed
- Real language characters (accented letters, CJK, etc.) -- flagged as `WARN`
- Tree-diagram box-drawing characters -- preserved to keep `output/` tree displays intact

---

## Make Targets

| Target | Purpose |
|--------|---------|
| `make check` | Check all `.md` files under `skills/` for non-ASCII (no writes) |
| `make fix` | Fix known non-ASCII characters in all `.md` files under `skills/` |
| `make fix-file FILE=path/to/file` | Fix a single named file |
| `make install` | Install `sanitise-ascii` to `/usr/local/bin` |
| `make uninstall` | Remove from `/usr/local/bin` |
| `make install-hook` | Install pre-commit hook into the current repo |
| `make install-hook-global` | Install pre-commit hook globally for all repos |
| `make help` | Show all available targets |

---

## Installing the Pre-Commit Hook

The hook runs automatically on every `git commit`, checks only staged files, auto-fixes what it can,
and re-stages the corrected files. If unfixable characters remain, the commit is blocked.

### Single repo

```bash
make install-hook
```

### All repos (global hook)

```bash
make install-hook-global
```

The hook finds `sanitise-ascii.py` by looking in:

1. Repository root
2. Hooks directory (`.git/hooks/`)
3. `PATH`

If it cannot find the script it warns and allows the commit through -- it degrades gracefully rather
than blocking all commits when misconfigured.

---

## Adding to CI

```yaml
# GitHub Actions example
- name: Check ASCII cleanliness
  run: python3 sanitise-ascii.py --check --dir ./skills
```

Exit code `1` will fail the job if any non-ASCII characters remain unfixed.

---

## Installing the Skill

**Global** (available in any project):

```bash
cp -R . ~/.claude/skills/sanitise-ascii
```

**Project-local** (only in the current repo):

```bash
cp -R . .claude/skills/sanitise-ascii
```

---

## Extending the Fix Map

Edit the `REPLACEMENTS` dictionary in `scripts/sanitise-ascii.py`:

```python
"\uXXXX": "ascii-equivalent",
```

Run check mode to discover new offenders -- it prints the codepoint and surrounding context for
each unfixed character:

```bash
python3 scripts/sanitise-ascii.py --check path/to/file
```
