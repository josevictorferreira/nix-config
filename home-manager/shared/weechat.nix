{ pkgs, lib, config, configRoot, ... }:

with lib;
let
  cfg = config.modules.weechat;
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

    meta = with lib; {
      description = "Vi-like key bindings for WeeChat";
      homepage = "https://github.com/GermainZ/weechat-vimode";
      licence = licenses.gpl3;
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

    meta = with lib; {
      description = "Emoji support for WeeChat";
      homepage = "https://github.com/weechat/scripts";
      license = licenses.mit;
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
in
{
  options.modules.weechat = {
    enable = mkEnableOption "weechat";
    additionalScripts = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "List of weechat scripts to install.";
    };
  };
  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.aspell
        pkgs.aspellDicts.en
        pkgs.aspellDicts.pt_BR
        (pkgs.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins; [
              lua
              perl
              (python.withPackages (p: with p; [ websocket-client ]))
            ];
            scripts = cfg.additionalScripts ++ defaultScripts;

            init = ''
              /exec -sh -oc cat weechatrc
            '';
          };
        })
      ];
      file."${configRoot}/config/weechat/weechatrc" = {
        source = "${configRoot}/config/weechat/weechatrc";
        recursive = true;
        executable = false;
      };
    };
  };
}
