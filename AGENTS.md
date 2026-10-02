# AGENTS.md

Guidance for coding agents (Claude Code, Codex, Gemini CLI) working in this repository. Claude Code reads it through `CLAUDE.md`, which only imports this file.

## Overview

Personal macOS dotfiles repo for Sami Al Mouhtaseb. Manages shell config, Homebrew packages, terminal emulator settings, and utility scripts. Targets macOS with zsh (Oh My Zsh + Powerlevel10k) as the primary shell.

## Key Commands

### Dotfile Management

```bash
# Import dotfiles from repo to home directory (creates timestamped backups first)
sh dot.sh import

# Backup current home dotfiles into the repo
sh dot.sh backup

# Diff repo dotfiles against what's currently in ~
sh dot.sh diff
```

### Full System Setup

```bash
# Bootstrap a fresh macOS machine (installs Homebrew, zsh, Oh My Zsh, fonts, dev tools, etc.)
# Idempotent: re-runs only install what is missing. Never overwrites files in ~ (uses `dot.sh init`).
sh setup.sh

# Show what a run would do on this machine, change nothing
DRY_RUN=1 sh setup.sh
```

### Homebrew

```bash
# Install all packages from Brewfile
cd Brew && brew bundle

# Backup current Homebrew state to Brewfile
sh Brew/backup.sh
```

## Architecture

### Dotfile Sync Model

`dot.sh` manages four operations (init, import, backup, diff). `LOCATIONS` lists filenames (without the leading dot) copied between `~/dotfiles/.<name>` and `~/.<name>`; `EXTRAS` lists `"<repo path>|<home path>"` pairs for files that live elsewhere (currently empty; terminal configs are pointed at the repo by `iTerm/setup.sh` and `ghostty/setup.sh` instead). All operations skip files whose content already matches. `init` only creates files missing from `~` and is what `setup.sh` runs, so re-running setup never overwrites local edits. When adding a new dotfile, update `LOCATIONS` or `EXTRAS` in `dot.sh`.

### Shell Initialization Chain

1. `.zshrc` — loads Oh My Zsh, Powerlevel10k theme, plugins (zsh-syntax-highlighting, zsh-autosuggestions, ssh-agent), then sources `.bash_profile`
2. `.bash_profile` — adds `~/dotfiles/bin` to PATH, then sources `.exports`, `.aliases`, `.functions`, and `.extra` (gitignored personal overrides)
3. `.exports` — PATH entries and environment variables (nvm, rbenv, pyenv, sdkman, Go, Android, etc.)
4. `.aliases` — shell aliases (navigation, Docker, Ruby/Rails, networking, etc.)
5. `.functions` — utility shell functions
6. `.history_preexec.sh` — SQLite-based command history tracking (stores commands in `~/.history.db`)

### Directory Layout

- `bin/` — custom scripts added to PATH (extract, ip lookup, http server, etc.)
- `Brew/` — Homebrew Brewfile and management scripts
- `cron/` — cron job scripts (history backup to `~/history_logs/`)
- `ghostty/` — Ghostty config; `ghostty/setup.sh` symlinks it to `~/Library/Application Support/com.mitchellh.ghostty/config` (run by `setup.sh`, like `iTerm/setup.sh`)
- `iTerm/` — iTerm2 preferences, fonts, and themes
- `misc/` — one-off utility scripts (CSV splitting, file renaming, etc.)
- `packages/` — `npm.list` (global npm tools, installed per missing package by `setup.sh`), `gems.list` (rbenv default gems), `pip.list` (legacy reference only, not restored)

### Git Configuration

Commits are GPG-signed by default (`.gitconfig` has `gpgsign = true` for both commits and tags). The git config includes branch aliases like `brn` which creates branches prefixed with `satnami/`.
