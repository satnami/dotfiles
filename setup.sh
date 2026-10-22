#!/bin/sh

# Bootstrap a macOS machine.
#
# Idempotent: every step checks what is already in place and only installs or
# creates what is missing. Nothing is upgraded or overwritten, so re-running
# the script at any time is safe and only fills the gaps.
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/satnami/dotfiles/master/setup.sh)"
#   sh ~/dotfiles/setup.sh                # from an existing checkout
#   DRY_RUN=1 sh ~/dotfiles/setup.sh      # show what a run would do, change nothing

# Knobs
export DRY_RUN="${DRY_RUN:-}"

DOTFILES="$HOME/dotfiles"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log()  { printf '\n==> %s\n' "$*"; }
ok()   { printf '    ok    %s\n' "$*"; }
warn() { printf '    WARN  %s\n' "$*" >&2; }

# run <cmd> [args...]    — execute, or only print under DRY_RUN
run() {
  if [ -n "$DRY_RUN" ]; then printf '    would %s\n' "$*"; else "$@"; fi
}
# run_sh '<shell snippet>' — same, for pipelines and curl|bash installers
run_sh() {
  if [ -n "$DRY_RUN" ]; then printf '    would %s\n' "$1"; else eval "$1"; fi
}

# clone <url> <dir> [git clone flags...]  — skipped when <dir> already exists
clone() {
  _url="$1"; _dir="$2"; shift 2
  if [ -d "$_dir" ]; then
    ok "$_dir"
  else
    run git clone "$@" "$_url" "$_dir"
  fi
}

# ---------------------------------------------------------------- GitHub SSH
# Brew/Brewfile taps creditornot/wolt-dev-tools over git@github.com, so GitHub
# must accept this machine's SSH key before `brew bundle` can fully succeed.
# `ssh -T` exits 1 even on success, so match the banner instead.
log "GitHub SSH"
if ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
  ok "authenticated"
else
  warn "no GitHub SSH access: the creditornot tap will fail in brew bundle. Add your key to GitHub and re-run."
fi

# ------------------------------------------------------------------ Homebrew
log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "brew"
else
  run_sh '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi
# The installer does not touch PATH. Load brew into this shell now;
# .zshrc runs the same `brew shellenv` for every future shell.
for BREW_BIN in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$BREW_BIN" ]; then
    eval "$("$BREW_BIN" shellenv)"
    break
  fi
done
if ! command -v brew >/dev/null 2>&1; then
  if [ -n "$DRY_RUN" ]; then
    warn "brew missing; the steps below assume it is installed"
  else
    echo "brew not found after install" >&2
    exit 1
  fi
fi

# ------------------------------------------------------------- dotfiles repo
# git comes with the Xcode Command Line Tools that the Homebrew installer sets up.
log "Dotfiles repo"
clone https://github.com/satnami/dotfiles "$DOTFILES"

# ------------------------------------------------------------- dotfiles -> ~
# Creates only the files missing from ~. Existing files are left alone; to push
# repo changes over them run `dot.sh import` by hand (it keeps backups).
# Runs before Oh My Zsh so its installer finds our .zshrc and keeps it.
log "Dotfiles into ~"
bash "$DOTFILES/dot.sh" init

# ---------------------------------------------------------------------- zsh
# macOS ships zsh as the default shell; this only matters on other systems.
log "zsh"
if command -v zsh >/dev/null 2>&1; then
  ok "zsh"
else
  run brew install zsh
  ZSH_PATH="$(command -v zsh)"
  grep -qx "$ZSH_PATH" /etc/shells || run_sh "echo \"$ZSH_PATH\" | sudo tee -a /etc/shells >/dev/null"
  run chsh -s "$ZSH_PATH"
fi

# ---------------------------------------------------------------- Oh My Zsh
log "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "oh-my-zsh"
else
  run_sh 'RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
fi
clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" --depth=1
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# ----------------------------------------------------------------------- up
log "up"
if [ -f "$HOME/.config/up/up.sh" ]; then
  ok "up.sh"
else
  run curl -fsSL --create-dirs -o "$HOME/.config/up/up.sh" https://raw.githubusercontent.com/shannonmoeller/up/master/up.sh
fi

# ------------------------------------------------------------------ Brewfile
# --no-upgrade: install what is missing, leave installed packages at their version.
log "brew bundle"
if [ -n "$DRY_RUN" ]; then
  brew bundle check --verbose --file="$DOTFILES/Brew/Brewfile"   # lists what is missing, installs nothing
else
  brew bundle --verbose --no-upgrade --file="$DOTFILES/Brew/Brewfile" || warn "brew bundle reported failures (see above); fix and re-run"
fi

# --------------------------------------------------------------- GPG agent
# Keep the pinentry program and cache settings present without duplicating them.
log "GPG agent"
GPG_AGENT_CONF="$HOME/.gnupg/gpg-agent.conf"
if [ -n "$DRY_RUN" ]; then
  printf '    would ensure %s contains pinentry and cache settings\n' "$GPG_AGENT_CONF"
