# True Dendritic Refactor: Legacy Module Migration Plan

## Goal
Transform legacy NixOS/Darwin modules into true dendritic flake-parts modules.

## Current State
- Legacy modules in `modules/legacy/_/**`
- Wrapped by aspects (core-jvf) but not true dendritic
- True dendritic: each file defines `flake.modules.<class>.<aspect>`

## Target State
- All modules as flake-parts modules under `modules/aspects/`
- Each module contributes to `flake.modules.nixos.<name>` and/or `flake.modules.darwin.<name>`
- Legacy directory eventually empty/deletable

---

## Dependency Analysis & Priority Ranking

### Priority 1: Foundation (No Dependencies)
**Why first**: Define base options used by everything else.

| Module | Why Priority 1 |
|--------|---------------|
| `users/default.nix` | Defines `jvf.users.*` options used by roles |
| `users/wrappers.nix` | Defines `jvf.wrappers.*` used by all programs |
| `users/repositories.nix` | User git repos, minimal dependencies |

### Priority 2: Hardware (NixOS Only, Independent)
**Why early**: Hardware detection, no program dependencies.

| Module | Notes |
|--------|-------|
| `hardware/default.nix` | Aggregator for hardware modules |
| `hardware/amd-gpu.nix` | AMD GPU config |
| `hardware/bluetooth.nix` | Bluetooth service |
| `hardware/logitech.nix` | Logitech devices |
| `hardware/openrgb.nix` | RGB control |

### Priority 3: System Modules (Independent)
**Why early**: Core system settings, few cross-dependencies.

| Module | NixOS | Darwin | Notes |
|--------|-------|--------|-------|
| `system/locale.nix` | ✅ | ✅ | Language/timezone |
| `system/nixpkgs.nix` | ✅ | ✅ | Nixpkgs config |
| `system/nix-daemon.nix` | ✅ | ✅ | Nix daemon settings |
| `system/networking.nix` | ✅ | ✅ | Network configuration |
| `system/security.nix` | ✅ | ✅ | Security settings |
| `system/firewall.nix` | ✅ | ❌ | Firewall rules |
| `system/xdg.nix` | ✅ | ✅ | XDG directories |
| `system/audio.nix` | ✅ | ✅ | Audio/PipeWire |
| `system/base-programs.nix` | ✅ | ✅ | Base package sets |
| `system/base-services.nix` | ✅ | ✅ | Base system services |
| `system/display.nix` | ✅ | ❌ | Display/graphics |
| `system/environment.nix` | ✅ | ✅ | Environment variables |
| `system/flatpak.nix` | ✅ | ❌ | Flatpak support |
| `system/locale.nix` | ✅ | ✅ | Locale settings |
| `system/logind.nix` | ✅ | ❌ | Login daemon |
| `system/power-management.nix` | ✅ | ❌ | Power settings |
| `system/virtualization.nix` | ✅ | ❌ | VMs/containers |

### Priority 4: Programs (Used by Roles)
**Why mid**: Many programs used by multiple roles.

| Module | Used By | Notes |
|--------|---------|-------|
| `programs/zsh/default.nix` | development, ops, media | Shell config |
| `programs/zsh/plugins/*` | zsh | Plugin definitions |
| `programs/starship.nix` | development | Prompt |
| `programs/git.nix` | development, ops | Git config |
| `programs/neovim.nix` | development, ops | Editor |
| `programs/tmux.nix` | development | Terminal multiplexer |
| `programs/ghostty.nix` | development | Terminal |
| `programs/kitty.nix` | development | Terminal |
| `programs/alacritty.nix` | development | Terminal |
| `programs/wezterm.nix` | development | Terminal |
| `programs/fzf.nix` | development | Fuzzy finder |
| `programs/bat.nix` | development | Cat replacement |
| `programs/eza.nix` | development | LS replacement |
| `programs/zoxide.nix` | development | CD replacement |
| `programs/lazygit.nix` | development | Git TUI |
| `programs/jq.nix` | development | JSON processor |
| `programs/ripgrep.nix` | development | Grep replacement |
| `programs/btop.nix` | development | System monitor |
| `programs/direnv.nix` | development | Env management |
| `programs/yazi.nix` | development | File manager |
| `programs/walker.nix` | development | Launcher |
| `programs/wallust.nix` | development | Colorscheme |
| `programs/mycli.nix` | development | MySQL CLI |
| `programs/pgcli.nix` | development | PostgreSQL CLI |
| `programs/pgformatter.nix` | development | SQL formatter |
| `programs/mongosh.nix` | development | MongoDB CLI |
| `programs/redis.nix` | development | Redis CLI |
| `programs/ranger.nix` | development | File manager |
| `programs/yazi.nix` | development | File manager |
| `programs/zellij.nix` | development | Terminal multiplexer |

### Priority 5: Services (Standalone)
**Why mid**: Independent services, can be enabled by roles.

| Module | NixOS | Darwin | Notes |
|--------|-------|--------|-------|
| `services/smb.nix` | ✅ | ❌ | SMB client |
| `services/cephfs.nix` | ✅ | ❌ | CephFS client |
| `services/llm-proxy.nix` | ✅ | ❌ | LLM proxy |

