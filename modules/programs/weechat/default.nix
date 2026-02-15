{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.weechat;

  defaultSettings = import ./settings.nix;
  defaultPlugins = import ./plugins.nix {
    inherit lib pkgs;
  };
  weechatSecrets = import ./secrets.nix {
    inherit lib cfg;
  };

  # Hierarchical buflist filters (default: show only parent buffers)
  # Level 1: Parent buffers only (#Discord, #WhatsApp, slack.team)
  # Level 2+: Hidden by default (categories, channels, contacts)
  # Toggle in weechat: /filter toggle <filter_name>
  buflistFilterCommands = [
    # Discord: hide nested (categories and channels), keep only #Discord parent
    ''/filter add buflist_hide_discord_nested * * ^#Discord\..*''
    # WhatsApp: hide contacts, keep only bridge parent
    ''/filter add buflist_hide_whatsapp_nested * * ^#WhatsApp.*\..*''
    # Slack: hide channels, keep only team
    ''/filter add buflist_hide_slack_channels * * ^slack\.[^.]+\..*''
  ];

  allFilterCommands = cfg.autohideFilterCommands ++ buflistFilterCommands;

  weechatInit = import ./init.nix {
    inherit lib pkgs cfg;
    settings = cfg.settings;
    secretPaths = weechatSecrets.paths;
    filterCommands = allFilterCommands;
  };

  weechatPkg = pkgs.weechat.override {
    configure =
      { availablePlugins, ... }:
      {
        scripts = cfg.plugins.scripts;
        plugins =
          (map (pluginName: availablePlugins.${pluginName}) cfg.plugins.native)
          ++ lib.optionals cfg.matrix.enable [ defaultPlugins.matrix ];
        init = weechatInit;
      };
  };
in
{
  options.jvf.programs.weechat = {
    enable = lib.mkEnableOption "weechat, an extensible chat client";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install configuration";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = weechatPkg;
      description = "The weechat package to be used";
    };

    plugins = {
      native = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = defaultPlugins.native;
        description = "Native Weechat plugin names enabled in the wrapped package.";
      };

      scripts = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = defaultPlugins.scripts;
        description = "Script packages installed for Weechat.";
      };
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultSettings;
      description = "Settings written via /set during Weechat init.";
    };

    autohideFilterCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/filter add weechat_matrix_discord_categories matrix * * (?i)(^|[[:space:][:punct:]])(category|categories|space|spaces)($|[[:space:][:punct:]])"
      ];
      description = "Filter commands executed at startup to auto-hide category/meta buffers.";
    };

    matrix = {
      enable = lib.mkEnableOption "Matrix protocol support via weechat-matrix-rs";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = weechatSecrets.sops;

    jvf.wrappers.users.${cfg.username}.programs.weechat = {
      packages = [
        cfg.package
        pkgs.aspell
        pkgs.aspellDicts.en
        pkgs.aspellDicts.pt_BR
        pkgs.python3
      ]
      ++ cfg.plugins.scripts;
      command = "${lib.getExe cfg.package}";
    };
  };
}
