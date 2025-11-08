#!/bin/bash

pidof hyprlock || hyprlock -c "$HOME/.config/hypr/hyprlock-2k.conf"