### Priority 6: Roles (Depend on Programs/Services)
**Why later**: Import and configure programs/services.

| Module | Imports |
|--------|---------|
| `roles/development.nix` | ghostty, alacritty, kitty, git, neovim, tmux, zsh, starship |
| `roles/webDevelopment.nix` | chrome, firefox, thunderbird, chromium |
| `roles/opsDevelopment.nix` | helm, k9s, kubectl, kubectx, stern, lazydocker |
| `roles/monitoring.nix` | grafana, k9s |
| `roles/communication.nix` | slack, telegram, discord, zoom-us |
| `roles/aiDevelopment.nix` | opencode, claudecode, cursor, ai-cli, windsurf |
| `roles/localAi.nix` | ollama, fabric-ai, moondream |
| `roles/designing.nix` | figma, aseprite, krita, gimp, inkscape, blender |
| `roles/media.nix` | spotify, vlc, obs-studio, stremio, jellyfin-media-player |
| `roles/gaming.nix` | lutris, wine, gamemode, gamescope, heroic |
| `roles/networkStorage.nix` | smb, cephFs |
| `roles/privacy.nix` | protonvpn-cli, onionshare |
| `roles/documenting.nix` | obsidian, notion, libreoffice, qownnotes |

### Priority 7: Aggregators
**Why late**: Aggregate lower-level modules, updated last.

| Module | Aggregates |
|--------|-----------|
| `system/default.nix` | All system modules via `jvf.system.modules` |
| `roles/default.nix` | All role modules via `jvf.roles.active` |
| `hardware/default.nix` | Hardware modules |

### Priority 8: Desktop Environment (Complex)
**Why last**: Many interdependent modules.

| Module | Dependencies |
|--------|--------------|
| `desktop/hyprland/default.nix` | 15+ submodules |
| `desktop/hyprland/monitors.nix` | Hyprland config |
| `desktop/hyprland/workspaces.nix` | Hyprland config |
| `desktop/hyprland/input.nix` | Hyprland config |
| `desktop/hyprland/binds.nix` | Hyprland config |
| `desktop/hyprland/windowrule.nix` | Hyprland config |
| `desktop/hyprland/general.nix` | Hyprland config |
| `desktop/hyprland/decoration.nix` | Hyprland config |
| `desktop/hyprland/animations.nix` | Hyprland config |
| `desktop/hyprland/layout.nix` | Hyprland config |
| `desktop/hyprland/misc.nix` | Hyprland config |
| `desktop/hyprland/plugins/*` | Hyprland plugins |
| `desktop/hyprland/waybar/` | Waybar config |
| `desktop/hyprland/rofi/` | Rofi config |
| `desktop/hyprland/ags/` | AGS widgets |
| `desktop/hyprland/swaync/` | Notifications |
| `desktop/hyprland/wlogout/` | Logout menu |
| `desktop/hyprland/wlsunset/` | Night light |
| `desktop/hyprland/swww/` | Wallpaper |
| `desktop/hyprland/hyprlock/` | Lock screen |
| `desktop/hyprland/hypridle/` | Idle management |

### Priority 9: Complex Cross-Cutting (AI Tools)
**Why last**: Touches everything, most complex.

| Module | Complexity |
|--------|-----------|
| `common/ai-tools/default.nix` | DSL for AI agents |
| `common/ai-tools/skills.nix` | Skill definitions |
| `common/ai-tools/mcp-servers.nix` | MCP server configs |
| `common/ai-tools/rules/` | Prompt rules |

---

## Implementation Strategy

### Wave 1: Foundation (Tasks 1-3)
Refactor base options and wrapper system.

### Wave 2: System Core (Tasks 4-8)
Refactor independent system modules.

### Wave 3: Programs (Tasks 9-25)
Refactor most-used programs first.

### Wave 4: Services (Tasks 26-28)
Refactor service modules.

### Wave 5: Roles (Tasks 29-40)
Refactor roles, updating to use dendritic program aspects.

### Wave 6: Aggregators (Tasks 41-43)
Update aggregators to use dendritic modules.

### Wave 7: Hardware (Tasks 44-48)
Refactor hardware modules (NixOS only).

### Wave 8: Desktop (Tasks 49-70)
Refactor Hyprland ecosystem.

### Wave 9: AI Tools (Tasks 71-75)
Refactor complex AI tools module.

### Wave 10: Cleanup (Task 76)
Remove legacy directory, finalize.

---

## Critical Migration Rules

1. **One module = One aspect file**
   - File defines `flake.modules.nixos.<name>` and/or `flake.modules.darwin.<name>`
   - No aggregator imports multiple modules

2. **Preserve option paths**
   - Keep `jvf.<category>.<name>.enable` pattern
   - Don't break existing host configs

3. **Cross-platform where possible**
   - NixOS-only modules: don't define darwin class
   - Darwin-only modules: don't define nixos class

4. **Dependencies explicit**
   - Use `imports` in flake-parts modules to depend on other aspects
   - Example: `programs.neovim` imports `programs.zsh` if needed

