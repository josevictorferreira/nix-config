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

  weechatConf = lib.generators.toINI { } weechatConfig;

  pluginsConfig = {
    var = {
      "python.vimode.mode_indicator_cmd_color" = "white";
      "python.vimode.mode_indicator_cmd_color_bg" = "141";
      "python.vimode.mode_indicator_insert_color" = "white";
      "python.vimode.mode_indicator_insert_color_bg" = "56";
      "python.vimode.mode_indicator_normal_color" = "black";
      "python.vimode.mode_indicator_normal_color_bg" = "148";
      "python.vimode.mode_indicator_prefix" = "[";
      "python.vimode.mode_indicator_replace_color" = "white";
      "python.vimode.mode_indicator_replace_color_bg" = "196";
      "python.vimode.mode_indicator_search_color" = "white";
      "python.vimode.mode_indicator_search_color_bg" = "27";
      "python.vimode.mode_indicator_suffix" = "]";
      "python.vimode.search_vim" = "on";
      "python.slack.auto_open_threads" = "true";
      "python.slack.background_load_all_history" = "true";
      "python.slack.color_buflist_muted_channels" = "dark gray";
      "python.slack.color_deleted" = "red";
      "python.slack.color_edited_suffix" = "196";
      "python.slack.color_reaction_suffix" = "058";
      "python.slack.color_reaction_suffix_added_by_you" = "blue";
      "python.slack.color_thread_suffix" = "013";
      "python.slack.color_typing_notice" = "yellow";
      "python.slack.colorize_attachments" = "prefix";
      "python.slack.colorize_private_chats" = "false";
      "python.slack.debug_level" = "0";
      "python.slack.debug_mode" = "on";
      "python.slack.external_user_prefix" = "*";
      "python.slack.files_download_location" = "~/Downloads/weeslack";
      "python.slack.group_name_prefix" = "&";
      "python.slack.history_fetch_count" = "50";
      "python.slack.map_underline_to" = "_";
      "python.slack.muted_channels_activity" = "personal_highlights";
      "python.slack.never_away" = "true";
      "python.slack.notify_subscribed_threads" = "auto";
      "python.slack.notify_usergroup_handled_updated" = "false";
      "python.slack.record_events" = "false";
      "python.slack.render_bold_as" = "bold";
      "python.slack.render_emoji_as_string" = "false";
      "python.slack.render_italic_as" = "italic";
      "python.slack.send_typing_notice" = "false";
      "python.slack.shared_name_prefix" = "%";
      "python.slack.short_buffer_names" = "false";
      "python.slack.show_buflist_presense" = "true";
      "python.slack.show_emoji" = "true";
      "python.slack.show_emoji_reactions" = "true";
      "python.slack.show_emoji_reactions_in_threads" = "true";
      "python.slack.switch_buffer_on_join" = "true";
      "python.slack.thread_messages_in_channel" = "false";
      "python.slack.unfurl_auto_link_display" = "false";
      "python.slack.unfurl_ignore_alt_text" = "false";
      "python.slack.unhide_buffers_with_activity" = "false";
      "python.slack.use_full_names" = "false";
    };
    desc = { };
  };

  pluginsConf = lib.generators.toINI { } pluginsConfig;

  spellConfig = {
    color = { };
    check = {
      default_dict = "en,pt_BR";
      suggestions = 3;
    };
    dict = { };
    look = { };
    option = {
      ignore-case = "true";
    };
  };

  spellConf = lib.generators.toINI { } spellConfig;

  ircConfig = {
    look = {
      server_buffer = "independent";
    };
    color = { };
    network = { };
    msgbuffer = { };
    ctcp = { };
    ignore = { };
    server_default = { };
    server = { };
  };

  ircConf = lib.generators.toINI { } ircConfig;

  buflistConfig = {
    look = {
      sort = "number";
    };
    format = {
      buffer = "\${color_hotlist}\${format_number}\${if:\${buffer.name}=~^server?\${if:\${buffer.prev_buffer.number}==\${buffer.number}?├:┬}:\${if:\${type}==channel||\${type}==private?: }}\${indent}\${color_hotlist}\${format_nick_prefix}\${cut:15,…,\${name}} \${hotlist}";
      buffer_current = "\${color:magenta}>>\${if:\${type}==server?\${color:brown,default}:\${color:cyan,default}}\${if:\${buffer.name}=~^server?\${if:\${buffer.prev_buffer.number}==\${buffer.number}?├:┬}:\${if:\${type}==channel||\${type}==private?: }}\${indent}\${color_hotlist}\${format_nick_prefix}\${cut:15,…,\${name}} \${hotlist}";
      hotlist_highlight = "\${color:148}";
      hotlist_low = "\${color:white}";
      hotlist_message = "\${color:magenta}";
      hotlist_none = "\${if:\${type}==server?\${color:brown}:\${color:cyan}}";
      hotlist_private = "\${color:226}";
      indent = "\${color:brown}\${if:\${merged}?\${if:\${buffer.prev_buffer.number}!=\${buffer.number}?│┌:\${if:\${buffer.next_buffer.number}==\${buffer.number}?│├:\${if:\${buffer.next_buffer.name}=~^server||\${buffer.next_buffer.number}<0?└┴:├┴}}}:\${if:\${buffer.active}>0?\${if:\${buffer.next_buffer.name}=~^server?└:\${if:\${buffer.next_buffer.number}>0?├:└}}:\${if:\${buffer.next_buffer.name}=~^server? :│}}}─";
      number = "\${if:\${number}<10||\${number}>20?\${number}:\${if:\${number}==10? 0:\${if:\${number}==11? Q:\${if:\${number}==12? W:\${if:\${number}==13? E:\${if:\${number}==14? R:\${if:\${number}==15? T:\${if:\${number}==16? Y:\${if:\${number}==17? U:\${if:\${number}==18? I:\${if:\${number}==19? O:\${if:\${number}==20? P}}}}}}}}}}}";
    };
  };

  buflistConf = lib.generators.toINI { } buflistConfig;

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

  triggerConf = lib.generators.toINI { } triggerConfig;

  aliasConfig = {
    cmd = {
      open = "/url_hint_replace /exec -bg xdg-open {url$1}";
    };
    completion = { };
  };

  aliasConf = lib.generators.toINI { } aliasConfig;

  configDir = jvfLib.filesystem.mkConfigDir "weechat-config" {
    "weechat.conf" = weechatConf;
    "plugins.conf" = pluginsConf;
    "spell.conf" = spellConf;
    "irc.conf" = ircConf;
    "buflist.conf" = buflistConf;
    "trigger.conf" = triggerConf;
    "alias.conf" = aliasConf;
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
