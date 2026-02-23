# Aspect: programs-kitty
# Defines jvf.programs.kitty options and platform-specific kitty terminal config.
# NixOS: kitty package + config via wrappers + nerd-fonts.
# Darwin: kitty package + config via wrappers + nerd-fonts.
{ ... }:
let
  mkKittyOptions =
    { config, lib, pkgs, ... }:
    let
      defaultSettings = {
        font_family = "JetBrainsMonoNL Nerd Font SemiBold";
        bold_font = "JetBrainsMonoNL Nerd Font Bold";
        italic_font = "JetBrainsMonoNL Nerd Font Italic";
        bold_italic_font = "JetBrainsMonoNL Nerd Font Bold Italic";
        font_size = 14;
        disable_ligatures = "never";
        window_border_width = "0.0pt";
        window_margin_width = 0;
        draw_minimal_borders = true;
        window_padding_width = 0;
        single_window_margin_width = -1;
        confirm_os_window_close = 0;
        placement_strategy = "top-left";
        repaint_delay = 2;
        input_delay = 0;
        sync_to_monitor = false;
        wayland_enable_ime = false;
        term = "xterm-256color";
        background_opacity = "0.95";
      };
    in
    {
      options.jvf.programs.kitty = {
        enable = lib.mkEnableOption "kitty, a GPU-accelerated terminal emulator";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        package = lib.mkPackageOption pkgs "kitty" { };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = defaultSettings;
          description = lib.mdDoc "Configuration for kitty, written to kitty.conf.";
          example = {
            font_size = 12;
            background_opacity = "0.9";
          };
        };
      };
    };

  toConfigFormat =
    lib: settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (
          key: value:
          if builtins.isBool value then
            "${key} ${if value then "yes" else "no"}"
          else
            "${key} ${builtins.toString value}"
        )
        settings
    );

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.kitty;
    in
    {
      imports = [ mkKittyOptions ];

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.kitty = {
          packages = [
            cfg.package
          ];
          configs = {
            "kitty.conf" = toConfigFormat lib cfg.settings;
          };
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
in
{
  flake.modules.nixos.programs-kitty = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-kitty = mkConfig { isDarwin = true; };
}
