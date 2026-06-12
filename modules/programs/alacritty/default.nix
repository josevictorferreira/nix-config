# Aspect: programs-alacritty
# Defines jvf.programs.alacritty options and platform-specific alacritty terminal config.
# NixOS: alacritty package + config via jvf.home + IBM Plex Mono + nerd-fonts.
# Darwin: alacritty package + config via jvf.home + IBM Plex Mono + nerd-fonts.
_:
let
  mkAlacrittyOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
          default = { };
          description = lib.mdDoc "Configuration for alacritty, written to alacritty.toml.";
          example = {
            font.size = 12;
            window.opacity = 0.9;
          };
        };
      };
    };

  alacrittyModule =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.jvf.programs.alacritty;
      colors = config.jvf.theme.colors;
      fonts = config.jvf.theme.fonts;
      fontFamily = "JetBrainsMonoNL Nerd Font";
      tomlFormat = pkgs.formats.toml { };
      themeColors = {
        primary = {
          background = "0x${colors.background}";
          foreground = "0x${colors.foreground}";
        };
        cursor = {
          text = "0x${colors.background}";
          cursor = "0x${colors.cursor}";
        };
        normal = {
          black = "0x${colors.color0}";
          red = "0x${colors.color1}";
          green = "0x${colors.color2}";
          yellow = "0x${colors.color3}";
          blue = "0x${colors.color4}";
          magenta = "0x${colors.color5}";
          cyan = "0x${colors.color6}";
          white = "0x${colors.color7}";
        };
        bright = {
          black = "0x${colors.color8}";
          red = "0x${colors.color9}";
          green = "0x${colors.color10}";
          yellow = "0x${colors.color11}";
          blue = "0x${colors.color12}";
          magenta = "0x${colors.color13}";
          cyan = "0x${colors.color14}";
          white = "0x${colors.color15}";
        };
      };
    in
    {
      imports = [ mkAlacrittyOptions ];

      config = {
        jvf.programs.alacritty.settings = lib.mkDefault {
          colors = themeColors;
          env = {
            TERM = "tmux-256color";
          };
          font = {
            size = fonts.size;
            normal = {
              family = fontFamily;
              style = "Medium";
              # style = "Regular";
            };
            bold = {
              family = fontFamily;
              style = "Bold";
            };
            italic = {
              family = fontFamily;
              style = "Medium";
              # style = "Italic";
            };
            bold_italic = {
              family = fontFamily;
              style = "Medium";
              # style = "Bold Italic";
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

        users.users.${cfg.username}.packages = [ cfg.package ];

        jvf.home.users.${cfg.username}.items.".config/alacritty/alacritty.toml" = {
          kind = "file";
          mode = "copy";
          text = builtins.readFile ((pkgs.formats.toml { }).generate "alacritty.toml" cfg.settings);
        };
        fonts.packages = [
          pkgs.ibm-plex
          pkgs.nerd-fonts.zed-mono
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.nerd-fonts.inconsolata
          pkgs.tamzen
        ];
      };
    };
in
{
  flake.modules.nixos.programs-alacritty = alacrittyModule;
  flake.modules.darwin.programs-alacritty = alacrittyModule;
}
