{
  lib,
  pkgs,
  config,
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
    mouse-hide-while-typing = true;
    custom-shader-animation = true;
    confirm-close-surface = false;
    shell-integration = "zsh";
    theme = "Zenbones Dark";
  };
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
      configDir = pkgs.writeTextDir "ghostty/config" (toConfigFormat cfg.settings);

      ghosttyWrapped = pkgs.writeShellApplication {
        name = "ghostty";
        runtimeInputs = [ cfg.package ];
        text = ''
          XDG_CONFIG_HOME='${configDir}' exec ${lib.getExe cfg.package} "$@"
        '';
      };

      ghosttyDesktop = pkgs.makeDesktopItem {
        name = "ghostty";
        desktopName = "Ghostty";
        comment = "A fast, feature-rich terminal emulator";
        exec = lib.getExe ghosttyWrapped;
        terminal = false;
        type = "Application";
        categories = [
          "System"
          "Utility"
          "TerminalEmulator"
        ];
        icon = "ghostty";
      };

      ghosttyIcon = pkgs.runCommand "ghostty-icon" { } ''
        mkdir -p $out/share/icons/hicolor/512x512/apps
        mkdir -p $out/share/icons
      '';
    in
    {
      environment.systemPackages = [
        ghosttyWrapped
        ghosttyDesktop
        ghosttyIcon
      ];
      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];
    }
  );
}
