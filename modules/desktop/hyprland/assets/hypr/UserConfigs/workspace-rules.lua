-- Workspace rules.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- You can set workspace rules to achieve workspace-specific behaviours, e.g.
-- a workspace where all windows are drawn without borders or gaps.

-- Assigning workspaces to a certain monitor (by EDID description, see monitors.lua)
local ultrawide = "desc:Samsung Electric Company LC34G55T"
local side = "desc:Philips Consumer Electronics Company 27M2N3200L"

local workspaceMonitors = {
    ["1"] = ultrawide,
    ["2"] = side,
    ["3"] = ultrawide,
    ["4"] = ultrawide,
    ["5"] = ultrawide,
    ["6"] = side,
    ["7"] = side,
    ["8"] = side,
}

for workspace, monitor in pairs(workspaceMonitors) do
    hl.workspace_rule({ workspace = workspace, monitor = monitor })
end

-- Example rules (from the wiki)
-- hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false })
-- hl.workspace_rule({ workspace = "name:coding", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true, monitor = "DP-1" })
-- hl.workspace_rule({ workspace = "8", border_size = 8 })
-- hl.workspace_rule({ workspace = "name:Hello", monitor = ultrawide, default = true })
-- hl.workspace_rule({ workspace = "5", on_created_empty = "[float] firefox" })
-- hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
