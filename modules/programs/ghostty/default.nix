# Aspect: programs-ghostty
# Defines jvf.programs.ghostty options and platform-specific ghostty config.
# NixOS: installs ghostty package + nerd-fonts + config via jvf.wrappers.
# Darwin: config via jvf.wrappers only (ghostty installed via App Store).
{ ... }:
let
  mkGhosttyOptions =
    { lib, pkgs, ... }:
    let
      toConfigFormat =
        settings:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            key: value:
            if builtins.isBool value then "${key} = ${builtins.toJSON value}" else "${key} = ${toString value}"
          ) settings
        );
    in
    {
      options.jvf.programs.ghostty = {
        enable = lib.mkEnableOption "ghostty, a fast terminal emulator";
        package = lib.mkPackageOption pkgs "ghostty" { };

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to install the configuration.";
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Configuration for ghostty, passed as config key-value pairs.";
          example = {
            font-size = 12;
            theme = "tokyonight_night";
          };
        };
      };

      config._module.args.toConfigFormat = toConfigFormat;
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      toConfigFormat,
      ...
    }:
    let
      cfg = config.jvf.programs.ghostty;

      tmuxpDarwinPath = ''
        if [ -e /etc/profile ]; then source /etc/profile; fi

        # Explicitly add Nix paths to the front to survive tmux/zsh resets
        export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:$PATH"
      '';

      tmuxpInitScript = pkgs.writeShellScript "tmuxp-init" ''
        ${lib.optionalString isDarwin tmuxpDarwinPath}

        exec tmuxp load -y main
      '';

      defaultSettings = {
        gtk-titlebar = false;
        gtk-single-instance = true;
        window-decoration = "auto";
        window-padding-balance = true;
        macos-titlebar-style = "transparent";
        font-family = "JetBrainsMonoNL Nerd Font";
        font-style = "Regular";
        font-size = 11;
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
      imports = [ mkGhosttyOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs.ghostty.settings = lib.mkDefault defaultSettings;

        jvf.wrappers.users.${cfg.username}.programs.ghostty = {
          packages = lib.optional (!isDarwin) cfg.package;
          configs = {
            "config" = toConfigFormat cfg.settings;
          };
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
in
{
  flake.modules.nixos.programs-ghostty = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-ghostty = mkConfig { isDarwin = true; };
}
