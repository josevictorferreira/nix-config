# Theme Switcher Configuration Plan

## Executive Summary

This document outlines a comprehensive, idiomatic Nix approach to centralized theme management across all programs. The design enables:
- **Single source of truth** for themes via `jvf.theming` module
- **Easy theme switching** with one option (`jvf.theming.activeTheme = "catppuccin-mocha"`)
- **Runtime theme switching** with time-based or manual triggers
- **Type-safe theme definitions** using NixOS module system
- **Per-program theme overrides** when needed
- **Seamless integration** with existing wrappers system

---

## Current State Analysis

### Problems Identified
1. **Scattered theme definitions**: Each program hardcodes its own colors
   - `alacritty.nix`: Hardcoded Kanagawa-like colors
   - `ghostty.nix`: `theme = "Atom One Dark"`
   - `kitty.nix`: No theme, just opacity
   - `waybar/`: 34+ separate CSS files with different themes
   - `rofi/`: 21+ theme files with no standardization

2. **No centralized color palette**: Colors duplicated across configs

3. **No runtime switching capability**: Changes require full rebuild

4. **Inconsistent theming**: Programs don't share the same visual identity

---

## Proposed Architecture

### Directory Structure

```
modules/
  theming/
    # Core theme infrastructure
    default.nix              # Main module exporting all theming functionality
    
    # Theme definitions (color palettes)
    themes/
      catppuccin-mocha.nix   # Full color palette
      catppuccin-latte.nix
      tokyonight-night.nix
      tokyonight-day.nix
      kanagawa-wave.nix
      monokai-pro.nix
      nord.nix
      gruvbox-dark.nix
      rose-pine.nix
      
    # Per-program theme generators
    generators/
      alacritty.nix          # Converts theme palette -> alacritty config
      kitty.nix              # Converts theme palette -> kitty config
      ghostty.nix            # Converts theme palette -> ghostty config
      waybar.nix             # Converts theme palette -> waybar CSS
      rofi.nix               # Converts theme palette -> rofi rasi
      gtk.nix                # Converts theme palette -> GTK theme
      hyprland.nix           # Converts theme palette -> Hyprland colors
      swaync.nix             # Converts theme palette -> notification styling
      wlogout.nix            # Converts theme palette -> logout menu
      kvantum.nix            # Qt theming
      # ... add more as needed
    
    # Runtime switching utilities
    runtime/
      switcher.nix           # Script to switch themes without rebuild
      scheduler.nix          # Time-based theme switching daemon
      ipc.nix                # IPC interface for theme switching
```

---

## Core Theme Module Design

### `/modules/theming/default.nix`

**Responsibility**: Central module that:
1. Defines the theme type system
2. Exposes `jvf.theming.*` options
3. Imports all theme definitions and generators
4. Manages theme selection logic
5. Provides runtime switching capabilities

**Key Options**:
```nix
{
  options.jvf.theming = {
    enable = lib.mkEnableOption "centralized theme management";
    
    # Primary theme selection
    activeTheme = lib.mkOption {
      type = lib.types.enum [
        "catppuccin-mocha"
        "catppuccin-latte"
        "tokyonight-night"
        "tokyonight-day"
        "kanagawa-wave"
        "monokai-pro"
        "nord"
        "gruvbox-dark"
        "rose-pine"
      ];
      default = "catppuccin-mocha";
      description = "Active system-wide theme";
    };
    
    # Time-based switching
    scheduleEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automatic time-based theme switching";
    };
    
    schedule = lib.mkOption {
      type = lib.types.submodule {
        options = {
          lightTheme = lib.mkOption {
            type = lib.types.str;
            default = "catppuccin-latte";
          };
          darkTheme = lib.mkOption {
            type = lib.types.str;
            default = "catppuccin-mocha";
          };
          lightStartHour = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Hour to switch to light theme (24h format)";
          };
          darkStartHour = lib.mkOption {
            type = lib.types.int;
            default = 19;
            description = "Hour to switch to dark theme (24h format)";
          };
        };
      };
      default = {};
    };
    
    # Runtime switching support
    runtime = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable runtime theme switching without rebuild";
      };
      
      method = lib.mkOption {
        type = lib.types.enum [ "symlink" "reload-signal" "hybrid" ];
        default = "hybrid";
        description = ''
          Method for runtime switching:
          - symlink: Switch config symlinks (requires program restart)
          - reload-signal: Send reload signals to programs
          - hybrid: Use best method per-program
        '';
      };
    };
    
    # Per-program overrides
    overrides = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = { alacritty = "tokyonight-night"; };
      description = "Override theme for specific programs";
    };
    
    # Advanced: custom color overrides
    customColors = lib.mkOption {
      type = lib.types.nullOr themeColorType;
      default = null;
      description = "Override specific colors in active theme";
    };
  };
}
```

