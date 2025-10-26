{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.jvf.programs.ghostty;

  defaultConfig = {
    gtk-titlebar = false;
    gtk-single-instance = true;
    window-decoration = "auto";
    window-padding-balance = true;
    macos-titlebar-style = "transparent";
    font-family = "JetBrainsMonoNL Nerd Font";
    font-style = "Regular";
    font-size = 14;
    cursor-style = "block_hollow";
    cursor-style-blink = true;
    cursor-invert-fg-bg = true;
    mouse-hide-while-typing = true;
    custom-shader-animation = true;
    confirm-close-surface = false;
    theme = "zenbones-zenwritten-dark";
    shell-integration = "zsh";
    command = "/bin/zsh ~/.config/tmux/scripts/sessions.sh";
  };

  toConfigFormat =
    settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        if builtins.isBool value then if value then key else "" else "${key} = ${builtins.toString value}"
      ) settings
    );
in
{
  options.jvf.programs.ghostty = {
    enable = lib.mkEnableOption "ghostty, a fast terminal emulator";
    package = lib.mkPackageOption pkgs "ghostty" { };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig;
      description = lib.mdDoc "Configuration for ghostty, written to config.";
      example = {
        font-size = 12;
        theme = "tokyonight_night";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      configFile = pkgs.writeTextFile {
        name = "ghostty-config";
        text = toConfigFormat cfg.settings;
      };

      ghostty-wrapped = pkgs.writeShellApplication {
        name = "ghostty";
        runtimeInputs = [ cfg.package ];
        text = ''
          exec ${lib.getExe cfg.package} --config "${configFile}" "$@"
        '';
      };
    in
    {
      environment.systemPackages = [ ghostty-wrapped ];
    }
  );
}
