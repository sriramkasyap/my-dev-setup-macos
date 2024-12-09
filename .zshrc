#!/usr/bin/env zsh

# Shell prompt based on the Solarized Dark theme.
# Converted from bash to zsh format

# Terminal color settings
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM='gnome-256color'
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM='xterm-256color'
fi

# Git status function for prompt
function git_prompt_info() {
    # First check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi

    local ref
    ref=$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
        git describe --all --exact-match HEAD 2> /dev/null || \
        git rev-parse --short HEAD 2> /dev/null || \
        echo '(unknown)')
    
    if [[ -n "$ref" ]]; then
        local git_status=""
        local repoUrl=$(git config --get remote.origin.url)
        
        if [[ $repoUrl == *chromium/src.git* ]]; then
            git_status="*"
        else
            # Check for uncommitted changes in the index
            git diff --quiet --ignore-submodules --cached 2>/dev/null || git_status+="+"
            # Check for unstaged changes
            git diff-files --quiet --ignore-submodules -- 2>/dev/null || git_status+="!"
            # Check for untracked files
            [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]] && git_status+="?"
            # Check for stashed files
            git rev-parse --verify refs/stash &>/dev/null && git_status+="$"
        fi
        
        [[ -n "$git_status" ]] && git_status=" [$git_status]"
        echo " @ %F{green}${ref}%f%F{blue}${git_status}%f"
    fi
}

# Color setup using terminfo
if tput setaf 1 &> /dev/null; then
    reset=$(tput sgr0)
    bold=$(tput bold)
    # Solarized colors
    black="%F{0}"
    blue="%F{33}"
    cyan="%F{37}"
    green="%F{64}"
    orange="%F{166}"
    purple="%F{125}"
    red="%F{124}"
    violet="%F{61}"
    white="%F{15}"
    yellow="%F{136}"
else
    reset="%f"
    bold="%B"
    black="%F{black}"
    blue="%F{blue}"
    cyan="%F{cyan}"
    green="%F{green}"
    orange="%F{yellow}"
    purple="%F{magenta}"
    red="%F{red}"
    violet="%F{magenta}"
    white="%F{white}"
    yellow="%F{yellow}"
fi

# User style
if [[ $UID -eq 0 ]]; then
    user_style="%F{red}"
else
    user_style="%F{166}"
fi

# Host style
if [[ -n "$SSH_TTY" ]]; then
    host_style="%B%F{red}"
else
    host_style="%F{136}"
fi

# Function to get IP address
function get_ip_address() {
    local ip=""
    # Get all active network interfaces
    for interface in $(networksetup -listallhardwareports | grep -A 1 "Hardware Port" | grep "Device:" | awk '{print $2}'); do
        if ip=$(ipconfig getifaddr $interface 2>/dev/null); then
            echo "$ip"
            return
        fi
    done
    echo "no IP"
}

# Set prompt
setopt PROMPT_SUBST
PROMPT=$'\n'
PROMPT+='${user_style}%n%f'  # username
PROMPT+='%F{host_style} at $(get_ip_address) %f'
PROMPT+='%F{white} in %f'
PROMPT+='%F{33}%~%f'  # current directory
PROMPT+='$(git_prompt_info)'  # git information
PROMPT+=$'\n'
PROMPT+='%F{white}%# %f'  # prompt character

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/opt/homebrew/opt/node@12/bin:$PATH"
export PATH="/opt/homebrew/opt/node@14/bin:$PATH"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Flutter
export PATH="$PATH:$HOME/flutter/bin"

# Aliases
alias sshcronec2="ssh ubuntu@13.233.30.113 -i ~/rowdy-sk-re.pem"
alias htconf="cd /opt/homebrew/etc/httpd/"

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"



autoload -U add-zsh-hook

load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc)"
    if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
        if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
        elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
            nvm use
        fi
    fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc