-- Laptop-specific binds and display handling.
-- Merged from the old Laptops.conf + LaptopDisplay.conf (both are lid /
-- brightness concerns).
--
-- These binds are harmless on desktops: the xf86* keys simply never fire and
-- the touchpad device name never matches.

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"

-- Touchpad. Use `hyprctl devices` to get the device name.
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"
local TOUCHPAD_ENABLED = true

hl.bind("xf86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true, description = "Keyboard brightness down" })
hl.bind("xf86KbdBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true, description = "Keyboard brightness up" })
hl.bind("xf86Launch1", hl.dsp.exec_cmd("rog-control-center"), { description = "ASUS Armoury Crate button" })
hl.bind("xf86Launch3", hl.dsp.exec_cmd("asusctl led-mode"), { description = "Switch keyboard RGB profile" })
hl.bind("xf86Launch4", hl.dsp.exec_cmd("asusctl profile"), { description = "Change fan profile" })
hl.bind("xf86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"), { repeating = true, description = "Brightness down" })
hl.bind("xf86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"), { repeating = true, description = "Brightness up" })
hl.bind("xf86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"), { description = "Toggle touchpad" })

-- Screenshot keybinds for the Asus G15 (no PrintScr button)
hl.bind("SUPER + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "Screenshot (fullscreen)" })
hl.bind("SUPER + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "Screenshot (area)" })
hl.bind("SUPER + CTRL + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "Screenshot in 5s" })
hl.bind("SUPER + ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "Screenshot in 10s" })
hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "Screenshot active window" })

hl.device({
    name = Touchpad_Device,
    enabled = TOUCHPAD_ENABLED,
})

-- Below is useful when connecting a laptop to an external display.
-- WIKI: disable the laptop monitor when the lid is closed.
-- https://wiki.hypr.land/Configuring/Basics/Binds/#switches
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, preferred, auto, 1"'), { locked = true })
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'), { locked = true })

--
-- WARNING! The lid-switch approach above has caveats -- USE WITH CAUTION!
-- CONS: the wallpaper (SUPER+W) will re-choose a wallpaper.
-- CAVEAT: the main laptop monitor will NOT display; it needs the external
-- monitor to be re-connected. One workaround: make sure the laptop lid is OPEN
-- before shutting down.
--
-- The hyprlang config wrote monitor lines into LaptopDisplay.conf from these
-- binds. Under Lua the equivalent is to call hl.monitor() from a switch bind
-- directly, so no generated file is needed:
-- hl.bind("switch:off:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- end, { locked = true })
-- hl.bind("switch:on:Lid Switch", function()
--     hl.monitor({ output = "eDP-1", disabled = true })
-- end, { locked = true })
