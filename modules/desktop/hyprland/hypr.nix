# Aspect: desktop-hyprland-hypr (NixOS only)
# Hyprland compositor configuration with hypridle, hyprlock, pyprland.
# Config files managed via jvf.home.
# Theme adapter: generates wallust/wallust-hyprland.conf from jvf.theme.colors.
_:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.desktop.hyprland.hypr = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure Hyprland wrapper";
        };
      };
    };

in
{
  flake.modules.nixos.desktop-hyprland-hypr =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.hypr;
      colors = config.jvf.theme.colors;
      darkPreset = config.jvf.theme.presets.tokyonight-night;
      lightPreset = config.jvf.theme.presets.tokyonight-day;

      # Theme adapter: generate hyprland color variables from a color set
      mkHyprColorsConf = c: pkgs.writeText "wallust-hyprland.conf" ''
        $background = rgb(${c.background})
        $foreground = rgb(${c.foreground})
        $color0 = rgb(${c.color0})
        $color1 = rgb(${c.color1})
        $color2 = rgb(${c.color2})
        $color3 = rgb(${c.color3})
        $color4 = rgb(${c.color4})
        $color5 = rgb(${c.color5})
        $color6 = rgb(${c.color6})
        $color7 = rgb(${c.color7})
        $color8 = rgb(${c.color8})
        $color9 = rgb(${c.color9})
        $color10 = rgb(${c.color10})
        $color11 = rgb(${c.color11})
        $color12 = rgb(${c.color12})
        $color13 = rgb(${c.color13})
        $color14 = rgb(${c.color14})
        $color15 = rgb(${c.color15})
        $placeholderFg = ##${c.foreground}99
      '';

      # Active theme deployment (unchanged behavior)
      hyprColorsConf = mkHyprColorsConf colors;

      # Profile artifacts for dual-theme runtime switching
      darkHyprArtifact = pkgs.runCommand "theme-hypr-dark" { } ''
        mkdir -p $out
        cp ${mkHyprColorsConf darkPreset.colors} $out/wallust-hyprland.conf
      '';
      lightHyprArtifact = pkgs.runCommand "theme-hypr-light" { } ''
        mkdir -p $out
        cp ${mkHyprColorsConf lightPreset.colors} $out/wallust-hyprland.conf
      '';
    in
    {
      imports = [ mkOptions ];

      config = {
        services.hypridle.enable = false;

        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          package = pkgs.hyprland;
        };

        jvf.wrappers.users.${cfg.username}.programs.hypr = {
          packages = [
            pkgs.hypridle
            pkgs.hyprcursor
            pkgs.hyprlock
            pkgs.pyprland
          ];
        };

        jvf.home.users.${cfg.username}.items = {
          ".config/hypr" = {
            kind = "dir";
            mode = "copy";
            source = ./assets/hypr/.;
            postInstall = ''
              # Theme adapter: inject generated colors (replaces wallust runtime gen)
              mkdir -p "$TARGET_PATH/wallust"
              cp ${hyprColorsConf} "$TARGET_PATH/wallust/wallust-hyprland.conf"

              # Create Battery.sh script for hyprlock
              mkdir -p "$TARGET_PATH/scripts"
              cat > "$TARGET_PATH/scripts/Battery.sh" << 'BATTERY_EOF'
              #!/usr/bin/env bash
              # Battery status script for hyprlock

              if command -v acpi &> /dev/null; then
                  acpi -b | grep -P -o '[0-9]+(?=%)'
              elif [ -f /sys/class/power_supply/BAT0/capacity ]; then
                  cat /sys/class/power_supply/BAT0/capacity
              elif [ -f /sys/class/power_supply/BAT1/capacity ]; then
                  cat /sys/class/power_supply/BAT1/capacity
              else
                  echo "N/A"
              fi
              BATTERY_EOF

              # Make all scripts executable
              find "$TARGET_PATH/scripts" "$TARGET_PATH/UserScripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
              if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
                echo "Reloading Hyprland..."
                ${config.programs.hyprland.package}/bin/hyprctl reload >/dev/null 2>&1 || true
              fi
            '';
          };
          ".config/pypr" = {
            kind = "dir";
            mode = "copy";
            source = ./assets/pypr/.;
          };
        };

        # Profile artifacts for dual-theme runtime switching
        jvf.theme.profileArtifacts.dark.hypr = darkHyprArtifact;
        jvf.theme.profileArtifacts.light.hypr = lightHyprArtifact;

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
}
