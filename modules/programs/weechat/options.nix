# options.nix - Weechat option definitions
{ config, lib, ... }:
{
  options.jvf.programs.weechat = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install configuration";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The weechat package to be used (auto-generated if null)";
    };

    plugins = {
      native = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "python"
          "perl"
          "lua"
          "ruby"
        ];
        description = "Native Weechat plugin names enabled in the wrapped package.";
      };

      scripts = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Script packages installed for Weechat.";
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Settings written via /set during Weechat init.";
    };

    extraCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra Weechat commands executed at startup.";
    };

    extraInitCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional init commands from submodules (e.g., matrix setup).";
    };

    prependInitCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Run before all other init lines (e.g. /python load with store path).";
    };

    autohideFilterCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/filter add weechat_matrix_discord_categories matrix * * (?i)(^|[[:space:][:punct:]])(category|categories|space|spaces)($|[[:space:][:punct:]])"
      ];
      description = "Filter commands executed at startup to auto-hide category/meta buffers.";
    };

    initScript = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Generated weechat initialization script.";
    };

    matrixPlugin = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The weechat-matrix-rs plugin package (set by matrix.nix when enabled)";
    };

    matrix = {
      enable = lib.mkEnableOption "Matrix protocol support via weechat-matrix-rs";
    };

    bufcat = {
      enable = lib.mkEnableOption "buflist categorization via bufcat script";
      configPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to bufcat.json. When null, BUFCAT_CONFIG_PATH is the bufcat derivation in the store (flake
          edits apply after rebuild). When set, that path is used (e.g. a writable file under $HOME).
        '';
      };
    };
  };
}
