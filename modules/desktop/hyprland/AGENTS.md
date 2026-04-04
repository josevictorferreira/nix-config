# Hyprland Desktop Environment

**Parent:** [../../../AGENTS.md](../../../AGENTS.md)

## OVERVIEW
Hyprland Wayland compositor + Waybar + Rofi + AGS + utilities. 17 modules, 272+ asset files.

## STRUCTURE
```
hyprland/
├── default.nix      # Main hyprland config
├── ags.nix          # AGS (Aylur's GTK Shell)
├── waybar.nix       # Status bar
├── rofi.nix         # App launcher
├── cava.nix         # Audio visualizer
├── fastfetch.nix    # System info
├── gtk3.nix         # GTK theme
├── kvantum.nix      # Qt theme
├── qt5ct.nix        # Qt5 config
├── qt6ct.nix        # Qt6 config
├── swappy.nix       # Screenshot editor
├── thunar.nix       # File manager
├── wallust.nix      # Wallpaper colors
├── wlogout.nix      # Logout menu
├── xfce4.nix        # XFCE app theming
├── swaync.nix       # Notification center
└── assets/          # Co-located configs
    ├── hypr/        # Hyprland .conf files
    ├── rofi/        # .rasi themes
    ├── waybar/      # config + style.css
    ├── ags/         # AGS modules
    ├── cava/        # shaders
    ├── fastfetch/   # json config
    ├── gtk3/        # settings.ini
    ├── kvantum/     # themes
    ├── wlogout/     # icons
    └── ...
```

## WHERE TO LOOK
| Task | Location |
|------|----------|
| **Hyprland binds/rules** | `assets/hypr/` |
| **Waybar modules** | `assets/waybar/config` |
| **Rofi themes** | `assets/rofi/*.rasi` |
| **AGS widgets** | `assets/ags/` |
| **GTK/Qt theming** | `assets/gtk3/`, `assets/kvantum/` |
| **New utility module** | `modules/desktop/hyprland/<name>.nix` |

## CONVENTIONS
- **Co-located assets**: Config files live in `assets/<subsystem>/`
- **Dendritic exports**: Each module exports `flake.modules.nixos.*`
- **Enable pattern**: `jvf.desktop.hyprland.<submodule>.enable` (waybar uses `jvf.home` for config, not wrappers)
- **Asset reference**: Use relative path from module file
- **Config migration**: waybar is migrated to jvf.home for config. Other hyprland sub-modules still use wrappers translation layer.

## ANTI-PATTERNS
- **Inlining configs** - use `writeTextFile` + assets/ files
- **Hardcoded paths** - reference via `${./assets/...}`
- **Enabling by default** - all modules require explicit enable

## CONFIG NESTING GOTCHAS
- **hypr**: Uses directory-style configs (`{"hypr" = derivation;}`). The configDir flattening in wrappers.nix uses `symlinkJoin` to merge the hypr entry at root level while keeping `pypr` as subdirectory.
- **swaync**: Uses prefix-style configs (`{"swaync/config.json" = file;}`). The configDir flattening strips the `programName/` prefix to avoid double-nesting.
- Always check which pattern a module uses before modifying its config structure.
