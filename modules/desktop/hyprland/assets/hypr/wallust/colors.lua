-- Theme colours for the Hyprland Lua config.
--
-- This checked-in file is a placeholder: hypr.nix overwrites it during
-- activation (postInstall) with the colours from config.jvf.theme.colors, and
-- jvf-theme-switch replaces it again when switching dark/light at runtime.
-- The values below match the dark preset (tokyonight-night) so that the config
-- is still valid if the generated file is ever missing.
--
-- Consumers: UserConfigs/user-settings.lua, UserConfigs/decor-animations.lua
--
-- NOTE: hyprlock reads its colours from wallust/wallust-hyprland.conf instead
-- (hyprlock still uses hyprlang, so both files are generated from the same
-- theme source).

return {
    background = "rgb(1a1b26)",
    foreground = "rgb(c0caf5)",
    color0 = "rgb(15161e)",
    color1 = "rgb(f7768e)",
    color2 = "rgb(9ece6a)",
    color3 = "rgb(e0af68)",
    color4 = "rgb(7aa2f7)",
    color5 = "rgb(bb9af7)",
    color6 = "rgb(7dcfff)",
    color7 = "rgb(a9b1d6)",
    color8 = "rgb(414868)",
    color9 = "rgb(ff899d)",
    color10 = "rgb(9fe044)",
    color11 = "rgb(faba4a)",
    color12 = "rgb(8db0ff)",
    color13 = "rgb(c7a9ff)",
    color14 = "rgb(a4daff)",
    color15 = "rgb(c0caf5)",
}
