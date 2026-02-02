# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=50000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# ============================================================================
# ADVANCED BASH PROMPT CONFIGURATION
# ============================================================================

# Timer functions for command execution time
function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  timer_show=$(($SECONDS - $timer))
  unset timer
}

trap 'timer_start' DEBUG

# If this is an interactive shell, then set PROMPT_COMMAND
if [ "$PS1" ]; then
  PROMPT_COMMAND=timer_stop
fi

# Git branch and status function
parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

git_status_info() {
  local git_status="$(git status 2>/dev/null)"
  local branch=$(parse_git_branch)

  if [ -n "$branch" ]; then
    local git_info="$branch"

    # Check for uncommitted changes
    if echo "$git_status" | grep -q "Changes to be committed"; then
      git_info="${git_info}✓"
    fi

    if echo "$git_status" | grep -q "Changes not staged\|Untracked files"; then
      git_info="${git_info}✗"
    fi

    # Check if ahead/behind remote
    if echo "$git_status" | grep -q "Your branch is ahead"; then
      git_info="${git_info}↑"
    fi

    if echo "$git_status" | grep -q "Your branch is behind"; then
      git_info="${git_info}↓"
    fi

    echo "$git_info"
  fi
}

# Battery status function
get_battery() {
  local battery_path="/sys/class/power_supply/BAT0/capacity"
  local ac_path="/sys/class/power_supply/AC/online"

  if [ -f "$battery_path" ]; then
    local capacity=$(cat "$battery_path")
    local charging=""

    if [ -f "$ac_path" ] && [ "$(cat "$ac_path")" = "1" ]; then
      charging="⚡"
    fi

    # Color code based on battery level
    if [ "$capacity" -ge 80 ]; then
      echo -e "\[\e[32m\]🔋${capacity}%${charging}\[\e[0m\]"
    elif [ "$capacity" -ge 40 ]; then
      echo -e "\[\e[33m\]🔋${capacity}%${charging}\[\e[0m\]"
    else
      echo -e "\[\e[31m\]🔋${capacity}%${charging}\[\e[0m\]"
    fi
  fi
}

# Format execution time
format_time() {
  local seconds=$1
  if [ $seconds -lt 60 ]; then
    echo "${seconds}s"
  elif [ $seconds -lt 3600 ]; then
    printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
  else
    printf "%dh %dm %ds" $((seconds / 3600)) $((seconds % 3600 / 60)) $((seconds % 60))
  fi
}

# Get number of background jobs
get_jobs() {
  local job_count=$(jobs | wc -l)
  if [ $job_count -gt 0 ]; then
    echo "⚙️ ${job_count}"
  fi
}

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  # Advanced two-line prompt
  # Line 1: All information (user, host, directory, git, battery, time, jobs, exit status, execution time)
  # Line 2: Command input with colored prompt symbol

  PS1='${debian_chroot:+($debian_chroot)}'

  # User and host
  PS1+='\[\e[1;32m\]\u\[\e[0m\]'

  # Current directory
  PS1+=' \[\e[1;34m\]\w\[\e[0m\]'

  # Git branch and status
  PS1+=' $(if [ -n "$(parse_git_branch)" ]; then echo "\[\e[1;35m\]($(git_status_info))\[\e[0m\]"; fi)'

  # Background jobs
  PS1+=' $(get_jobs)'

  # Exit status (show only if non-zero)
  PS1+=' $(if [ $? -ne 0 ]; then echo "\[\e[1;31m\]✘ $?\[\e[0m\]"; else echo "\[\e[1;32m\]✔\[\e[0m\]"; fi)'

  # Command execution time (show if > 0)
  PS1+=' $(if [ -n "$timer_show" ] && [ $timer_show -gt 0 ]; then echo "\[\e[1;33m\]⏱ $(format_time $timer_show)\[\e[0m\]"; fi)'

  # New line and prompt symbol
  PS1+='\n\[\e[1;32m\]\$\[\e[0m\] '

