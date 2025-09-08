# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "$ZINIT_HOME/zinit.zsh"

# Theme
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
zinit ice depth=1
zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Syntax Highlighting
zinit light zdharma/fast-syntax-highlighting

# Completions
zinit light zsh-users/zsh-completions
autoload -U compinit && compinit

# Completions with fzf
zinit light Aloxaf/fzf-tab

# Suggestions
zinit light zsh-users/zsh-autosuggestions

# Snippets
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::kubectl
zinit snippet OMZP::aws
zinit snippet OMZP::asdf

# History Substring Search
zinit load 'zsh-users/zsh-history-substring-search'
zinit ice wait atload'_history_substring_search_config'

# Completions cache
zinit cdreplay -q

# Vi Mode
zinit light jeffreytse/zsh-vi-mode

# FZF history search, should use with prefix <ctrl+space> to trigger
# If no prefix, count occurrences, sort by count (desc) then by command number (desc), and remove duplicates
# With prefix, find commands that START WITH the prefix
function fzf_history_search_prefix_widget() {
  local prefix="${LBUFFER}"
  local selected_command
  
  if [[ -z $prefix ]]; then
    selected_command=$(fc -l 1 | awk '{cmd_num=$1; $1=""; command=substr($0,2)} 
      {count[command]++; if(!seen[command]) {order[command]=cmd_num; seen[command]=1}}
      END {for(cmd in count) print count[cmd] " " order[cmd] " " cmd}' | 
      sort -k1,1nr -k2,2nr | awk '{$1=""; $2=""; print substr($0,3)}' | 
      awk '!seen[$0]++' | fzf --exact --reverse --prompt="history> ")
  else
    selected_command=$(fc -l 1 | awk '{cmd_num=$1; $1=""; command=substr($0,2)} 
      {count[command]++; if(!seen[command]) {order[command]=cmd_num; seen[command]=1}}
      END {for(cmd in count) print count[cmd] " " order[cmd] " " cmd}' | 
      sort -k1,1nr -k2,2nr | awk '{$1=""; $2=""; print substr($0,3)}' | 
      awk '!seen[$0]++' | awk "\$0 ~ /^[[:space:]]*${prefix}/" | 
      fzf --no-sort --reverse --prompt="history> ")
  fi
  
  if [[ -n $selected_command ]]; then
    BUFFER="${selected_command}"
    CURSOR=${#BUFFER}
  else
    zle reset-prompt
  fi
  
  zle redisplay
}

zle -N fzf_history_search_prefix_widget