---

## Theme Type System

### Color Palette Schema

Every theme must define this standardized color palette:

```nix
# Type definition in theming/default.nix
themeColorType = lib.types.submodule {
  options = {
    # Base colors
    base00 = lib.mkOption { type = lib.types.str; }; # Background
    base01 = lib.mkOption { type = lib.types.str; }; # Lighter background
    base02 = lib.mkOption { type = lib.types.str; }; # Selection background
    base03 = lib.mkOption { type = lib.types.str; }; # Comments, invisibles
    base04 = lib.mkOption { type = lib.types.str; }; # Dark foreground
    base05 = lib.mkOption { type = lib.types.str; }; # Default foreground
    base06 = lib.mkOption { type = lib.types.str; }; # Light foreground
    base07 = lib.mkOption { type = lib.types.str; }; # Lightest foreground
    
    # ANSI colors (terminals)
    base08 = lib.mkOption { type = lib.types.str; }; # Red
    base09 = lib.mkOption { type = lib.types.str; }; # Orange
    base0A = lib.mkOption { type = lib.types.str; }; # Yellow
    base0B = lib.mkOption { type = lib.types.str; }; # Green
    base0C = lib.mkOption { type = lib.types.str; }; # Cyan
    base0D = lib.mkOption { type = lib.types.str; }; # Blue
    base0E = lib.mkOption { type = lib.types.str; }; # Magenta
    base0F = lib.mkOption { type = lib.types.str; }; # Brown
    
    # UI-specific (optional, with defaults)
    accent = lib.mkOption { 
      type = lib.types.str; 
      default = base0D; # Usually blue
      description = "Primary accent color";
    };
    
    urgent = lib.mkOption {
      type = lib.types.str;
      default = base08; # Usually red
      description = "Urgent/error indicator";
    };
    
    success = lib.mkOption {
      type = lib.types.str;
      default = base0B; # Usually green
    };
    
    warning = lib.mkOption {
      type = lib.types.str;
      default = base0A; # Usually yellow
    };
  };
};

# Metadata type
themeMetadataType = lib.types.submodule {
  options = {
    name = lib.mkOption { type = lib.types.str; };
    variant = lib.mkOption { 
      type = lib.types.enum [ "dark" "light" ];
    };
    author = lib.mkOption { type = lib.types.str; };
    description = lib.mkOption { type = lib.types.str; default = ""; };
  };
};

# Full theme type
themeType = lib.types.submodule {
  options = {
    meta = lib.mkOption { type = themeMetadataType; };
    colors = lib.mkOption { type = themeColorType; };
  };
};
```

### Example Theme Definition

```nix
# modules/theming/themes/catppuccin-mocha.nix
{ lib, ... }:

{
  meta = {
    name = "Catppuccin Mocha";
    variant = "dark";
    author = "Catppuccin";
    description = "Soothing pastel theme for the high-spirited!";
  };
  
  colors = {
    # Base16 mapping
    base00 = "#1e1e2e"; # base/background
    base01 = "#181825"; # mantle
    base02 = "#313244"; # surface0
    base03 = "#45475a"; # surface1/comments
    base04 = "#585b70"; # surface2
    base05 = "#cdd6f4"; # text/foreground
    base06 = "#f5e0dc"; # rosewater
    base07 = "#b4befe"; # lavender
    
    # ANSI
    base08 = "#f38ba8"; # red
    base09 = "#fab387"; # peach/orange
    base0A = "#f9e2af"; # yellow
    base0B = "#a6e3a1"; # green
    base0C = "#94e2d5"; # teal/cyan
    base0D = "#89b4fa"; # blue
    base0E = "#cba6f7"; # mauve/magenta
    base0F = "#f2cdcd"; # flamingo/brown
    
    # UI colors (using Catppuccin named colors)
    accent = "#89b4fa";    # blue
    urgent = "#f38ba8";    # red
    success = "#a6e3a1";   # green
    warning = "#f9e2af";   # yellow
  };
}
```

---

## Generator Functions

Each program needs a generator that converts the universal theme palette into its specific config format.

