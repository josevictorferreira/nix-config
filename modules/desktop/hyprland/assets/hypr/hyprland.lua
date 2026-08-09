-- Hyprland configuration entrypoint (Lua).
--
-- Since Hyprland 0.55 hyprlang is deprecated in favour of Lua. If both
-- hyprland.lua and hyprland.conf exist, the .lua file wins -- but that check
-- happens only at compositor startup, never on `hyprctl reload`.
--
-- Each require()d file is an isolated error scope: a syntax error in one file
-- does not prevent the others from loading. Emergency binds (SUPER+Q/R/M)
-- remain available if this file itself fails.
--
-- Wiki: https://wiki.hypr.land/Configuring/Start/

hl.config({
    debug = {
        damage_tracking = 2,
        disable_logs = false,
        disable_time = false,
    },
})

-- jvf-theme-switch rewrites wallust/colors.lua and then runs `hyprctl reload`.
-- Lua caches modules in package.loaded, so drop the colours entry up front:
-- within a single config pass both consumers still share one load, but every
-- reload re-reads the file and therefore picks up the new theme. Harmless if
-- Hyprland reloads with a fresh Lua state.
package.loaded["wallust/colors"] = nil

-- Load order mirrors the old `source =` order from hyprland.conf: later files
-- override earlier ones for any option set twice.
require("configs/settings")
require("configs/keybinds")

require("UserConfigs/env")
require("UserConfigs/monitors")
require("UserConfigs/startup")
require("UserConfigs/laptop")
require("UserConfigs/window-rules")
require("UserConfigs/decor-animations")
require("UserConfigs/user-keybinds")
require("UserConfigs/user-settings")
require("UserConfigs/workspace-rules")
