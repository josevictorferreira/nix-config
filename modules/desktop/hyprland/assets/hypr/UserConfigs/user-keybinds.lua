-- User keybinds.
-- See laptop.lua for laptop-specific binds.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

local term = "kitty"
-- The old config also defined $files = "kitty --class=yazi-fm -e yazi" but never
-- used it; ToggleYazi.sh spawns that command itself.

-- rofi app launcher
-- hl.bind(mainMod .. " + " .. mainMod .. "_L", hl.dsp.exec_cmd("pkill rofi; rofi -show drun -modi drun,filebrowser,run,window"), { release = true })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi; rofi -show drun -modi drun"), { description = "App launcher (rofi)" })

-- ags overview
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill rofi || true && ags -t 'overview'"), { description = "Overview (ags)" })

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term), { description = "Launch terminal" })
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(scriptsDir .. "/ToggleYazi.sh"), { description = "Toggle yazi file manager" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(scriptsDir .. "/ToggleTodo.sh"), { description = "Edit Todo.md" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(scriptsDir .. "/ToggleQuickNote.sh"), { description = "Edit quick-notes.md" })

hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh"), { description = "Calculator (qalculate)" })

-- pyprland
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("pypr toggle term"), { description = "Dropdown terminal" })
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("pypr zoom"), { description = "Toggle zoom" })

-- User added keybinds
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(UserScripts .. "/ZshChangeTheme.sh"), { description = "Change oh-my-zsh theme" })
-- non_consuming so the ALT/SHIFT press still reaches the focused client
hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"), { non_consuming = true, description = "Change keyboard layout" })
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd(UserScripts .. "/TodoAdd.sh"), { description = "Add todo item via rofi" })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(UserScripts .. "/TodoCheck.sh"), { description = "Complete todo item via rofi" })

-- Passthrough submap example. Under Lua a submap is a function scope rather
-- than a pair of `submap =` markers:
-- hl.define_submap("passthru", function()
--     hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("reset"))
-- end)
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
