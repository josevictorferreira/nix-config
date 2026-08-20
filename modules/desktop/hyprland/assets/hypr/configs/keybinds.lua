-- Default keybinds.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Flag translation from the hyprlang era:
--   binde  -> { repeating = true }      bindl -> { locked = true }
--   bindel -> both of the above         bindm -> { mouse = true }
--   bindn  -> { non_consuming = true }
--
-- Bind callbacks run on the compositor event loop and must never block, so
-- every external command goes through hl.dsp.exec_cmd (never io.popen).

local mainMod = "SUPER"

local home = os.getenv("HOME")
local scriptsDir = home .. "/.config/hypr/scripts"
local UserScripts = home .. "/.config/hypr/UserScripts"

-- Shorthand: `sh` builds an exec dispatcher, `desc` keeps the option tables
-- readable at the call sites below.
local function sh(cmd)
    return hl.dsp.exec_cmd(cmd)
end

hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "Exit Hyprland" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Fullscreen" })
hl.bind(mainMod .. " + SHIFT + Q", sh(scriptsDir .. "/KillActiveProcess.sh"), { description = "Kill active process" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
-- No Lua dispatcher for workspaceopt, and `hyprctl dispatch` now evaluates its
-- argument as Lua, so the old shell fallback cannot reach it either. Toggling
-- float on every window of the active workspace reproduces allfloat.
hl.bind(mainMod .. " + ALT + F", function()
    for _, w in ipairs(hl.get_workspace_windows(hl.get_active_workspace())) do
        hl.dispatch(hl.dsp.window.float({ window = w, action = "toggle" }))
    end
end, { description = "Float all windows on workspace" })
hl.bind("CTRL + ALT + L", sh(scriptsDir .. "/LockScreen.sh"), { description = "Lock screen" })
hl.bind("CTRL + ALT + P", sh(scriptsDir .. "/Wlogout.sh"), { description = "Power menu" })

-- FEATURES / EXTRAS
-- NOTE: the hyprlang config bound this to `?`; the Lua bind parser needs the
-- real keysym name (`question`), it rejects "?" as an unknown keysym.
hl.bind(mainMod .. " + question", sh(scriptsDir .. "/KeyHints.sh"), { description = "Keybind hints" })
hl.bind(mainMod .. " + ALT + R", sh(scriptsDir .. "/Refresh.sh"), { description = "Refresh waybar, swaync, rofi" })
-- Mirrors macOS Character Viewer (CTRL + CMD + SPACE); SUPER stands in for CMD.
hl.bind("CTRL + " .. mainMod .. " + space", sh(scriptsDir .. "/RofiEmoji.sh"), { description = "Emoji picker" })
hl.bind(mainMod .. " + S", sh(scriptsDir .. "/RofiSearch.sh"), { description = "Web search via rofi" })
hl.bind(mainMod .. " + SHIFT + B", sh(scriptsDir .. "/ChangeBlur.sh"), { description = "Toggle blur settings" })
hl.bind(mainMod .. " + SHIFT + G", sh(scriptsDir .. "/GameMode.sh"), { description = "Game mode (animations on/off)" })
hl.bind(mainMod .. " + ALT + L", sh(scriptsDir .. "/ChangeLayout.sh"), { description = "Toggle master/dwindle layout" })
hl.bind(mainMod .. " + ALT + V", sh(scriptsDir .. "/ClipManager.sh"), { description = "Clipboard manager" })
hl.bind(mainMod .. " + SHIFT + N", sh("swaync-client -sw"), { description = "Notification panel" })

-- FEATURES / EXTRAS (UserScripts)
hl.bind(mainMod .. " + E", sh(UserScripts .. "/QuickEdit.sh"), { description = "Quick edit Hyprland settings" })
hl.bind(mainMod .. " + SHIFT + M", sh(UserScripts .. "/RofiBeats.sh"), { description = "Online music" })
hl.bind(mainMod .. " + W", sh(UserScripts .. "/WallpaperSelect.sh"), { description = "Select wallpaper" })
hl.bind(mainMod .. " + SHIFT + W", sh(UserScripts .. "/WallpaperEffects.sh"), { description = "Wallpaper effects" })
hl.bind("CTRL + ALT + W", sh(UserScripts .. "/WallpaperRandom.sh"), { description = "Random wallpaper" })
-- `hyprctl setprop` was removed along with the legacy parser; set_prop defaults
-- to the active window, which is what `setprop active ...` meant.
hl.bind(mainMod .. " + ALT + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "Toggle opacity on active window" })
hl.bind(mainMod .. " + SHIFT + K", sh(scriptsDir .. "/KeyBinds.sh"), { description = "Searchable keybinds" })

-- Waybar / bar related
-- `hyprctl dispatch` evaluates its argument as Lua under a Lua config, so the
-- restart must be spelled as a dispatcher call. Long-bracket string keeps the
-- inner quotes readable.
hl.bind(mainMod .. " + SHIFT + R", sh([[hyprctl reload; pkill waybar; sleep 0.3; hyprctl dispatch 'hl.dsp.exec_cmd("waybar")']]), { description = "Reload Hyprland + restart Waybar" })
hl.bind(mainMod .. " + B", sh("pkill -SIGUSR1 waybar"), { description = "Toggle waybar" })
hl.bind(mainMod .. " + CTRL + B", sh(scriptsDir .. "/WaybarStyles.sh"), { description = "Waybar styles menu" })
hl.bind(mainMod .. " + ALT + B", sh(scriptsDir .. "/WaybarLayout.sh"), { description = "Waybar layout menu" })

-- Dwindle layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "Toggle split (dwindle)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Pseudo tile (dwindle)" })

-- Master layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"), { description = "Remove master" })
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"), { description = "Add master" })
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "Swap with master" })

