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
    {
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.hypr;
      colors = config.jvf.theme.colors;

      # Theme adapter: generate hyprland color variables
      hyprlandColorsConf = pkgs.writeText "wallust-hyprland.conf" ''
        $background = rgb(${colors.background})
        $foreground = rgb(${colors.foreground})
        $color0 = rgb(${colors.color0})
        $color1 = rgb(${colors.color1})
        $color2 = rgb(${colors.color2})
        $color3 = rgb(${colors.color3})
        $color4 = rgb(${colors.color4})
        $color5 = rgb(${colors.color5})
        $color6 = rgb(${colors.color6})
        $color7 = rgb(${colors.color7})
        $color8 = rgb(${colors.color8})
        $color9 = rgb(${colors.color9})
        $color10 = rgb(${colors.color10})
        $color11 = rgb(${colors.color11})
        $color12 = rgb(${colors.color12})
        $color13 = rgb(${colors.color13})
        $color14 = rgb(${colors.color14})
        $color15 = rgb(${colors.color15})
        $placeholderFg = ##${colors.foreground}99
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
              cp ${hyprlandColorsConf} "$TARGET_PATH/wallust/wallust-hyprland.conf"

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
              echo "Reloading Hyprland..."
              ${config.programs.hyprland.package}/bin/hyprctl reload 2>/dev/null || true
            '';
          };
          ".config/pypr" = {
            kind = "dir";
            mode = "copy";
            source = ./assets/pypr/.;
          };
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
}
