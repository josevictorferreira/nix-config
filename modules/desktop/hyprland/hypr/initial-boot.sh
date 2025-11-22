#!/bin/bash

scriptsDir=$HOME/.config/hypr/scripts
wallpaper=$HOME/.wallpaper_modified
waybar_style="$HOME/.config/waybar/style/[Dark] Latte-Wallust combined.css"
kvantum_theme="Catppuccin-Mocha"
color_scheme="prefer-dark"
gtk_theme="Andromeda-dark"
icon_theme="Flat-Remix-Blue-Dark"
cursor_theme="Bibata-Modern-Ice"

swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

if [ ! -f "$HOME/.initial_startup_done" ]; then
    sleep 1
	if [ -f "$wallpaper" ]; then
		wallust run -s $wallpaper > /dev/null 
		swww query || swww-daemon
		
		# Small delay to ensure swww daemon is ready and monitors are initialized
		sleep 0.5
		
		# Apply wallpaper to all monitors
		for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
			$swww -o "$monitor" $wallpaper $effect &
		done
		wait
		
	    "$scriptsDir/WallustSwww.sh" > /dev/null 2>&1 & 
	fi
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &
    
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &

    "$scriptsDir/SwitchKeyboardLayout.sh" > /dev/null 2>&1 &

	if [ -f "$waybar_style" ]; then
    	ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"

		"$scriptsDir/Refresh.sh" > /dev/null 2>&1 & 
	fi
    touch "$HOME/.initial_startup_done"

    exit
fi
