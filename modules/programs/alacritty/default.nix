# Aspect: programs-alacritty
# Defines jvf.programs.alacritty options and platform-specific alacritty terminal config.
# NixOS: alacritty package + config via wrappers + IBM Plex Mono + nerd-fonts.
# Darwin: alacritty package + config via wrappers + IBM Plex Mono + nerd-fonts.
{ ... }:
let
  mkAlacrittyOptions =
    { config, lib, pkgs, ... }:
    let
      fontFamily = "IBM Plex Mono";

      defaultConfig = {
        colors = {
          primary = {
            background = "#1f1f28";
            foreground = "#dcd7ba";
          };
          normal = {
            black = "#090618";
            red = "#c34043";
            green = "#76946a";
            yellow = "#c0a36e";
            blue = "#7e9cd8";
            magenta = "#957fb8";
            cyan = "#6a9589";
            white = "#c8c093";
          };
          bright = {
            black = "#727169";
            red = "#e82424";
            green = "#98bb6c";
            yellow = "#e6c384";
            blue = "#7fb4ca";
            magenta = "#938aa9";
            cyan = "#7aa89f";
            white = "#dcd7ba";
          };
          selection = {
            background = "#2d4f67";
            foreground = "#c8c093";
          };
        };
        env = {
          TERM = "tmux-256color";
        };
        font = {
          size = 11.0;
          normal = {
            family = fontFamily;
            style = "Regular";
          };
          bold = {
            family = fontFamily;
            style = "SemiBold";
          };
          italic = {
            family = fontFamily;
            style = "Italic";
          };
          bold_italic = {
            family = fontFamily;
            style = "Bold Italic";
          };
        };
        scrolling = {
          history = 100000;
          multiplier = 3;
        };
        window = {
          dynamic_title = true;
          opacity = 1;
          padding = {
            x = 0;
            y = 0;
          };
        };
        cursor = {
          blink_interval = 500;
          style = {
            shape = "Block";
            blinking = "Always";
          };
        };
      };
    in
    {
      options.jvf.programs.alacritty = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure alacritty";
        };

        package = lib.mkPackageOption pkgs "alacritty" { };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = defaultConfig;
          description = lib.mdDoc "Configuration for alacritty, written to alacritty.toml.";
          example = {
            font.size = 12;
            window.opacity = 0.9;
          };
        };
      };
    };

  alacrittyModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.alacritty;
    in
    {
      imports = [ mkAlacrittyOptions ];

      config = {
        jvf.wrappers.users.${cfg.username}.programs.alacritty = {
          packages = [
            cfg.package
          ];
          configs = {
            "alacritty.toml" = cfg.settings;
          };
        };

        fonts.packages = [
          pkgs.ibm-plex
          pkgs.nerd-fonts.zed-mono
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
in
{
  flake.modules.nixos.programs-alacritty = alacrittyModule;
  flake.modules.darwin.programs-alacritty = alacrittyModule;
}