### Example: Alacritty Generator

```nix
# modules/theming/generators/alacritty.nix
{ lib, ... }:

# theme: the selected theme attrset
# settings: existing alacritty settings to merge with
theme: settings:

let
  colors = theme.colors;
in
lib.recursiveUpdate settings {
  colors = {
    primary = {
      background = colors.base00;
      foreground = colors.base05;
    };
    
    cursor = {
      text = colors.base00;
      cursor = colors.base05;
    };
    
    normal = {
      black = colors.base00;
      red = colors.base08;
      green = colors.base0B;
      yellow = colors.base0A;
      blue = colors.base0D;
      magenta = colors.base0E;
      cyan = colors.base0C;
      white = colors.base05;
    };
    
    bright = {
      black = colors.base03;
      red = colors.base08;
      green = colors.base0B;
      yellow = colors.base0A;
      blue = colors.base0D;
      magenta = colors.base0E;
      cyan = colors.base0C;
      white = colors.base07;
    };
    
    selection = {
      background = colors.base02;
      foreground = colors.base05;
    };
  };
}
```

### Example: Waybar Generator

```nix
# modules/theming/generators/waybar.nix
{ lib, pkgs, ... }:

theme: 

let
  c = theme.colors;
  
  # Helper to convert hex to rgba
  hexToRgba = hex: alpha: 
    let
      r = lib.toInt "0x${builtins.substring 1 2 hex}";
      g = lib.toInt "0x${builtins.substring 3 2 hex}";
      b = lib.toInt "0x${builtins.substring 5 2 hex}";
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
in
pkgs.writeText "waybar-theme.css" ''
  /* Generated theme: ${theme.meta.name} */
  
  * {
    /* Color definitions */
    --background: ${c.base00};
    --background-alt: ${c.base01};
    --surface: ${c.base02};
    --foreground: ${c.base05};
    --comment: ${c.base03};
    
    --red: ${c.base08};
    --orange: ${c.base09};
    --yellow: ${c.base0A};
    --green: ${c.base0B};
    --cyan: ${c.base0C};
    --blue: ${c.base0D};
    --magenta: ${c.base0E};
    
    --accent: ${c.accent};
    --urgent: ${c.urgent};
    --success: ${c.success};
    --warning: ${c.warning};
    
    /* Transparency variants */
    --background-transparent: ${hexToRgba c.base00 "0.8"};
    --surface-transparent: ${hexToRgba c.base02 "0.6"};
  }
  
  window#waybar {
    background: var(--background-transparent);
    color: var(--foreground);
  }
  
  #workspaces button {
    color: var(--comment);
  }
  
  #workspaces button.active {
    color: var(--accent);
    border-bottom: 2px solid var(--accent);
  }
  
  #workspaces button.urgent {
    color: var(--urgent);
  }
  
  #clock {
    color: var(--blue);
  }
  
  #battery.warning {
    color: var(--warning);
  }
  
  #battery.critical {
    color: var(--urgent);
  }
  
  #network.disconnected {
    color: var(--urgent);
  }
  
  #pulseaudio.muted {
    color: var(--comment);
  }
  
  /* Add all other waybar elements... */
''
```

---

## Integration with Existing Program Modules

### Modified Program Module Pattern

Each program module should:
1. Check if `jvf.theming.enable` is true
2. Use theme generator if enabled
3. Allow manual overrides

**Example: Updated `alacritty.nix`**

```nix
{ lib, pkgs, config, username, ... }:

let
  cfg = config.jvf.programs.alacritty;
  themingCfg = config.jvf.theming;
  
  # Get active theme for this program
  activeTheme = 
    if themingCfg.enable then
      let
        themeName = themingCfg.overrides.alacritty or themingCfg.activeTheme;
        theme = themingCfg.themes.${themeName};
        generator = import ../theming/generators/alacritty.nix { inherit lib; };
      in
        generator theme cfg.settings
    else
      cfg.settings;
  
  # Default settings (non-theme stuff)
  defaultConfig = {
    env = {
      TERM = "tmux-256color";
    };
    font = {
      size = 14.0;
      normal.family = "JetBrainsMonoNL Nerd Font";
      # ... rest of font config
    };
    scrolling = {
      history = 100000;
      multiplier = 3;
    };
    # NOTE: colors removed - now managed by theming system
  };
in
{
  options.jvf.programs.alacritty = {
    enable = lib.mkEnableOption "alacritty, a GPU-accelerated terminal emulator";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
    };
    package = lib.mkPackageOption pkgs "alacritty" { };
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig;
      description = "Alacritty settings (theme applied automatically if theming enabled)";
    };
  };
  
  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.alacritty = {
      packages = [ cfg.package ];
      configs = {
        "alacritty.toml" = activeTheme; # Uses themed config
      };
    };
    
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };
}
```

