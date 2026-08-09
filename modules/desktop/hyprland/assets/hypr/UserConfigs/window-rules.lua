-- Window rules.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- In Lua each rule is one table: the effects that used to be comma-separated on
-- a single `windowrule =` line are now named fields, so the 0.55-era "explicit
-- `on` argument" quirk is gone.

-- Yazi file manager floating scratchpad
hl.window_rule({
    name = "yazi-scratchpad",
    match = { class = "^(yazi-fm)$" },
    float = true,
    center = true,
    size = { 900, 600 },
    workspace = "special:yazi silent",
})

-- Todo scratchpad floating neovim
hl.window_rule({
    name = "todo-scratchpad",
    match = { class = "^(todo-nvim)$" },
    float = true,
    center = true,
    size = { 900, 600 },
    workspace = "special:todo silent",
})

-- Quick note scratchpad floating neovim
hl.window_rule({
    name = "quick-note-scratchpad",
    match = { class = "^(quick-note-nvim)$" },
    float = true,
    center = true,
    size = { 900, 600 },
    workspace = "special:quick-note silent",
})
