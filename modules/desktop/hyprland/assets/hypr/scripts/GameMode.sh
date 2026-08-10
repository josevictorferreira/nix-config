#!/usr/bin/env bash
notif="$HOME/.config/swaync/images/bell.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    # `hyprctl keyword` does not work against a Lua config, so the whole batch
    # collapses into one hl.config call. The opacity-1 windowrule that used to
    # follow is expressed as the three decoration.*_opacity options instead:
    # no window rule in this config sets a per-window opacity, so forcing the
    # globals to 1.0 makes every window opaque exactly as the rule did.
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = {
            shadow = { enabled = false },
            blur = { passes = 0 },
            rounding = 0,
            active_opacity = 1.0,
            inactive_opacity = 1.0,
            fullscreen_opacity = 1.0,
        },
        general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })'
    awww kill 
    notify-send -e -u low -i "$notif" "gamemode enabled. All animations off"
    exit
else
	awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
	sleep 0.1
	${SCRIPTSDIR}/WallustAwww.sh
	sleep 0.5
	${SCRIPTSDIR}/Refresh.sh	 
    notify-send -e -u normal -i "$notif" "gamemode disabled. All animations normal"
    exit
fi
hyprctl reload
