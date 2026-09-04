# Aspect: programs-ghostty
# Defines jvf.programs.ghostty options and platform-specific ghostty terminal config.
# NixOS: ghostty package via wrappers + config via jvf.home.
# Darwin: ghostty-bin package via wrappers + config via jvf.home (pkgs.ghostty is Linux-only).
# Note: ghostty-bin is the official binary distribution (mirrors the upstream DMG).
_:
let
  mkGhosttyOptions =
    { config
    , lib
    , pkgs
    , ...
    }:
    {
      options.jvf.programs.ghostty = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the configuration";
        };

        # ghostty-bin (Darwin DMG mirror) is darwin-only; the source-built
        # `ghostty` supports Linux. Pick per platform so the NixOS user-env
        # doesn't try to evaluate the unsupported binary distribution.
        package = lib.mkOption {
          type = lib.types.package;
          default = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
          defaultText = lib.literalExpression "if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty";
          description = "The ghostty package to use.";
        };

        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = lib.mdDoc "Configuration for ghostty, written to config.";
          example = {
            font-size = 12;
            window-padding-x = 4;
          };
        };
      };
    };

  # Ghostty's config format is `key = value` with one key per line.
  # Unlike kitty, ghostty uses '=' separator and supports strings without quoting
  # for simple values (numbers, identifiers). Booleans serialize as true/false.
  toConfigFormat =
    lib: settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (
          key: value:
          if builtins.isBool value then
            "${key} = ${if value then "true" else "false"}"
          else
            "${key} = ${toString value}"
        )
        settings
    );

  ghosttyModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.ghostty;

      defaultSettings = {
        font-family = "JetBrainsMonoNL Nerd Font";
        font-size = 11;
        font-style = "Regular";
        font-feature = "calt off";
        background = "#1a1b26";
        foreground = "#c0caf5";
        cursor-color = "#c0caf5";
        cursor-style = "block_hollow";
        cursor-style-blink = true;
        # String to avoid Nix's toString float repr ("0.700000"); ghostty parses both.
        cursor-opacity = "0.7";
        mouse-hide-while-typing = true;
        window-decoration = "auto";
        window-padding-balance = true;
        window-padding-x = 2;
        window-padding-y = 2;
        macos-titlebar-style = "transparent";
        macos-option-as-alt = true;
        confirm-close-surface = false;
        gtk-single-instance = true;
        gtk-titlebar = false;
        custom-shader-animation = true;
        shell-integration = "zsh";
      };

      # Map theme palette colors to ghostty's `palette = N=#hex` syntax.
      # Ghostty takes 16 colors in palette=index=hex lines.
      colorIndices = lib.genList lib.id 16;

      # Pre-render palette lines as "palette = N=#hex" because ghostty's
      # config schema uses key=`palette` and value=`N=#hex` (one line per index).
      paletteLines = lib.concatStringsSep "\n" (
        map
          (
            i:
            "palette = ${toString i}=#${lib.getAttr "color${toString i}" config.jvf.theme.colors}"
          )
          colorIndices
      );

      themeOverrides = {
        font-family = config.jvf.theme.fonts.monospace;
        font-size = config.jvf.theme.fonts.size;
        background = "#${config.jvf.theme.colors.background}";
        foreground = "#${config.jvf.theme.colors.foreground}";
        cursor-color = "#${config.jvf.theme.colors.cursor}";
      };
    in
    {
      imports = [ mkGhosttyOptions ];

      config = {
        jvf.programs.ghostty.settings = lib.mkDefault (defaultSettings // themeOverrides);

        jvf.wrappers.users.${cfg.username}.programs.ghostty = {
          packages = [
            cfg.package
          ];
        };

        jvf.home.users.${cfg.username}.items.".config/ghostty/config" = {
          kind = "file";
          mode = "copy";
          text = toConfigFormat lib cfg.settings + "\n" + paletteLines;
        };
      };
    };
in
{
  flake.modules.nixos.programs-ghostty = ghosttyModule;
  flake.modules.darwin.programs-ghostty = ghosttyModule;
}
