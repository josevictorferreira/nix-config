{ pkgs, lib, config, configRoot, ... }:

with lib;
let
  cfg = config.modules.weechat;
  defaultScripts = with pkgs.weechatScripts; [
    wee-slack
    weechat-autosort
    weechat-go
    url_hint
    edit
    highmon
    colorize_nicks
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
        (pkgs.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins; [
              lua
              perl
              (python.withPackages (p: with p; [ websocket-client ]))
            ];
            scripts = cfg.additionalScripts ++ defaultScripts;
            init = ''
              /script install vimode.py
              /script install emoji.lua

              /set irc.look.server_buffer independent
              /set buflist.format.buffer ''${format_number}''${indent}''${cut:20,...,}''${format_nick_prefix}''${color_hotlist}''${format_name}

              /set weechat.look.eat_newline_glitch on
              /set weechat.look.prefix_align_more right

              /set plugins.var.python.urlserver.http_port "60211"
              /set plugins.var.python.slack.files_download_location "~/Downloads/weeslack"
              /set plugins.var.python.slack.auto_open_threads true
              /set plugins.var.python.slack.never_away true
              /set plugins.var.python.slack.render_emoji_as_string false
              /set plugins.var.python.slack.render_bold_as bold
              /set plugins.var.python.slack.render_italic_as italic

              /alias add open_url /url_hint_replace /exec -bg xdg-open {url$1}
              /key bind meta2-11~ /open_url 1
              /key bind meta2-12~ /open_url 2
              /key bind meta-! /buffer close
            '';
          };
        })
      ];
      file = {
        ".config/weechat" = {
          source = "${configRoot}/config/weechat";
          recursive = true;
          executable = false;
        };
      };
    };
  };
}
