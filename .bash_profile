# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return;;
esac

# Homebrew — no-op when .zshrc already ran brew shellenv; needed for bash login shells
if [ -z "$HOMEBREW_PREFIX" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "/usr/local/sbin" ] && PATH="/usr/local/sbin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/dotfiles/bin" ] && export PATH="$HOME/dotfiles/bin:$PATH"

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don’t want to commit.
for file in "${ZDOTDIR:-$HOME}"/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
# HISTSUFFIX=`tty | sed 's/\///g;s/^dev//g'`
# HISTFILE=".$0_history"
HISTSIZE=100000
HISTFILESIZE=$HISTSIZE
# don't put duplicate lines or lines starting with space in the history in bash(1)
HISTCONTROL=ignoreboth
HISTTIMEFORMAT="%y-%m-%d %H:%M:%S "
PROMPT_COMMAND="history -a"

# autocorrect typos in path names when using `cd`
# shopt -s cdspell

# (bash) append to the history file, don't overwrite it
# shopt -s histappend
# (bash) check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
# shopt -s checkwinsize
# If set, the pattern "**" used in a pathname expansion context will match all files and zero or more directories and subdirectories.
# shopt -s globstar

if [ -n "$ZSH_VERSION" ]; then
  # (zsh) append history to the history file (no overwriting)
  setopt appendhistory
  # (zsh) share history across terminals
  setopt sharehistory
  # (zsh) immediately append to the history file, not just when a term is killed
  setopt incappendhistory
  # (zsh) don't show duplicates in search
  setopt histfindnodups
  # (zsh) add additional data to history like timestamp
  setopt extendedhistory
fi

# useful only for Mac OS Silicon M1
# still working but useless for the other platforms
if [ -x "/usr/local/bin/docker" ]; then
  dockerx() {
    if [[ $(uname -m) == "arm64" ]] && [[ "$1" == "run" || "$1" == "build" ]]; then
      /usr/local/bin/docker "$1" --platform linux/amd64 "${@:2}"
    else
      /usr/local/bin/docker "$@"
    fi
  }
fi

code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$@" ;}

if command -v safehouse >/dev/null 2>&1; then
  # Only pass paths that exist on this machine.
  safe() {
    local -a args
    args=()
    [ -d "$HOME/Work" ] && args+=(--add-dirs-ro="$HOME/Work")
    [ -d "$HOME/server" ] && args+=(--add-dirs-ro="$HOME/server")
    [ -f "$HOME/.config/agent-safehouse/local-overrides.sb" ] && args+=(--append-profile="$HOME/.config/agent-safehouse/local-overrides.sb")
    safehouse "${args[@]}" "$@"
  }
  safe-claude() { safe claude --dangerously-skip-permissions "$@"; }
  if command -v codex >/dev/null 2>&1; then
    safe-codex() { safe codex --dangerously-bypass-approvals-and-sandbox "$@"; }
  fi
  if command -v gemini >/dev/null 2>&1; then
    gemini() { NO_BROWSER=true safe gemini --yolo "$@"; }
  fi
fi

if command -v thefuck >/dev/null 2>&1; then eval "$(thefuck --alias)"; fi
if command -v rbenv >/dev/null 2>&1; then eval "$(rbenv init -)"; fi
if command -v pyenv >/dev/null 2>&1; then eval "$(pyenv init -)"; fi
if command -v pyenv-virtualenv-init >/dev/null 2>&1; then eval "$(pyenv virtualenv-init -)"; fi
# if command -v minishift >/dev/null 2>&1; then
#   eval $(minishift oc-env)
#   eval $(minishift docker-env)
# fi

# if command -v fortune >/dev/null 2>&1 && command -v cowsay >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
#   fortune | cowsay -f stegosaurus | lolcat
# fi
# command -v cowsay >/dev/null 2>&1 && cowsay -f stegosaurus "Now I Am Become Death, The Destroyer Of Worlds"
# echo 'Now I Am Become Death, The Destroyer Of Worlds' | command -v parrotsay >/dev/null 2>&1 && parrotsay
# command -v espeak >/dev/null 2>&1 && espeak "Hey folks!"
