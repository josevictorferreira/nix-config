{ pkgs, lib, config, ... }:

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
              /set weechat.bar.input.items "[mode_indicator]+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]"
              /set weechat.bar.vi_line_numbers.hidden off
              /set weechat.look.mouse on
              /set weechat.look.prefix_same_nick "⤷"
              /set weechat.look.color_nick_offline yes
              /set weechat.look.align_end_of_lines message
              /set weechat.look.align_multiline_words on

              /set weechat.bar.nicklist.conditions "$${info:term_width} > 100"
              /set weechat.bar.nicklist.size_max 30

              /set weechat.bar.title.color_fg black
              /set weechat.bar.title.color_bg 31
              /set weechat.bar.nicklist.color_fg 229
              /set weechat.bar.nicklist.separator on
              /set weechat.bar.nicklist.size_max 20
              /set weechat.bar.nicklist.size 16

              /set spell.enable "true"
              /set spell.check.default_dict "en,pt_BR"
              /set spell.option.ignore-case "true"

              /set plugins.var.python.slack.files_download_location "~/Downloads/weeslack"
              /set plugins.var.python.slack.auto_open_threads true
              /set plugins.var.python.slack.never_away true
              /set plugins.var.python.slack.render_emoji_as_string false
              /set plugins.var.python.slack.show_buflist_presense true
              /set plugins.var.python.slack.show_emoji true
              /set plugins.var.python.slack.show_emoji_reactions true
              /set plugins.var.python.slack.show_emoji_reactions_in_threads true
              /set plugins.var.python.vimode.search_vim on

              /alias add open /url_hint_replace /exec -bg xdg-open  {url$1}

              /key bind ctrl-G /go
              /key bind ctrl-F /open
              
              /autojoin
            '';
          };
        })
      ];
    };
  };
}
