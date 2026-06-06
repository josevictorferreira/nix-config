# === Theme Options ===
# Provides jvf.theme.{colors, fonts, gtk} as the single source of truth
# for visual theming across all desktop modules.
#
# Colors use a base16 palette (color0-color15) + semantic aliases.
# Per-app adapters live in each desktop module -- they consume config.jvf.theme.
#
# Set jvf.theme.active in your host config to select a preset, or
# override jvf.theme.colors / jvf.theme.fonts directly.

{ lib, config, ... }:
let
  inherit (lib) mkOption types;

  # A single hex color (6 chars, no #)
  hexColorType = types.strMatching "[0-9a-fA-F]{6}";

  # Full 16-color palette + foreground/background/cursor
  paletteType = types.submodule {
    options = {
      background = mkOption {
        type = hexColorType;
        description = "Background color (hex, no #).";
      };
      foreground = mkOption {
        type = hexColorType;
        description = "Foreground color (hex, no #).";
      };
      cursor = mkOption {
        type = hexColorType;
        description = "Cursor color (hex, no #).";
      };
      color0 = mkOption {
        type = hexColorType;
        description = "Base16 color 0 (black).";
      };
      color1 = mkOption {
        type = hexColorType;
        description = "Base16 color 1 (red).";
      };
      color2 = mkOption {
        type = hexColorType;
        description = "Base16 color 2 (green).";
      };
      color3 = mkOption {
        type = hexColorType;
        description = "Base16 color 3 (yellow).";
      };
      color4 = mkOption {
        type = hexColorType;
        description = "Base16 color 4 (blue).";
      };
      color5 = mkOption {
        type = hexColorType;
        description = "Base16 color 5 (magenta).";
      };
      color6 = mkOption {
        type = hexColorType;
        description = "Base16 color 6 (cyan).";
      };
      color7 = mkOption {
        type = hexColorType;
        description = "Base16 color 7 (white).";
      };
      color8 = mkOption {
        type = hexColorType;
        description = "Base16 color 8 (bright black).";
      };
      color9 = mkOption {
        type = hexColorType;
        description = "Base16 color 9 (bright red).";
      };
      color10 = mkOption {
        type = hexColorType;
        description = "Base16 color 10 (bright green).";
      };
      color11 = mkOption {
        type = hexColorType;
        description = "Base16 color 11 (bright yellow).";
      };
      color12 = mkOption {
        type = hexColorType;
        description = "Base16 color 12 (bright blue).";
      };
      color13 = mkOption {
        type = hexColorType;
        description = "Base16 color 13 (bright magenta).";
      };
      color14 = mkOption {
        type = hexColorType;
        description = "Base16 color 14 (bright cyan).";
      };
      color15 = mkOption {
        type = hexColorType;
        description = "Base16 color 15 (bright white).";
      };
    };
  };

  fontsType = types.submodule {
    options = {
      monospace = mkOption {
        type = types.str;
        default = "JetBrainsMono Nerd Font";
        description = "Monospace font family for terminals, editors, status bars.";
      };
      sansSerif = mkOption {
        type = types.str;
        default = "Fira Code";
        description = "Sans-serif font for GTK and UI elements.";
      };
      size = mkOption {
        type = types.int;
        default = 14;
        description = "Base font size (pt) for UI.";
      };
    };
  };

  gtkType = types.submodule {
    options = {
      theme = mkOption {
        type = types.str;
        default = "Andromeda-dark";
        description = "GTK theme name.";
      };
      iconTheme = mkOption {
        type = types.str;
        default = "Flat-Remix-Blue-Dark";
        description = "Icon theme name.";
      };
      cursorTheme = mkOption {
        type = types.str;
        default = "Bibata-Modern-Ice";
        description = "Cursor theme name.";
      };
      cursorSize = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size in pixels.";
      };
      applicationPreferDarkTheme = mkOption {
        type = types.bool;
        default = true;
        description = "Whether GTK apps should prefer dark theme variant.";
      };
    };
  };

  qtPreferencesType = types.submodule {
    options = {
      style = mkOption {
        type = types.str;
        default = "kvantum";
        description = "Qt widget style.";
      };
      colorScheme = mkOption {
        type = types.str;
        default = "Kvantum";
        description = "Qt color scheme name.";
      };
    };
  };

  artifactsType = types.attrsOf types.str;

  # Rofi needs semantic mappings derived from the base16 palette
  rofiSemanticType = types.submodule (
    { ... }:
    {
      options = {
        activeBackground = mkOption {
          type = hexColorType;
          description = "Active item background.";
        };
        activeForeground = mkOption {
          type = hexColorType;
          description = "Active item foreground.";
        };
        normalBackground = mkOption {
          type = hexColorType;
          description = "Normal item background.";
        };
        normalForeground = mkOption {
          type = hexColorType;
          description = "Normal item foreground.";
        };
        urgentBackground = mkOption {
          type = hexColorType;
          description = "Urgent item background.";
        };
        urgentForeground = mkOption {
          type = hexColorType;
          description = "Urgent item foreground.";
        };
        selectedBackground = mkOption {
          type = hexColorType;
          description = "Selected item background.";
        };
        selectedForeground = mkOption {
          type = hexColorType;
          description = "Selected item foreground.";
        };
        borderColor = mkOption {
          type = hexColorType;
          description = "Border color.";
        };
      };
    }
  );

  # Presets registry
  presetType = types.submodule {
    options = {
      colors = mkOption {
        type = paletteType;
        description = "Color palette for this preset.";
      };
      fonts = mkOption {
        type = fontsType;
        default = { };
        description = "Font overrides for this preset.";
      };
      gtk = mkOption {
        type = gtkType;
        default = { };
        description = "GTK overrides for this preset.";
      };
      qt = mkOption {
        type = qtPreferencesType;
        default = { };
        description = "Qt toolkit preferences for this preset.";
      };
      rofiSemantic = mkOption {
        type = rofiSemanticType;
        description = "Rofi semantic color mappings.";
      };
      backgroundAlpha = mkOption {
        type = types.str;
        default = "0.25";
        description = "Background alpha for transparent panels (waybar, etc).";
      };
      artifacts = mkOption {
        type = artifactsType;
        default = { };
        description = "Consumer category subpaths under the profile artifact directory.";
      };
    };
  };

  cfg = config.jvf.theme;