else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*) ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Navigation alias
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# System Shortcuts
alias untar='tar -xvf'
alias ports='sudo lsof -i -P -n'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias histg='history | grep'
alias top='htop'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Colorize commands
alias diff='diff --color=auto'
alias tree='tree -C'

# Quick edit
alias bashrc='${EDITOR:-nano} ~/.bashrc'
alias reload='source ~/.bashrc && echo "Bash config reloaded!"'

# Git Shortcuts
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias tor='/home/shubham/programs/tor-browser/start-tor-browser.desktop'
# Networking
alias myip='ip a'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
export PATH="/home/shubham/programs/node/bin:$PATH:/home/shubham/android-studio-linux/bin/:/home/shubham/programs/Telegram/:/home/shubham/programs/flutter/bin/:/home/shubham/programs/nvim/bin/:home/shubham/programs/ytdlp/:$HOME/scripts/:$HOME/.local/bin/"

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
# FZF config for bash history search
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
elif [ -f ~/.fzf.bash ]; then
  source ~/.fzf.bash
fi

# Custom functions
mkcd() {
  mkdir -p "$1"
  cd "$1"
}

# Quick find function
qfind() {
  find . -iname "*$1*"
}

# Create backup of a file
backup() {
  cp "$1"{,.bak-$(date +%Y%m%d-%H%M%S)}
}

# Extract various archive formats
extract() {
  if [ -f "$1" ]; then
    case $1 in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz) tar xzf "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) unrar x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.tar) tar xf "$1" ;;
    *.tbz2) tar xjf "$1" ;;
    *.tgz) tar xzf "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Show disk usage of current directory
duh() {
  du -sh * | sort -hr | head -20
}

# Make a directory and cd into it
take() {
  mkdir -p "$1" && cd "$1"
}

# Find and kill process by name
killp() {
  ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Get public IP
publicip() {
  curl -s https://api.ipify.org
  echo
}

# Weather function (optional - requires curl)
weather() {
  local location="${1:-}"
  curl -s "wttr.in/${location}?format=3"
}

shopt -s cdspell

# ============================================================================
# ENHANCED SHELL OPTIONS
# ============================================================================

# Correct minor errors in directory spelling during cd
shopt -s cdspell

# Update window size after each command
shopt -s checkwinsize

# Save multi-line commands as one command
shopt -s cmdhist

# Append to history file, don't overwrite
shopt -s histappend

# Enable recursive globbing with **
shopt -s globstar 2>/dev/null

# Case-insensitive globbing
shopt -s nocaseglob

# Don't try to complete on empty line
shopt -s no_empty_cmd_completion

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================

# Timestamp in history
export HISTTIMEFORMAT="%F %T "

# Ignore duplicate commands and commands starting with space
export HISTCONTROL=ignoreboth:erasedups

# Commands to ignore in history
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"

# ============================================================================
# BETTER TERMINAL BEHAVIOR
# ============================================================================

# Make less more friendly for non-text files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set default editor
export EDITOR=nano
export VISUAL=nano

# Enable colors for less pager
export LESS='-R --use-color -Dd+r$Du+b'
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

# Auto refrest GPG agnet

# Refresh GPG agent on every prompt
gpg-connect-agent reloadagent /bye >/dev/null 2>&1

# Start SSH agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
  evel "$(ssh-agent -s)" >/dev/null
fi

# Add SSH keys automatically
# ssh-add -l >/dev/null 2>&1 || ssh-add ~/.ssh/id_rsa >/dev/null 2>&1

# For adding multiple SSH keys
for key in ~/.ssh/id_*; do
  [ -f "$key" ] && ssh-add "$key" >/dev/null 2>&1
done

# PPT Generator CLI
export PATH="$HOME/.local/bin:$PATH"
if [ "$TERM_PROGRAM" != "vscode" ]; then
    cd ~/dev/
fi
