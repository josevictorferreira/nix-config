# Aspect: desktop-hyprland-hypr (NixOS only)
# Hyprland compositor configuration with hypridle, hyprlock, pyprland.
# Configures jvf.wrappers.users for config file management.
{ ... }:
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

  hyprConfigDir = ./assets/hypr;
in
{
  flake.modules.nixos.desktop-hyprland-hypr =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.hypr;
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
          configs = {
            "hypr" = hyprConfigDir;
          };
          postInstall = ''
            # Create Battery.sh script for hyprlock
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
            find "$TARGET_PATH/scripts" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            echo "Reloading Hyprland..."
            ${config.programs.hyprland.package}/bin/hyprctl reload || true
          '';
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
}