in
{
  options.jvf.theme = {
    active = mkOption {
      type = types.str;
      default = "tokyonight-night";
      description = "Name of the active theme preset from jvf.theme.presets.";
    };

    presets = mkOption {
      type = types.attrsOf presetType;
      default = { };
      description = "Available theme presets.";
    };

    # Resolved values (from active preset, can be overridden)
    colors = mkOption {
      type = paletteType;
      default = cfg.presets.${cfg.active}.colors;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.colors";
      description = "Active color palette. Defaults to the active preset's colors.";
    };

    fonts = mkOption {
      type = fontsType;
      default = cfg.presets.${cfg.active}.fonts;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.fonts";
      description = "Active fonts. Defaults to the active preset's fonts.";
    };

    gtk = mkOption {
      type = gtkType;
      default = cfg.presets.${cfg.active}.gtk;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.gtk";
      description = "Active GTK settings. Defaults to the active preset's GTK.";
    };

    qt = mkOption {
      type = qtPreferencesType;
      default = cfg.presets.${cfg.active}.qt;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.qt";
      description = "Active Qt preferences.";
    };

    rofiSemantic = mkOption {
      type = rofiSemanticType;
      default = cfg.presets.${cfg.active}.rofiSemantic;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.rofiSemantic";
      description = "Active rofi semantic colors. Defaults to the active preset's.";
    };

    backgroundAlpha = mkOption {
      type = types.str;
      default = cfg.presets.${cfg.active}.backgroundAlpha;
      defaultText = lib.literalExpression "config.jvf.theme.presets.${config.jvf.theme.active}.backgroundAlpha";
      description = "Background alpha for transparent panels.";
    };

    profiles = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          preset = mkOption { type = types.str; };
          displayName = mkOption { type = types.str; };
          artifacts = mkOption { type = artifactsType; default = { }; };
        };
      });
      default = { };
      description = "Runtime profiles (dark, light) mapping to presets.";
    };

    artifactContract = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Maps consumer category names to subdirectory names under profile artifact dir.";
    };

    profileArtifacts = mkOption {
      type = types.attrsOf (types.attrsOf types.package);
      default = { };
      description = "Registered adapter artifacts: profile -> category -> derivation.";
    };

    paths = mkOption {
      type = types.submodule {
        options = {
          artifactBase = mkOption {
            type = types.str;
            default = ".local/share/jvf-theme/profiles";
          };
          runtimeState = mkOption {
            type = types.str;
            default = ".local/state/jvf-theme";
          };
        };
      };
      default = { };
    };

    profileSchedule = mkOption {
      type = types.submodule {
        options = {
          light = mkOption {
            type = types.submodule {
              options = {
                start = mkOption { type = types.str; default = "06:00"; };
                end = mkOption { type = types.str; default = "12:00"; };
              };
            };
            default = { };
          };
        };
      };
      default = { };
    };
  };
}
