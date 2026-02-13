{ lib
, pkgs
, config
, username
, ...
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
  weechatInit = import ./init.nix {
    inherit lib pkgs cfg;
    settings = cfg.settings;
    secretPaths = weechatSecrets.paths;
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
