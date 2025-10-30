{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.jvf.programs.ghostty;

  # Convert configuration settings to command-line arguments
  toArgsFormat =
    settings:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (
        key: value:
        let
          # Convert kebab-case to camelCase for CLI args
          argName = lib.replaceStrings [ "-" ] [ "" ] key;
          argValue =
            if builtins.isBool value then (if value then "true" else "false") else builtins.toString value;
        in
        "--${argName}=${argValue}"
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
      description = lib.mdDoc "Configuration for ghostty, passed as command-line arguments via --args.";
      example = {
        font-size = 12;
        theme = "tokyonight_night";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Generate command-line arguments from configuration
      ghosttyArgs = toArgsFormat cfg.settings;

      ghosttyWrapped = pkgs.writeShellApplication {
        name = "ghostty";
        runtimeInputs = [ cfg.package ];
        text = ''
          exec ${lib.getExe cfg.package} --args ${ghosttyArgs} "$@"
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
