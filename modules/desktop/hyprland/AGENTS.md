# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Commit:** N/A (Dynamic)
**Branch:** main

## OVERVIEW
Hyprland window manager config. Core desktop module.
Modular setup. Deep nesting. Heavy visual integration (Wallust).
Covers theming (GTK/QT/Kvantum), bars, launchers, notifications.

## STRUCTURE
```
modules/desktop/hyprland/
├── hypr/              # Compositor core
│   ├── configs/       # Base settings (Static)
│   ├── UserConfigs/   # User overrides (Dynamic)
│   └── scripts/       # Logic glue
├── waybar/            # Status bar presets
├── rofi/              # Launcher themes
├── ags/               # JS widgets
├── swaync/            # Notifications
└── wallust/           # Color engine templates
```

## WHERE TO LOOK
- `hypr/hyprland.conf`: Entry point. Orchestrates imports.
- `hypr/UserConfigs/WindowRules.conf`: App behavior. Floating rules.
- `hypr/UserConfigs/UserKeybinds.conf`: Shortcut definitions.
- `default.nix`: Nix module. Options & package sets.

## CONVENTIONS
- **Split Config**: Base logic in `configs/`. User overrides in `UserConfigs/`.
- **Dynamic Theming**: Wallust colors drive CSS/Conf across all apps.
- **Raw Format**: CSS/JS/Conf kept as native files. Not converted to Nix attrs.
- **Modular Imports**: Sub-components managed via discrete `.nix` files in `default.nix`.

## ANTI-PATTERNS
- **Monolithic Binds**: No shortcuts in root `hyprland.conf`. Use `UserKeybinds.conf`.
- **Hardcoded Hex**: Avoid static colors. Use Wallust vars (`@color0`).
- **Nix-fying CSS**: Don't rewrite Waybar/AGS styles as Nix attributes.
