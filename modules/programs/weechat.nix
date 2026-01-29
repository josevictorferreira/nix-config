{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.weechat;
  secretPath = "/run/secrets/slack_api_token";

  weechatSettings = {
    "plugins.var.python.vimode.no_warn" = "on";
    "plugins.var.python.vimode.search_vim" = "on";
    "plugins.var.python.slack.autoconnect" = "off";
    "weechat.bar.buflist.type" = "root";
    "weechat.bar.buflist.position" = "left";
    "weechat.bar.buflist.size_max" = "12";
    "weechat.look.buffer_time_format" = "%H:%M";
    "weechat.look.prefix_align" = "none";
    "weechat.look.prefix_align_max" = "0";
    "weechat.look.prefix_same_nick" = "off";
    "weechat.color.chat_time" = "darkgray";
    "weechat.look.save_config_on_exit" = "off";
    "plugins.var.python.slack.slack_api_token" = "\${sec.data.slack_token}";
  };

  weechatInit = ''
    /exec -oc -sh echo "/secure set slack_token $(cat ${secretPath}); /slack connect"
    /bar hide nicklist

    /vimode bind_keys

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (key: val: "/set ${key} \"${val}\"") weechatSettings
    )}
  '';

  weechatCommands = lib.concatStringsSep ";" (
    lib.mapAttrsToList (key: val: "/set ${key} \"${val}\"") weechatSettings
  );

  viModeScript = pkgs.stdenv.mkDerivation {
    pname = "vimode";
    version = "0.8";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/GermainZ/weechat-vimode/0ca9a67017302b32c38a6c9e3ffcd5b81f2aea36/vimode.py";
      sha256 = "sha256-YRFIcvTJcGjmcPWOPkTz3DB40fudVcZ1MiT36qi/hyI=";
    };

    dontUnpack = true;
    prePatch = ''
      cp $src vimode.py
    '';

    passthru.scripts = [ "vimode.py" ];

    installPhase = ''
      runHook preInstall

      install -D vimode.py $out/share/vimode.py

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/GermainZ/weechat-vimode";
      description = "vi/vim-like modes and keybindings";
      license = lib.licenses.gpl3Plus;
    };
  };

  weechatPkg = pkgs.weechat.override {
    configure =
      { availablePlugins, ... }:
      {
        scripts = cfg.additionalScripts;
        plugins = [
          availablePlugins.python
          availablePlugins.perl
          availablePlugins.lua
          availablePlugins.ruby
        ];
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
    additionalScripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.weechatScripts.highmon
        pkgs.weechatScripts.colorize_nicks
        pkgs.weechatScripts.wee-slack
        pkgs.weechatScripts.url_hint
        pkgs.weechatScripts.multiline
        pkgs.weechatScripts.weechat-notify-send
        viModeScript
      ];
      description = "List of weechat scripts to install in addition to the default set.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.slack_api_token = {
      path = "/run/secrets/slack_api_token";
      owner = cfg.username;
      mode = "0400";
    };

    jvf.wrappers.users.${cfg.username}.programs.weechat = {
      packages = [
        cfg.package
        pkgs.aspell
        pkgs.aspellDicts.en
        pkgs.aspellDicts.pt_BR
        pkgs.python3
      ]
      ++ cfg.additionalScripts;
      command = "${lib.getExe cfg.package} -r '${weechatCommands}'";
    };
  };
}
