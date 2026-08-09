-- Monitors.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({ output = "DP-1", mode = "3440x1440@165", position = "auto", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "-1080x0", scale = 1 })
-- hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "-1080x0", scale = 1, transform = 3 })

-- NOTE: for laptops, see the notes in laptop.lua regarding display handling.
-- Created so that the monitor display does not wake up when not intended.
-- See https://github.com/hyprwm/Hyprland/issues/4090

-- Some examples
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1 })

-- QEMU-KVM, VirtualBox or VMware
-- hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })

-- Catch-all rules (empty output matches any monitor)
-- hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })  -- high refresh rate
-- hl.monitor({ output = "", mode = "highres", position = "auto", scale = 1 }) -- high resolution

-- To disable a monitor
-- hl.monitor({ output = "eDP-1", disabled = true })

-- Mirror samples
-- hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "0x0", scale = 1, mirror = "DP-2" })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0", scale = 1, mirror = "eDP-1" })

-- 10 bit monitor support -- https://wiki.hypr.land/Configuring/Basics/Monitors/
-- NOTE: colours registered in Hyprland (e.g. the border colour) do not support 10 bit.
-- NOTE: some applications cannot screen capture with 10 bit enabled (OBS may render black).
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, bitdepth = 10 })

-- hl.monitor({ output = "eDP-1", transform = 0 })
-- hl.monitor({ output = "eDP-1", reserved = { top = 10, right = 10, bottom = 10, left = 49 } })

-- Workspace/monitor assignment lives in UserConfigs/workspace-rules.lua
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
