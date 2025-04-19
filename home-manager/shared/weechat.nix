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
        };
      })
    ];
  };
  config = mkIf cfg.enable {
    programs.weechat = {
      enable = true;
      config.weechat = {
        look = {
          mouse = true;
          prefix_same_nick = "⤷";
          color_nick_offline = true;
          align_end_of_lines = "time";
          align_multiline_words = true;
        };
        bar = {
          input = {
            items = "[mode_indicator]+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]";
          };
          vi_line_numbers = {
            hidden = false;
          };
          nicklist = {
            conditions = "$${info:term_width} > 100";
            size_max = 20;
            color_fg = 229;
            separator = true;
            size = 16;
          };
          title = {
            color_fg = "black";
            color_bg = 31;
          };
        };
      };

      config.spell = {
        enable = "true";
        check = {
          default_dict = "en,pt_BR";
        };
        option = {
          "ignore-case" = "true";
        };
      };

      config.aspell = {
        check = {
          default_dict = "pt_BR";
          suggestions = 3;
        };
        color = {
          suggestions = "*green";
        };
        enable = true;
      };

      config.plugins.var.python = {
        slack = {
          files_download_location = "~/Downloads/weeslack";
          auto_open_threads = true;
          never_away = true;
          render_emoji_as_string = false;
          show_buflist_presense = true;
          show_emoji = true;
          show_emoji_reactions = true;
          show_emoji_reactions_in_threads = true;
        };
        vimode = {
          search_vim = true;
        };
      };

      alias.add = {
        open_url = "/url_hint_replace /exec -bg xdg-open  {url$1}";
      };

      bindings = {
        ctrl-g = "/go";
        ctrl-f = "/open_url";
      };

      init = [
        "/autojoin"
      ];
    };
  };
}
