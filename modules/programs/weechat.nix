{
  lib,
  pkgs,
  config,
  jvfLib,
  ...
}:
let
  cfg = config.jvf.programs.weechat;
  defaultPlugins = [
    pkgs.weechatScripts.colorize_nicks
    pkgs.weechatScripts.wee-slack
    pkgs.weechatScripts.url_hint
    pkgs.weechatScripts.multiline
    pkgs.weechatScripts.weechat-notify-send
  ];

  weechatConfig = {
    debug = { };
    startup = {
      command_after_plugins = "/autojoin";
      command_before_plugins = "";
      display_logo = "on";
      display_version = "on";
      sys_rlimit = "";
    };
    look = {
      align_end_of_lines = "prefix";
      align_multiline_words = "on";
      bar_more_down = "";
      bar_more_left = "…";
      bar_more_right = "…";
      bar_more_up = "";
      buffer_notify_default = "message";
      buffer_time_format = "\${color:239}%H\${color:239}:\${color:239}%M";
      color_inactive_message = "off";
      color_inactive_prefix = "off";
      color_inactive_prefix_buffer = "off";
      color_inactive_window = "off";
      color_nick_offline = "yes";
      hotlist_add_conditions = "\${away} || \${buffer.num_displayed} == 0";
      item_buffer_filter = "•";
      mouse = "on";
      nick_prefix = "";
      nick_suffix = "";
      prefix_align_max = 0;
      prefix_align_min = 0;
      prefix_buffer_align_max = 0;
      prefix_join = "→";
      prefix_quit = "←";
      prefix_same_nick = "⤷";
      prefix_suffix = " ";
      read_marker_string = "─";
      separator_horizontal = "";
    };
    palette = { };
    color = {
      bar_more = 183;
      chat_delimiters = 57;
      chat_highlight = "lightblue";
      chat_highlight_bg = "default";
      chat_host = 57;
      chat_nick = "default";
      chat_nick_colors = "cyan,lightcyan,blue,lightblue,magenta,lightmagenta,26,27,56,57,62,63,68,69,98,99,105,135,141,177,183";
      chat_nick_self = "lightmagenta";
      chat_prefix_join = 141;
      chat_prefix_more = "lightblue";
      chat_prefix_quit = 135;
      chat_prefix_suffix = "blue";
      chat_read_marker = 57;
      chat_text_found = "lightmagenta";
      chat_time = 239;
      eval_syntax_colors = "183,177,141,98";
      input_text_not_found = "magenta";
      separator = 57;
      status_data_highlight = 141;
      status_data_msg = 183;
      status_data_private = 141;
      status_more = "lightblue";
      status_name = "white";
      status_name_tls = 141;
      status_nicklist_count = "white";
      status_number = "white";
      status_time = "cyan";
    };
    completion = { };
    history = {
      max_buffer_lines_number = 1024;
    };
    proxy = { };
    network = { };
    plugin = { };
    signal = { };
    bar = {
      "input.color_bg" = "default";
      "input.color_delim" = "cyan";
      "input.color_fg" = "default";
      "input.conditions" = "";
      "input.filling_left_right" = "vertical";
      "input.filling_top_bottom" = "horizontal";
      "input.hidden" = "off";
      "input.items" =
        "[mode_indicator]+[input_prompt]+(away),[input_search],[input_paste],input_text,[vi_buffer]";
      "input.position" = "bottom";
      "input.priority" = 1000;
      "input.separator" = "off";
      "input.size" = 1;
      "input.size_max" = 0;
      "input.type" = "window";
      "nicklist.conditions" = "";
      "nicklist.hidden" = "on";
      "title.color_bg" = 56;
      "title.color_fg" = "white";
      "vi_line_numbers.hidden" = "off";
    };
    layout = { };
    notify = {
      "core.weechat" = 3;
      "irc.server.*" = 3;
    };
    filter = { };
    key = {
      ctrl-F = "/open";
      ctrl-G = "/go";
    };
    key_search = { };
    key_cursor = { };
    key_mouse = { };
  };

  pluginsConfig = {
    default = { };
    scripts = {
      description = "weechat-scripts package";
      autoload = "on";
    };
  };

  spellConfig = {
    dicts = {
      enabled = "en,pt_BR";
    };
    aspell = {
      search_aka = "off";
    };
  };

  ircConfig = {
    look = {
      new_channel_position = "bottom";
      new_server_position = "bottom";
      display_channel_join = "on";
      display_motd = "on";
    };
    color = {
      away = "red";
      error = "red";
      highlight = "white";
      information = "cyan";
      nick = "lightgreen";
      ssl_self = "green";
      user = "lightblue";
      topic_changed = "yellow";
    };
    server_default = {
      ipv6 = "on";
      ssl = "on";
      ssl_verify = "off";
    };
  };

  buflistConfig = {
    look = {
      scroll_horiz = "off";
      mouse_wheel = "on";
      show_cursor = "on";
    };
    format = {
      buffer = "\${color:42}●\${color:reset} \${color:237}\${name}\${color:reset}";
      hotlist = "\${color:69}(\${color:reset}\${hotlist}\${color:69})\${color:reset}";
      number = "\${if:\${number}<10||\${number}>20?\${number}:\${if:\${number}==10? 0:\${if:\${number}==11? Q:\${if:\${number}==12? W:\${if:\${number}==13? E:\${if:\${number}==14? R:\${if:\${number}==15? T:\${if:\${number}==16? Y:\${if:\${number}==17? U:\${if:\${number}==18? I:\${if:\${number}==19? O:\${if:\${number}==20? P}}}}}}}}}}}";
    };
  };

  triggerConfig = {
    look = { };
    color = { };
    trigger = {
      "url_color.arguments" =
        "\${tg_tags} !~ irc_quit;[a-z]+://\\S+;\${color:32}\${re:0}\${color:reset};";
      "url_color.command" = "";
      "url_color.conditions" = "";
      "url_color.enabled" = "on";
      "url_color.hook" = "modifier";
      "url_color.post_action" = "none";
      "url_color.regex" = "";
      "url_color.return_code" = "ok";
      "input_backtick.arguments" = "500|input_text_display";
      "input_backtick.command" = "";
      "input_backtick.conditions" = "";
      "input_backtick.enabled" = "on";
      "input_backtick.hook" = "modifier";
      "input_backtick.post_action" = "none";
      "input_backtick.regex" =
        "/(^| )(`[^`]+)($|(`)($|[,.?!:; ]))/\${re:1}\${color:,darkgray}\${re:2}\${re:4}\${color:,default}\${re:5}/";
      "input_backtick.return_code" = "ok";
      "print_backtick.arguments" = "weechat_print";
      "print_backtick.command" = "";
      "print_backtick.conditions" = "";
      "print_backtick.enabled" = "on";
      "print_backtick.hook" = "modifier";
      "print_backtick.post_action" = "none";
      "print_backtick.regex" =
        "/(^|\\t|\\d| )(`[^`]+`)([,.?!:; ]|$)/\${re:1}\${color:,darkgray}\${re:2}\${color:,default}\${re:3}/";
      "print_backtick.return_code" = "ok";
    };
  };

  aliasConfig = {
    cmd = {
      open = "/url_hint_replace /exec -bg xdg-open {url$1}";
    };
    completion = { };
  };

  configDir = jvfLib.filesystem.mkConfigDir "weechat-config" {
    "weechat.conf" = weechatConfig;
    "plugins.conf" = pluginsConfig;
    "spell.conf" = spellConfig;
    "irc.conf" = ircConfig;
    "buflist.conf" = buflistConfig;
    "trigger.conf" = triggerConfig;
    "alias.conf" = aliasConfig;
  };

  weechatWithPlugins = pkgs.wrapWeechat cfg.package {
    configure =
      { availablePlugins, ... }:
      {
        plugins = builtins.attrValues (
          builtins.removeAttrs availablePlugins [
            "python-plugins"
            "perl-plugins"
            "lua-plugins"
            "tcl-plugins"
            "ruby-plugins"
            "guile-plugins"
          ]
        );
        scripts = cfg.plugins ++ cfg.additionalScripts;
      };
  };

  weechatPackage = (
    pkgs.writeShellScriptBin "weechat" ''
      WEECHAT_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}/weechat"
      mkdir -p "$WEECHAT_HOME"

      if [ ! -f "$WEECHAT_HOME/.config_initialized" ]; then
        cp ${configDir}/weechat.conf "$WEECHAT_HOME/weechat.conf"
        cp ${configDir}/plugins.conf "$WEECHAT_HOME/plugins.conf"
        cp ${configDir}/spell.conf "$WEECHAT_HOME/spell.conf"
        cp ${configDir}/irc.conf "$WEECHAT_HOME/irc.conf"
        cp ${configDir}/buflist.conf "$WEECHAT_HOME/buflist.conf"
        cp ${configDir}/trigger.conf "$WEECHAT_HOME/trigger.conf"
        cp ${configDir}/alias.conf "$WEECHAT_HOME/alias.conf"
        touch "$WEECHAT_HOME/.config_initialized"
      fi

      exec ${weechatWithPlugins}/bin/weechat --dir "$WEECHAT_HOME" "$@"
    ''
  );
in
{
  options.jvf.programs.weechat = {
    enable = lib.mkEnableOption "weechat, an extensible chat client";
    package = lib.mkPackageOption pkgs "weechat-unwrapped" { };
    additionalScripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of weechat scripts to install in addition to the default set.";
    };
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = defaultPlugins;
      description = "List of weechat scripts to install.";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to weechat configuration file. If provided, will be copied to /etc/weechat/weechat.conf";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.aspellDicts.pt_BR
      weechatPackage
    ];
  };
}
