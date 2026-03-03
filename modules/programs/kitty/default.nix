# Aspect: programs-kitty
# Defines jvf.programs.kitty options and platform-specific kitty terminal config.
# NixOS: kitty package + config via wrappers + nerd-fonts.
# Darwin: kitty package + config via wrappers + nerd-fonts.
_:
let
  mkKittyOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.jvf.programs.kitty = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        package = lib.mkPackageOption pkgs "kitty" { };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
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
      lib.mapAttrsToList (
        key: value:
        if builtins.isBool value then
          "${key} ${if value then "yes" else "no"}"
        else
          "${key} ${builtins.toString value}"
      ) settings
    );

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.kitty;

      defaultSettings = {
        bold_font = "JetBrainsMonoNL Nerd Font Bold";
        italic_font = "JetBrainsMonoNL Nerd Font Italic";
        bold_italic_font = "JetBrainsMonoNL Nerd Font Bold Italic";
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

      colorIndices = lib.genList lib.id 16;

      themeOverrides = {
        font_family = config.jvf.theme.fonts.monospace;
        font_size = config.jvf.theme.fonts.size;
        background = "#${config.jvf.theme.colors.background}";
        foreground = "#${config.jvf.theme.colors.foreground}";
        cursor = "#${config.jvf.theme.colors.cursor}";
      }
      // lib.listToAttrs (
        map (
          i:
          lib.nameValuePair "color${toString i}" "#${lib.getAttr "color${toString i}" config.jvf.theme.colors}"
        ) colorIndices
      );
    in
    {
      imports = [ mkKittyOptions ];

      config = {
        jvf.programs.kitty.settings = lib.mkDefault (defaultSettings // themeOverrides);

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
