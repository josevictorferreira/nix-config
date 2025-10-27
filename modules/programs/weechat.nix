{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.jvf.programs.weechat;

  weechat-vimode = pkgs.stdenv.mkDerivation {
    name = "weechat-vimode";
    version = "0.1.0";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/GermainZ/weechat-vimode/57bd66cf558abc12e5b32a08064e58d5eaf713ce/vimode.py";
      sha256 = "sha256-YRFIcvTJcGjmcPWOPkTz3DB40fudVcZ1MiT36qi/hyI=";
    };

    dontUnpack = true;

    passthru.scripts = [ "vimode.py" ];

    installPhase = ''
      install -D $src $out/share/vimode.py
    '';

    meta = {
      description = "Vi-like key bindings for WeeChat";
      homepage = "https://github.com/GermainZ/weechat-vimode";
      license = lib.licenses.gpl3;
    };
  };

  emoji-lua = pkgs.stdenv.mkDerivation {
    name = "emoji-lua";
    version = "0.1.0";

    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/weechat/scripts/61252092630e0fafa28a3df5b393a1e828c2c7bf/lua/emoji.lua";
      sha256 = "sha256-+oqiIMEALiWH04LIoHCtYpgu3+4qCyZhgaruDdutShw=";
    };

    dontUnpack = true;

    passthru.scripts = [ "emoji.lua" ];

    installPhase = ''
      install -D $src $out/share/emoji.lua
    '';

    meta = {
      description = "Emoji support for WeeChat";
      homepage = "https://github.com/weechat/scripts";
      license = lib.licenses.mit;
    };
  };

  defaultScripts = with pkgs.weechatScripts; [
    wee-slack
    weechat-autosort
    weechat-go
    weechat-notify-send
    url_hint
    edit
    multiline
    highmon
    colorize_nicks
    emoji-lua
    weechat-vimode
  ];

  allScripts = cfg.additionalScripts ++ defaultScripts;

  weechatConfigDir = lib.optionalString (cfg.configFile != null) (
    pkgs.runCommand "weechat-config" { } ''
      mkdir -p $out/etc/weechat
      cp ${cfg.configFile} $out/etc/weechat/weechatrc
      chmod 644 $out/etc/weechat/weechatrc
    ''
  );

  weechatWithConfig = pkgs.weechat.override {
    configure =
      { availablePlugins, ... }:
      {
        plugins = with availablePlugins; [
          lua
          perl
          (python.withPackages (pythonPackages: with pythonPackages; [ websocket-client ]))
        ];
        scripts = allScripts;

        init = lib.optionalString (cfg.configFile != null) ''
          /exec -sh -oc cat ${config.systemConfigDir}/etc/weechat/weechatrc
        '';
      };
  };
in
{
  options.jvf.programs.weechat = {
    enable = lib.mkEnableOption "weechat, an extensible chat client";
    package = lib.mkPackageOption pkgs "weechat" { };
    additionalScripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of weechat scripts to install in addition to the default set.";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to weechat configuration file. If provided, will be copied to /etc/weechat/weechatrc";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.aspellDicts.pt_BR
    ]
    ++ lib.optionals (cfg.configFile != null) [
      weechatConfigDir
    ]
    ++ [
      (weechatWithConfig.override { inherit (cfg) package; })
    ];

    environment.etc = lib.optionalAttrs (cfg.configFile != null) {
      "weechat/weechatrc".source = "${weechatConfigDir}/etc/weechat/weechatrc";
    };
  };
}
