#!/bin/bash

cd "$HOME/.config/tmux/tmuxp" || exit

tmuxp load -y monitoring.yaml chat.yaml work.yaml projects.yaml main.yaml