-- Works in either layout (master/dwindle).
-- splitratio is a layoutmsg, so it goes through hl.dsp.layout like togglesplit.
hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio -0.5"), { description = "Shrink split ratio" })
hl.bind(mainMod .. " + V", hl.dsp.layout("splitratio 0.5"), { description = "Grow split ratio" })

-- Group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle group" })
hl.bind(mainMod .. " + CTRL + tab", hl.dsp.group.next(), { description = "Focus next window in group" })

-- Cycle windows / bring floating to top.
-- hyprlang allowed two `bind =` lines on one key and ran both; in Lua a single
-- callback dispatching both keeps that behaviour explicit and order-stable.
hl.bind("ALT + tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle windows and bring to top" })

-- Special keys / hot keys
hl.bind("xf86audioraisevolume", sh(scriptsDir .. "/Volume.sh --inc"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("xf86audiolowervolume", sh(scriptsDir .. "/Volume.sh --dec"), { locked = true, repeating = true, description = "Volume down" })
hl.bind("xf86AudioMicMute", sh(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true, description = "Mute microphone" })
hl.bind("xf86audiomute", sh(scriptsDir .. "/Volume.sh --toggle"), { locked = true, description = "Mute audio" })
hl.bind("xf86Sleep", sh("systemctl suspend"), { locked = true, description = "Suspend" })
hl.bind("xf86Rfkill", sh(scriptsDir .. "/AirplaneMode.sh"), { locked = true, description = "Airplane mode" })

-- Media controls
-- NOTE: the hyprlang config also bound xf86AudioPlayPause. That is not a real
-- keysym (hyprlang registered it but could never resolve it, so the bind was
-- dead); the Lua parser rejects it outright. XF86AudioPlay/Pause below already
-- cover the same script.
hl.bind("xf86AudioPause", sh(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "Play/pause" })
hl.bind("xf86AudioPlay", sh(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "Play/pause" })
hl.bind("xf86AudioNext", sh(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true, description = "Next track" })
hl.bind("xf86AudioPrev", sh(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true, description = "Previous track" })
hl.bind("xf86audiostop", sh(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true, description = "Stop playback" })

-- Screenshots
hl.bind(mainMod .. " + Print", sh(scriptsDir .. "/ScreenShot.sh --now"), { description = "Screenshot (fullscreen)" })
hl.bind(mainMod .. " + SHIFT + Print", sh(scriptsDir .. "/ScreenShot.sh --area"), { description = "Screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print", sh(scriptsDir .. "/ScreenShot.sh --in5"), { description = "Screenshot in 5s" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", sh(scriptsDir .. "/ScreenShot.sh --in10"), { description = "Screenshot in 10s" })
hl.bind("ALT + Print", sh(scriptsDir .. "/ScreenShot.sh --active"), { description = "Screenshot active window" })
hl.bind(mainMod .. " + SHIFT + S", sh(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "Screenshot via swappy" })

-- Resize windows
-- `relative = true` is REQUIRED. hyprlang's `resizeactive -50 0` was always a
-- delta, but hl.dsp.window.resize treats { x, y } as an absolute size, so a
-- literal translation throws "Invalid size" at press time. It fails silently:
-- the bind still registers, --verify-config still passes (the size is parsed on
-- dispatch, not on load), and bind callback errors are never logged.
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "Resize left" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "Resize right" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "Resize up" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "Resize down" })

-- Move windows / move focus (vim keys)
local directions = { h = "l", l = "r", k = "u", j = "d" }
for key, dir in pairs(directions) do
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = dir }), { description = "Move window " .. dir })
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }), { description = "Move focus " .. dir })
end

-- Workspaces
hl.bind(mainMod .. " + tab", hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace on monitor" })
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace on monitor" })

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "Move window to special workspace" })
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(), { description = "Toggle special workspace" })

-- Workspace switching uses key codes for better support across keyboard
-- layouts: 1 is code:10, 2 is code:11 ... 10 is code:19.
for i = 1, 10 do
    local code = "code:" .. (9 + i)
    hl.bind(mainMod .. " + " .. code, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
    -- follow = false is the Lua equivalent of movetoworkspacesilent.
    hl.bind(mainMod .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }), { description = "Move window to workspace " .. i .. " (silent)" })
end

hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1" }), { description = "Move window to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }), { description = "Move window to next workspace" })
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }), { description = "Move window to previous workspace (silent)" })
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "Move window to next workspace (silent)" })

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- Move/resize windows with mainMod + LMB/RMB dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })
