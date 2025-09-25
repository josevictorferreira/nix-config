#!/usr/bin/zsh

export TMUXP_CONFIGDIR=~/.config/tmux/scripts/sessions.sh

tmuxp load main.yaml projects.yaml work.yaml chat.yaml monitoring.yaml