5. **Incremental migration**
   - Each task: move ONE module
   - Keep `make check` green after each
   - Legacy module stays until replacement works

---

## Post-Migration Structure

```
modules/
├── aspects/                    # All dendritic aspects
│   ├── users.nix              # jfv.users options
│   ├── wrappers.nix           # jvf.wrappers system
│   ├── repositories.nix       # User git repos
│   ├── hardware-amd-gpu.nix
│   ├── hardware-bluetooth.nix
│   ├── hardware-logitech.nix
│   ├── hardware-openrgb.nix
│   ├── system-audio.nix
│   ├── system-networking.nix
│   ├── system-security.nix
│   ├── system-firewall.nix
│   ├── system-xdg.nix
│   ├── system-locale.nix
│   ├── system-nixpkgs.nix
│   ├── system-nix-daemon.nix
│   ├── system-base-programs.nix
│   ├── system-base-services.nix
│   ├── system-environment.nix
│   ├── system-display.nix
│   ├── system-flatpak.nix
│   ├── system-logind.nix
│   ├── system-power-management.nix
│   ├── system-virtualization.nix
│   ├── programs-zsh.nix
│   ├── programs-starship.nix
│   ├── programs-git.nix
│   ├── programs-neovim.nix
│   ├── programs-tmux.nix
│   ├── programs-ghostty.nix
│   ├── programs-kitty.nix
│   ├── programs-alacritty.nix
│   ├── programs-wezterm.nix
│   ├── programs-fzf.nix
│   ├── programs-bat.nix
│   ├── programs-eza.nix
│   ├── programs-zoxide.nix
│   ├── programs-lazygit.nix
│   ├── programs-jq.nix
│   ├── programs-ripgrep.nix
│   ├── programs-btop.nix
│   ├── programs-direnv.nix
│   ├── programs-yazi.nix
│   ├── programs-walker.nix
│   ├── programs-wallust.nix
│   ├── programs-mycli.nix
│   ├── programs-pgcli.nix
│   ├── programs-pgformatter.nix
│   ├── programs-mongosh.nix
│   ├── programs-redis.nix
│   ├── programs-ranger.nix
│   ├── programs-zellij.nix
│   ├── services-smb.nix
│   ├── services-cephfs.nix
│   ├── services-llm-proxy.nix
│   ├── roles-development.nix
│   ├── roles-web-development.nix
│   ├── roles-ops-development.nix
│   ├── roles-monitoring.nix
│   ├── roles-communication.nix
│   ├── roles-ai-development.nix
│   ├── roles-local-ai.nix
│   ├── roles-designing.nix
│   ├── roles-media.nix
│   ├── roles-gaming.nix
│   ├── roles-network-storage.nix
│   ├── roles-privacy.nix
│   ├── roles-documenting.nix
│   ├── desktop-hyprland.nix
│   ├── desktop-hyprland-monitors.nix
│   ├── desktop-hyprland-workspaces.nix
│   ├── desktop-hyprland-input.nix
│   ├── desktop-hyprland-binds.nix
│   ├── desktop-hyprland-windowrule.nix
│   ├── desktop-hyprland-general.nix
│   ├── desktop-hyprland-decoration.nix
│   ├── desktop-hyprland-animations.nix
│   ├── desktop-hyprland-layout.nix
│   ├── desktop-hyprland-misc.nix
│   ├── desktop-hyprland-waybar.nix
│   ├── desktop-hyprland-rofi.nix
│   ├── desktop-hyprland-ags.nix
│   ├── desktop-hyprland-swaync.nix
│   ├── desktop-hyprland-wlogout.nix
│   ├── desktop-hyprland-wlsunset.nix
│   ├── desktop-hyprland-swww.nix
│   ├── desktop-hyprland-hyprlock.nix
│   ├── desktop-hyprland-hypridle.nix
│   └── ai-tools.nix
├── hosts/
│   ├── nixos-desktop.nix
│   └── macos-macbook.nix
└── core/
    └── options.nix
```

Note: Aggregators (system/default.nix, roles/default.nix, hardware/default.nix) become unnecessary in true dendritic pattern - hosts just import specific aspects they need.

---

## Migration Example

### Before (Legacy)
```nix
# modules/legacy/_/users/default.nix
{ config, lib, ... }:
let cfg = config.jvf.users;
in {
  options.jvf.users = lib.mkOption { ... };
  config = lib.mkIf cfg.enable { ... };
}
```

### After (Dendritic)
```nix
# modules/aspects/users.nix
{ ... }:
{
  flake.modules.nixos.users = { config, lib, ... }:
    let cfg = config.jvf.users;
    in {
      options.jvf.users = lib.mkOption { ... };
      config = lib.mkIf cfg.enable { ... };
    };
  
  flake.modules.darwin.users = { config, lib, ... }:
    let cfg = config.jvf.users;
    in {
      options.jvf.users = lib.mkOption { ... };
      config = lib.mkIf cfg.enable { ... };
    };
}
```

### Host Usage
```nix
# modules/hosts/nixos-desktop.nix
{
  imports = with inputs.self.modules.nixos; [
    users
    wrappers
    system-locale
    programs-zsh
    programs-git
    roles-development
  ];
}
```