---

## Runtime Theme Switching

### Strategy

**Problem**: Nix configs are immutable after build - can't change themes without rebuild.

**Solution**: Multi-layered approach

1. **Symlink switching** (for configs)
   - Generate ALL theme variants during build
   - Use symlinks to point to active theme
   - Switch by updating symlink

2. **Reload signals** (for running programs)
   - Send SIGHUP or program-specific reload signal
   - Some programs hot-reload configs

3. **IPC commands** (for Hyprland ecosystem)
   - `hyprctl reload`
   - `killall -SIGUSR1 waybar`
   - etc.

### Implementation

```nix
# modules/theming/runtime/switcher.nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.theming;
  
  # Generate all theme configs for each program
  allThemeConfigs = lib.mapAttrs (themeName: theme:
    {
      alacritty = generateAlacrittyConfig theme;
      kitty = generateKittyConfig theme;
      waybar = generateWaybarConfig theme;
      # ... for each program
    }
  ) cfg.themes;
  
  # Theme switcher script
  themeSwitcher = pkgs.writeShellApplication {
    name = "jvf-theme-switch";
    runtimeInputs = [ pkgs.jq pkgs.coreutils ];
    text = ''
      THEME_NAME="''${1:-}"
      
      if [ -z "$THEME_NAME" ]; then
        echo "Usage: jvf-theme-switch <theme-name>"
        echo "Available themes:"
        ${lib.concatStringsSep "\n" (map (t: "  echo '  - ${t}'") (lib.attrNames cfg.themes))}
        exit 1
      fi
      
      # Validate theme exists
      if [ ! -d "${themeConfigDir}/$THEME_NAME" ]; then
        echo "Error: Theme '$THEME_NAME' not found"
        exit 1
      fi
      
      echo "Switching to theme: $THEME_NAME"
      
      # Update symlinks for each program
      ${lib.concatStringsSep "\n" (map (prog: ''
        ln -sf "${themeConfigDir}/$THEME_NAME/${prog}" "$HOME/.config/${prog}/theme"
      '') supportedPrograms)}
      
      # Reload programs
      echo "Reloading programs..."
      
      # Alacritty/Kitty: requires restart (notify user)
      notify-send "Theme Changed" "Restart terminals to apply theme: $THEME_NAME"
      
      # Waybar: reload
      killall -SIGUSR2 waybar 2>/dev/null || true
      
      # Hyprland: reload
      hyprctl reload config-only 2>/dev/null || true
      
      # Rofi: no reload needed (reads on launch)
      
      # GTK: update settings
      gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME"
      
      # Save current theme to state file
      echo "$THEME_NAME" > "$HOME/.config/jvf-theming/current-theme"
      
      echo "Theme switched successfully!"
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.runtime.enable) {
    environment.systemPackages = [ themeSwitcher ];
    
    # Install all theme configs
    jvf.wrappers.users.${username}.programs.jvf-theming = {
      configs = allThemeConfigs;
    };
  };
}
```

### Time-based Scheduler

```nix
# modules/theming/runtime/scheduler.nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.theming;
  
  themeScheduler = pkgs.writeShellApplication {
    name = "jvf-theme-scheduler";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      CURRENT_HOUR=$(date +%H)
      LIGHT_START=${toString cfg.schedule.lightStartHour}
      DARK_START=${toString cfg.schedule.darkStartHour}
      
      if [ "$CURRENT_HOUR" -ge "$LIGHT_START" ] && [ "$CURRENT_HOUR" -lt "$DARK_START" ]; then
        TARGET_THEME="${cfg.schedule.lightTheme}"
      else
        TARGET_THEME="${cfg.schedule.darkTheme}"
      fi
      
      CURRENT_THEME=$(cat "$HOME/.config/jvf-theming/current-theme" 2>/dev/null || echo "")
      
      if [ "$TARGET_THEME" != "$CURRENT_THEME" ]; then
        echo "Time-based theme switch: $CURRENT_THEME -> $TARGET_THEME"
        jvf-theme-switch "$TARGET_THEME"
      fi
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.scheduleEnabled) {
    # Systemd timer (NixOS)
    systemd.user.services.jvf-theme-scheduler = lib.mkIf (!pkgs.stdenv.isDarwin) {
      description = "JVF Theme Scheduler";
      script = "${themeScheduler}/bin/jvf-theme-scheduler";
    };
    
    systemd.user.timers.jvf-theme-scheduler = lib.mkIf (!pkgs.stdenv.isDarwin) {
      description = "JVF Theme Scheduler Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
    
    # Launchd timer (macOS)
    launchd.user.agents.jvf-theme-scheduler = lib.mkIf pkgs.stdenv.isDarwin {
      serviceConfig = {
        ProgramArguments = [ "${themeScheduler}/bin/jvf-theme-scheduler" ];
        StartInterval = 3600; # Every hour
        RunAtLoad = true;
      };
    };
  };
}
```

