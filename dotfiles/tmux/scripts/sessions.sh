#!/bin/bash

cd "$HOME/.config/tmux/tmuxp" || exit

tmuxp load monitoring.yaml chat.yaml work.yaml projects.yaml main.yaml
