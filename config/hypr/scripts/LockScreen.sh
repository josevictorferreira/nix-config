#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock
echo "LockScreen.sh triggered at $(date)" >> /tmp/lockscreen.log

pidof hyprlock || hyprlock -c $XDG_CONFIG_HOME/hypr/hyprlock-2k.conf -q 
