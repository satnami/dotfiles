# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export PATH=$HOME/bin:/usr/local/bin:$PATH

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=$HISTSIZE
PROMPT_COMMAND="history -a"

# (bash) append to the history file, don't overwrite it
# shopt -s histappend
# (bash) Autocorrect typos in path names when using `cd`
# shopt -s cdspell;
# (bash) check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
# shopt -s checkwinsize

# (zsh) append history to the history file (no overwriting)
setopt appendhistory
# (zsh) share history across terminals
setopt sharehistory
# (zsh) immediately append to the history file, not just when a term is killed
setopt incappendhistory

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
	source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# fortune | cowsay -f stegosaurus | lolcat
cowsay -f stegosaurus "Now I Am Become Death, The Destroyer Of Worlds"
# echo 'Now I Am Become Death, The Destroyer Of Worlds' | parrotsay
# espeak "Hey folks!"

eval $(thefuck --alias)
eval "$(rbenv init -)"
