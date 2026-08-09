-- User settings.
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- Colours come from the generated Lua module (see wallust/colors.lua). Note
-- that dotted hyprlang keys like `col.active_border` are nested tables in Lua.

local colors = require("wallust/colors")

hl.config({
    dwindle = {
        preserve_split = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        mfact = 0.5,
    },

    general = {
        border_size = 2,
        gaps_in = 6,
        gaps_out = 8,

        resize_on_border = true,

        col = {
            active_border = colors.color12,
            inactive_border = colors.color8,
        },

        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,

        sensitivity = 0, -- mouse sensitivity
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 2,
        float_switch_override_focus = false,
        mouse_refocus = false,

        touchpad = {
            disable_while_typing = true,
            natural_scroll = false,
            clickfinger_behavior = false,
            middle_button_emulation = true,
            tap_to_click = true, -- was `tap-to-click` in hyprlang
            drag_lock = false,
        },

        touchdevice = {
            enabled = true,
        },

        tablet = {
            transform = 0,
            left_handed = false,
        },
    },

    group = {
        col = {
            border_active = colors.color15,
            border_inactive = colors.color8,
        },

        groupbar = {
            col = {
                active = colors.color0,
            },
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = false,
    },

    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor = true,
        warp_on_change_workspace = true,
        no_warps = true,
    },
})
