# Prefer user-installed CLI tools (also covers non-interactive `zsh -lc`).
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
