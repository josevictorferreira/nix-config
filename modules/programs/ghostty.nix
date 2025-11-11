{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.ghostty;

  toConfigFormat =
    settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        if builtins.isBool value then
          "${key} = ${builtins.toJSON value}"
        else
          "${key} = ${builtins.toString value}"
      ) settings
    );

  tmuxpInitScript = pkgs.writeShellScript "tmuxp-init-wrapper" ''
    if command -v tmuxp >/dev/null 2>&1; then
      exec tmuxp load -y monitoring chat work projects main
    else
      exec tmux
    fi
  '';

  defaultConfig = {
    gtk-titlebar = false;
    gtk-single-instance = true;
    window-decoration = "auto";
    window-padding-balance = true;
    macos-titlebar-style = "transparent";
    font-family = "JetBrainsMonoNL Nerd Font";
    font-style = "Regular";
    font-size = 15;
    cursor-style = "block_hollow";
    cursor-style-blink = true;
    mouse-hide-while-typing = true;
    custom-shader-animation = true;
    confirm-close-surface = false;
    shell-integration = "zsh";
    theme = "Atom One Dark";
    command = tmuxpInitScript;
  };
in
{
  options.jvf.programs.ghostty = {
    enable = lib.mkEnableOption "ghostty, a fast terminal emulator";
    package = lib.mkPackageOption pkgs "ghostty" { };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultConfig;
      description = lib.mdDoc "Configuration for ghostty, passed as command-line arguments via --args.";
      example = {
        font-size = 12;
        theme = "tokyonight_night";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.ghostty = {
      packages = [
        cfg.package
      ];
      configs = {
        "config" = toConfigFormat cfg.settings;
      };
    };
  };
}
