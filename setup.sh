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
RUBY_SERIES="4.0"      # a Ruby of this series gets installed when none is present
NODE_VERSION="lts/*"   # nvm alias or version

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
  brew bundle --no-upgrade --file="$DOTFILES/Brew/Brewfile" || warn "brew bundle reported failures (see above); fix and re-run"
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

# -------------------------------------------------------------------- SDKMAN
# rcupdate=false: the installer must not append to ~/.zshrc; .exports already sources sdkman-init.sh.
log "SDKMAN"
if [ -d "$HOME/.sdkman" ]; then
  ok "sdkman"
else
  run_sh 'curl -s "https://get.sdkman.io?rcupdate=false" | bash'
fi

# ----------------------------------------------------------------------- Vim
log "Vim plugins"
clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
run vim +PluginInstall +qall    # installs only the .vimrc plugins that are missing
run vim +PluginUpdate +qall     # pulls updates for the installed ones

# ---------------------------------------------------------------------- Ruby
# rbenv + ruby-build come from the Brewfile.
log "Ruby"
if command -v rbenv >/dev/null 2>&1; then
  clone https://github.com/rbenv/rbenv-default-gems.git "$(rbenv root)/plugins/rbenv-default-gems"
  # default-gems is created once; a local copy is left alone even when it differs.
  if [ -f "$(rbenv root)/default-gems" ]; then
    ok "$(rbenv root)/default-gems"
  else
    run cp "$DOTFILES/packages/gems.list" "$(rbenv root)/default-gems"
  fi
  # Any installed Ruby of this series counts; only install when there is none.
  RUBY_VERSION="$(rbenv versions --bare 2>/dev/null | grep -E "^${RUBY_SERIES}\.[0-9]+$" | sort -V | tail -1)"
  if [ -n "$RUBY_VERSION" ]; then
    ok "ruby $RUBY_VERSION"
  else
    RUBY_VERSION="$(rbenv install -l 2>/dev/null | grep -E "^${RUBY_SERIES}\.[0-9]+$" | tail -1)"
    if [ -n "$RUBY_VERSION" ]; then
      run rbenv install "$RUBY_VERSION" || RUBY_VERSION=""
    else
      warn "ruby-build knows no Ruby ${RUBY_SERIES}.x (brew upgrade ruby-build?)"
    fi
  fi
  # Set the global Ruby only when none is configured yet.
  if [ -n "$RUBY_VERSION" ] && [ "$(rbenv global 2>/dev/null)" = "system" ]; then
    run rbenv global "$RUBY_VERSION"
  fi
else
  warn "rbenv not installed (brew bundle failed?), skipping Ruby"
fi

# ---------------------------------------------------------------------- Node
log "Node"
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  ok "nvm"
else
  # PROFILE=/dev/null: do not append to ~/.zshrc; .exports already loads nvm.
  run_sh 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | PROFILE=/dev/null bash'
fi
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # nvm is a shell function, not a binary: load it into this shell before calling it.
  . "$NVM_DIR/nvm.sh" --no-use
  if [ "$(nvm version "$NODE_VERSION")" = "N/A" ]; then
    run nvm install "$NODE_VERSION"
  else
    ok "node $(nvm version "$NODE_VERSION")"
  fi
  [ -f "$NVM_DIR/alias/default" ] || run nvm alias default "$NODE_VERSION"

  # Global npm packages: install only the ones from packages/npm.list that are missing.
  # nvm keeps globals per node version, so a new node starts with none of them.
  if nvm use "$NODE_VERSION" --silent 2>/dev/null; then
    # `nvm use` edits an existing nvm PATH entry in place, which can sit behind
    # /opt/homebrew/bin (Homebrew node). Force nvm's node first so npm is nvm's npm.
    PATH="$(dirname "$(nvm which "$NODE_VERSION")"):$PATH"; export PATH
    NPM_ROOT="$(npm root -g)"
    NPM_MISSING=""
    for pkg in $(sed -e '/^#/d' -e 's/npm install --location=global//' -e 's/\\//g' "$DOTFILES/packages/npm.list"); do
      [ -d "$NPM_ROOT/$pkg" ] || NPM_MISSING="$NPM_MISSING $pkg"
    done
    if [ -z "$NPM_MISSING" ]; then
      ok "npm globals"
    elif [ -n "$DRY_RUN" ]; then
      printf '    would npm install --location=global:%s\n' "$NPM_MISSING"
    else
      # One package per call: npm rolls back the whole command when a single package fails.
      for pkg in $NPM_MISSING; do
        npm install --location=global "$pkg" || warn "npm: $pkg failed to install"
      done
    fi
  else
    warn "node $NODE_VERSION not installed yet, npm globals come on the next run"
  fi
else
  warn "nvm not installed, skipping Node"
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

# ------------------------------------------------------------- Erlang (off)
# Kept for reference; run by hand when needed.
# brew install autoconf@2.69 && brew link --overwrite autoconf@2.69
# kerl update && kerl build 22.3 22.3 && kerl install 22.3 ~/kerl/default
# . ~/kerl/default/activate
# brew install rebar3
# git clone https://github.com/erlang-ls/erlang_ls ~/kerl/erlang-ls && (cd ~/kerl/erlang-ls && make && cp _build/default/bin/erlang_ls /usr/local/bin)
# git clone https://github.com/inaka/elvis ~/kerl/elvis && (cd ~/kerl/elvis && rebar3 compile && rebar3 escriptize && cp _build/default/bin/elvis /usr/local/bin)

# ---------------------------------------------------------------------- cron
log "cron: daily history backup"
if crontab -l 2>/dev/null | grep -q "history_backup"; then
  ok "crontab entry"
else
  run_sh "(crontab -l 2>/dev/null; echo \"0 12 * * * $DOTFILES/cron/history_backup\") | crontab -"
fi

log "Done. Open a new terminal."
