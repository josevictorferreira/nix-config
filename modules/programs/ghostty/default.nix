# Aspect: programs-ghostty
# Defines jvf.programs.ghostty options and platform-specific ghostty config.
# NixOS: installs ghostty package + nerd-fonts + config via jvf.wrappers.
# Darwin: config via jvf.wrappers only (ghostty installed via App Store).
_:
let
  mkGhosttyOptions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
        package = lib.mkPackageOption pkgs "ghostty" { };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
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

        exec ${lib.getExe pkgs.tmuxp} load -y main
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

        command = tmuxpInitScript;
      };

      themeOverrides = {
        background = "#${config.jvf.theme.colors.background}";
        foreground = "#${config.jvf.theme.colors.foreground}";
        cursor-color = "#${config.jvf.theme.colors.cursor}";
        font-family = config.jvf.theme.fonts.monospace;
        font-size = config.jvf.theme.fonts.size;
      };

      baseSettings = lib.removeAttrs defaultSettings [ "theme" ];

      paletteIndices = lib.genList lib.id 16;

      paletteLines = lib.concatStringsSep "\n" (
        map (
          i: "palette = ${toString i}=#${lib.getAttr "color${toString i}" config.jvf.theme.colors}"
        ) paletteIndices
      );
    in
    {
      imports = [ mkGhosttyOptions ];

      config = {
        jvf.programs.ghostty.settings = lib.mkDefault (baseSettings // themeOverrides);

        jvf.wrappers.users.${cfg.username}.programs.ghostty = {
          packages = lib.optional (!isDarwin) cfg.package;
          configs = {
            "config" = toConfigFormat cfg.settings + "\n" + paletteLines;
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
