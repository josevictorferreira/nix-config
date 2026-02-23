# Aspect: desktop-hyprland-swaync (NixOS only)
# Swaync notification daemon with Hyprland integration.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-swaync =
    { lib
    , config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.swaync;
    in
    {
      options.jvf.desktop.hyprland.swaync = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure swaync wrapper";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.swaync = {
          packages = [ pkgs.swaynotificationcenter ];
          configs = {
            "swaync/config.json" = builtins.readFile ./assets/swaync/config.json;
            "swaync/style.css" = builtins.readFile ./assets/swaync/style.css;
            "swaync/scripts/on-low-notification.sh" = pkgs.writeText "on-low-notification.sh" ''
              #!/usr/bin/env bash
              # Play sound for low urgency notifications
              ${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga 2>/dev/null || true
            '';
            "swaync/scripts/on-normal-notification.sh" = pkgs.writeText "on-normal-notification.sh" ''
              #!/usr/bin/env bash
              # Play sound for normal urgency notifications
              ${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message.oga 2>/dev/null || true
            '';
            "swaync/scripts/on-critical-notification.sh" = pkgs.writeText "on-critical-notification.sh" ''
              #!/usr/bin/env bash
              # Play sound for critical urgency notifications
              ${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga 2>/dev/null || true
            '';
          };
          postInstall = ''
            # Make notification scripts executable
            chmod +x "$TARGET_PATH/scripts/on-low-notification.sh" 2>/dev/null || true
            chmod +x "$TARGET_PATH/scripts/on-normal-notification.sh" 2>/dev/null || true
            chmod +x "$TARGET_PATH/scripts/on-critical-notification.sh" 2>/dev/null || true
          '';
        };
      };
    };
}
