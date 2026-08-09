-- Default settings. Avoid changing this file; UserConfigs/ is the place for
-- host-specific tweaks.
--
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Variables/

-- Initial boot script: applies initial wallpapers, theming, new settings etc.
-- exec_cmd is asynchronous, so this does not block compositor startup.
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/initial-boot.sh")
end)
