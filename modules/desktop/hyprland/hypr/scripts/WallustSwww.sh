#!/bin/bash

# Define the path to the swww cache directory
cache_dir="$HOME/.cache/swww/"

# Get all monitors
monitors=($(hyprctl monitors -j | jq -r '.[].name'))

# Initialize a flag to determine if the ln command was executed
ln_success=false
wallpaper_path=""

# Process all monitors and use the first valid wallpaper found
for monitor in "${monitors[@]}"; do
    cache_file="$cache_dir$monitor"
    echo "Checking cache for monitor: $monitor"
    
    # Check if the cache file exists for this monitor
    if [ -f "$cache_file" ]; then
        # Get the wallpaper path from the cache file
        current_wallpaper=$(grep -v 'Lanczos3' "$cache_file" | head -n 1)
        
        if [ -n "$current_wallpaper" ] && [ -f "$current_wallpaper" ]; then
            # Use the first valid wallpaper we find
            if [ -z "$wallpaper_path" ]; then
                wallpaper_path="$current_wallpaper"
                echo "Selected wallpaper: $wallpaper_path"
                
                # symlink the wallpaper to the location Rofi can access
                if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
                    ln_success=true
                fi
                
                # copy the wallpaper for wallpaper effects
                cp -r "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
            fi
        fi
    fi
done

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
    # execute wallust
    echo 'about to execute wallust'
    # execute wallust skipping tty and terminal changes
    wallust run "$wallpaper_path" -s &
fi