else
  mkdir -p "$HOME/.gnupg"
  touch "$GPG_AGENT_CONF"
  for GPG_SETTING in \
    'pinentry-program /opt/homebrew/bin/pinentry-mac' \
    'default-cache-ttl 86400' \
    'max-cache-ttl 604800'; do
    if ! grep -Fqx "$GPG_SETTING" "$GPG_AGENT_CONF"; then
      printf '%s\n' "$GPG_SETTING" >> "$GPG_AGENT_CONF"
    fi
  done
  chmod 700 "$HOME/.gnupg"
  ok "$GPG_AGENT_CONF"
fi

# -------------------------------------------------------------------- iTerm2
# Points iTerm2 at the prefs in the repo (idempotent `defaults write`).
log "iTerm2 prefs"
if run sh "$DOTFILES/iTerm/setup.sh" && [ -z "$DRY_RUN" ]; then
  ok "prefs load from $DOTFILES/iTerm"
fi

# ------------------------------------------------------------------- Ghostty
# Symlinks Ghostty's live config to the repo copy (idempotent).
log "Ghostty config"
run sh "$DOTFILES/ghostty/setup.sh"

# ------------------------------------------------------------ macOS defaults
# Finder, Dock, screenshot and privacy preferences (idempotent `defaults write`).
log "macOS defaults"
if [ "$(uname)" = "Darwin" ]; then
  # non-defaults first: macos/setup.sh ends with the Finder/Dock restart that
  # makes both sets of writes take effect, so it runs last.
  run sh "$DOTFILES/macos/non-defaults.sh"
  run sh "$DOTFILES/macos/setup.sh"
  run sh "$DOTFILES/macos/touch-id-sudo.sh" || warn "Touch ID for sudo not enabled (see above); re-run macos/touch-id-sudo.sh"
else
  ok "not macOS, skipped"
fi

# ----------------------------------------------------------------------- Vim
log "Vim plugins"
clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
run vim +PluginInstall +qall    # installs only the .vimrc plugins that are missing
run vim +PluginUpdate +qall     # pulls updates for the installed ones

# ---------------------------------------------------------------------- mise
# All managed runtime versions live in mise.toml in the dotfiles checkout.
log "mise runtimes"
if ! command -v mise >/dev/null 2>&1 && [ -x "$HOME/.local/bin/mise" ]; then
  PATH="$HOME/.local/bin:$PATH"; export PATH
fi
if ! command -v mise >/dev/null 2>&1; then
  if [ -n "$DRY_RUN" ]; then
    printf '    would curl -fsSL https://mise.run | sh\n'
  else
    run_sh 'curl -fsSL https://mise.run | sh'
    PATH="$HOME/.local/bin:$PATH"; export PATH
  fi
fi
if command -v mise >/dev/null 2>&1; then
  if [ -n "$DRY_RUN" ]; then
    printf '    would (cd %s && mise install --yes)\n' "$DOTFILES"
  else
    (cd "$DOTFILES" && mise install --yes) || warn "mise could not install every configured runtime (see above); fix and re-run"
  fi

  # mise.toml manages global npm CLIs; preserve the Ruby gem package list.
  if [ -n "$DRY_RUN" ]; then
    printf '    would install missing Ruby gems from packages/gems.list\n'
  else
    (cd "$DOTFILES" && mise exec -- sh -c '
      if command -v gem >/dev/null 2>&1; then
        for gem_name in $(sed "/^#/d" packages/gems.list); do
          gem list -i "$gem_name" >/dev/null 2>&1 || gem install --no-document "$gem_name" || echo "WARN: gem: $gem_name failed to install" >&2
        done
      fi
    ')
  fi
else
  if [ -n "$DRY_RUN" ]; then
    printf '    would (cd %s && mise install --yes)\n' "$DOTFILES"
    printf '    would install missing Ruby gems from packages/gems.list\n'
  else
    warn "mise installer did not make mise available, skipping managed runtimes"
  fi
fi

# ----------------------------------------------------------------------- GPG
# .gitconfig signs every commit and tag; without the secret key `git commit`
# fails with "gpg failed to sign the data". Keys are never installed by script.
log "GPG"
SIGNING_KEY="$(git config --file "$DOTFILES/.gitconfig" user.signingkey)"
if [ -n "$SIGNING_KEY" ] && gpg --list-secret-keys "$SIGNING_KEY" >/dev/null 2>&1; then
  ok "secret key $SIGNING_KEY present"
else
  warn "GPG secret key ${SIGNING_KEY:-(none in .gitconfig)} not found: gpg --import <your-key-backup.asc>"
fi

# ---------------------------------------------------------------------- cron
log "cron: daily history backup"
if crontab -l 2>/dev/null | grep -q "history_backup"; then
  ok "crontab entry"
else
  run_sh "(crontab -l 2>/dev/null; echo \"0 12 * * * $DOTFILES/cron/history_backup\") | crontab -"
fi

log "Done. Open a new terminal."