---

## Migration Path

### Phase 1: Infrastructure Setup (Week 1)
1. Create `modules/theming/default.nix` with type system
2. Define 2-3 initial themes (catppuccin-mocha, catppuccin-latte, tokyonight-night)
3. Create generators for:
   - Alacritty
   - Kitty
   - Ghostty
4. Test basic theme switching

### Phase 2: Terminal & Shell (Week 2)
5. Migrate alacritty.nix to use theming
6. Migrate kitty.nix to use theming
7. Migrate ghostty.nix to use theming
8. Create runtime switcher script
9. Test theme switching without rebuild

### Phase 3: Desktop Environment (Week 3)
10. Create waybar generator
11. Create rofi generator
12. Create GTK theme generator
13. Create Hyprland generator
14. Consolidate waybar CSS files

### Phase 4: Additional Programs (Week 4)
15. Create generators for:
    - swaync
    - wlogout
    - kvantum
    - Any other themed programs
16. Add more theme variants (gruvbox, nord, etc.)

### Phase 5: Advanced Features (Week 5+)
17. Implement time-based scheduler
18. Add theme preview system
19. Create theme override system
20. Document theme creation guide

---

## Usage Examples

### Basic Usage

```nix
# In your host config (hosts/nixos-desktop/config.nix)
{
  jvf.theming = {
    enable = true;
    activeTheme = "catppuccin-mocha";
  };
  
  # Programs automatically themed
  jvf.programs.alacritty.enable = true;
  jvf.programs.kitty.enable = true;
  jvf.desktop.hyprland.enable = true;
}
```

### Time-based Switching

```nix
{
  jvf.theming = {
    enable = true;
    scheduleEnabled = true;
    schedule = {
      lightTheme = "catppuccin-latte";
      darkTheme = "catppuccin-mocha";
      lightStartHour = 7;   # 7 AM -> light theme
      darkStartHour = 19;   # 7 PM -> dark theme
    };
  };
}
```

### Per-program Overrides

```nix
{
  jvf.theming = {
    enable = true;
    activeTheme = "catppuccin-mocha";
    
    # Alacritty uses different theme
    overrides.alacritty = "tokyonight-night";
    
    # Custom color tweaks
    customColors = {
      accent = "#ff79c6"; # Override accent color
    };
  };
}
```

### Manual Runtime Switching

```bash
# Switch to a different theme
jvf-theme-switch catppuccin-latte

# List available themes
jvf-theme-switch

# Check current theme
cat ~/.config/jvf-theming/current-theme
```

---

## Technical Considerations

### Performance
- **Build time**: All themes generated during build
  - **Mitigation**: Only generate for enabled programs
  - **Estimated cost**: ~100-200 extra derivations
  - **Benefit**: Zero-cost runtime switching

- **Disk space**: Multiple config copies per theme
  - **Estimated**: ~10-50KB per program per theme
  - **For 5 programs × 8 themes**: ~2-4MB total (negligible)

### Cross-platform Compatibility
- Theme type system: Pure Nix (works everywhere)
- Runtime switcher: Needs platform-specific reload commands
- Scheduler: Different implementation for systemd vs launchd
- **Solution**: Use platform detection (isDarwin) in generators

### Wallust Integration
- Current wallust generates themes from wallpapers
- **Integration strategy**:
  1. Keep wallust as separate `jvf.desktop.hyprland.wallust` module
  2. Make wallust write to `~/.config/jvf-theming/wallust-generated`
  3. Add `wallust-auto` as dynamic theme option
  4. Theme switcher can select wallust-generated theme
  5. Wallust script calls `jvf-theme-switch wallust-auto` after generation

