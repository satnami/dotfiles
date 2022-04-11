
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export PATH=$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH

export PATH=$HOME/dotfiles/bin:$PATH

# Load the shell dotfiles, and then some:
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
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

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
	source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

eval $(thefuck --alias)
eval "$(rbenv init -)"
if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
#eval $(minishift oc-env)
#eval $(minishift docker-env)

# fortune | cowsay -f stegosaurus | lolcat
cowsay -f stegosaurus "Now I Am Become Death, The Destroyer Of Worlds"
# echo 'Now I Am Become Death, The Destroyer Of Worlds' | parrotsay
# espeak "Hey folks!"
