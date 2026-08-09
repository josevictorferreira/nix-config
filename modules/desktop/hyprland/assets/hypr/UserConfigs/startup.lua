-- Autostart.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- hl.exec_cmd is asynchronous, so the trailing `&` that every exec-once line
-- needed in the hyprlang era is gone.

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

local wallDIR = home .. "/Pictures/wallpapers"
local SwwwRandom = UserScripts .. "/WallpaperAutoChange.sh"

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Theme convergence: set the correct theme on boot/login. Wrapper commands
    -- are symlinked into ~/.local/bin, which is already on the session PATH.
    hl.exec_cmd("jvf-theme-switch auto")

    hl.exec_cmd(scriptsDir .. "/LockScreen.sh")
    -- hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- Startup apps
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("ags")
    hl.exec_cmd("blueman-applet")

    -- keymapp: holds the Moonlander connection + API socket so `lights-off` can
    -- blank the keyboard LEDs via kontroll. Enable its API (and Start minimized)
    -- once in the keymapp UI; the setting persists across launches.
    hl.exec_cmd("keymapp")

    -- Clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")

    -- Rainbow borders
    hl.exec_cmd(UserScripts .. "/RainbowBorders.sh")

    -- Starting hypridle to start hyprlock
    -- hl.exec_cmd("hypridle")

    -- pyprland daemon
    hl.exec_cmd("pypr")

    -- Features available but disabled by default
    -- persistent wallpaper:
    -- hl.exec_cmd("awww-daemon --format xrgb && awww img " .. home .. "/Pictures/wallpapers/mecha-nostalgia.png")

    -- gnome polkit for nixos
    -- hl.exec_cmd(scriptsDir .. "/Polkit-NixOS.sh")

    -- xdg-desktop-portal-hyprland (should auto-start; forced here)
    hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")

    hl.exec_cmd("easyeffects --gapplication-service")

    hl.exec_cmd("awww-daemon --format xrgb")
    -- random wallpaper switcher every 30 minutes
    hl.exec_cmd(SwwwRandom .. " " .. wallDIR)
end)