### Testing Strategy
1. **Unit tests**: Test each generator with fixture themes
2. **Integration tests**: NixOS VM tests with theme switching
3. **Visual tests**: Screenshots of themed apps for regression detection
4. **Manual QA**: Create test checklist per theme/program combo

---

## Alternative Approaches Considered

### 1. Home Manager Integration
**Pros**: Existing theme infrastructure, user-level management
**Cons**: You explicitly don't use Home Manager, adds dependency
**Decision**: ❌ Not aligned with repo architecture

### 2. Stylix/nix-colors
**Pros**: Mature ecosystem, standardized Base16 schemes
**Cons**: Opinionated, may conflict with custom modules
**Decision**: ⚠️ Consider as inspiration, don't adopt directly

### 3. Single Theme File with Imports
**Pros**: Simpler, less abstraction
**Cons**: Harder to switch themes, no runtime support
**Decision**: ❌ Too inflexible

### 4. Proposed Architecture
**Pros**: 
- Idiomatic Nix module system
- Type-safe with validation
- Runtime switching capability
- Extensible for new programs/themes
- No external dependencies
- Aligns with existing wrappers pattern

**Cons**:
- More initial complexity
- Requires migration effort

**Decision**: ✅ **Selected approach**

---

## Success Metrics

1. **Single configuration point**: Theme set in one place (`jvf.theming.activeTheme`)
2. **Visual consistency**: All programs use same color palette
3. **Easy switching**: Change theme in <5 seconds (runtime) or one rebuild
4. **Maintainability**: Adding new theme takes <30 minutes
5. **Extensibility**: Adding program generator takes <1 hour
6. **Performance**: No noticeable build time increase (<5%)

---

## Open Questions

1. **Font theming**: Should fonts be part of theme system or separate?
   - **Recommendation**: Keep separate - fonts are more persistent than colors

2. **Wallpaper coordination**: Should themes suggest wallpapers?
   - **Recommendation**: Optional metadata field, not enforced

3. **Cursor theme**: Include in theming system?
   - **Recommendation**: Yes - add `cursorTheme` field to theme metadata

4. **Icon theme**: GTK/Qt icon themes?
   - **Recommendation**: Yes - especially for GTK generator

5. **Theme variants**: Support multiple variants per theme (e.g., mocha-blue, mocha-pink)?
   - **Recommendation**: Phase 2 feature - allow theme composition

---

## Implementation Checklist

- [ ] Create `modules/theming/` directory structure
- [ ] Implement core type system in `default.nix`
- [ ] Define 3 base themes (catppuccin-mocha/latte, tokyonight)
- [ ] Create alacritty generator + test
- [ ] Create kitty generator + test
- [ ] Create ghostty generator + test
- [ ] Migrate alacritty.nix to use theming
- [ ] Migrate kitty.nix to use theming
- [ ] Migrate ghostty.nix to use theming
- [ ] Create runtime switcher script
- [ ] Create waybar generator
- [ ] Create rofi generator
- [ ] Create GTK generator
- [ ] Create hyprland generator
- [ ] Implement time-based scheduler
- [ ] Add 5 more theme variants
- [ ] Write theme creation documentation
- [ ] Create example custom theme
- [ ] Performance benchmarks
- [ ] Visual regression test suite

---

## References & Resources

- [Base16 Spec](https://github.com/chriskempson/base16): Standard color scheme format
- [Catppuccin Palette](https://github.com/catppuccin/catppuccin): Reference implementation
- [Tokyo Night](https://github.com/tokyo-night/tokyo-night-vscode-theme): Another reference
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules): Official docs
- [Stylix](https://github.com/danth/stylix): For inspiration (but not direct use)

---

## Conclusion

This architecture provides:
- ✅ **Single source of truth** for themes
- ✅ **Type-safe** configuration
- ✅ **Runtime switching** capability
- ✅ **Time-based automation**
- ✅ **Idiomatic Nix** design
- ✅ **Seamless integration** with existing systems
- ✅ **Cross-platform** support (NixOS + macOS)

The modular design allows incremental adoption - start with terminal emulators, then expand to desktop environment. Each generator is independent, making maintenance and testing straightforward.

**Estimated implementation time**: 3-5 weeks part-time
**Long-term maintenance**: Low (themes rarely change structure)
**User experience improvement**: High (single-line theme changes)
