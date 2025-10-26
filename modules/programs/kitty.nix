{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.jvf.programs.kitty;

  defaultConfig = {
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
    term = "tmux-256color";
    background_opacity = "0.95";
  };

  toConfigFormat =
    settings:
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
in
{
  options.jvf.programs.kitty = {
    enable = lib.mkEnableOption "kitty, a GPU-accelerated terminal emulator";
    package = lib.mkPackageOption pkgs "kitty" { };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig;
      description = lib.mdDoc "Configuration for kitty, written to kitty.conf.";
      example = {
        font_size = 12;
        background_opacity = "0.9";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      configFile = pkgs.writeTextFile {
        name = "kitty.conf";
        text = toConfigFormat cfg.settings;
      };

      kitty-wrapped = pkgs.writeShellApplication {
        name = "kitty";
        runtimeInputs = [ cfg.package ];
        text = ''
          exec ${lib.getExe cfg.package} --config "${configFile}" "$@"
        '';
      };
    in
    {
      environment.systemPackages = [ kitty-wrapped ];
    }
  );
}
