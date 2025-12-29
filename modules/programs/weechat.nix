{ lib
, pkgs
, config
, username
, ...
}:
let
  cfg = config.jvf.programs.weechat;
  homeDir = if pkgs.stdenv.isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
  weechatHomeDir = "${homeDir}/.config/weechat";

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
      align_end_of_lines = "message";
      align_multiline_words = "on";
      bar_more_down = "";
      bar_more_left = "…";
      bar_more_right = "…";
      bar_more_up = "";
      buffer_notify_default = "message";
      # Minimal time format for vertical monitor
      buffer_time_format = "%H:%M";
      color_inactive_message = "off";
      color_inactive_prefix = "off";
      color_inactive_prefix_buffer = "off";
      color_inactive_window = "off";
      color_nick_offline = "off";
      hotlist_add_conditions = "\${away} || \${buffer.num_displayed} == 0";
      item_buffer_filter = "•";
      mouse = "on";
      nick_prefix = "";
      nick_suffix = "";
      # Minimal prefix settings for vertical monitor
      prefix_align = "none";
      prefix_align_max = 0;
      prefix_align_min = 0;
      prefix_align_more = "+";
      prefix_align_more_after = "on";
      prefix_buffer_align = "none";
      prefix_buffer_align_max = 0;
      prefix_join = "→";
      prefix_quit = "←";
      prefix_same_nick = "";
      prefix_suffix = "";
      read_marker_string = "─";
      separator_horizontal = "";
      # Disable config saving - Nix manages this config
      save_config_on_exit = "off";
      save_layout_on_exit = "none";
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
      # Input bar configuration
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
      # Nicklist (users pane) - completely hidden for vertical monitor
      "nicklist.color_bg" = "default";
      "nicklist.color_fg" = "default";
      "nicklist.conditions" = "";
      "nicklist.filling_left_right" = "vertical";
      "nicklist.filling_top_bottom" = "columns_vertical";
      "nicklist.hidden" = "on";
      "nicklist.items" = "buffer_nicklist";
      "nicklist.position" = "right";
      "nicklist.priority" = 200;
      "nicklist.separator" = "on";
      "nicklist.size" = 0;
      "nicklist.size_max" = 0;
      "nicklist.type" = "window";
      # Title bar
      "title.color_bg" = 56;
      "title.color_fg" = "white";
      "title.hidden" = "off";
      "title.position" = "top";
      "title.priority" = 500;
      "title.separator" = "off";
      "title.size" = 1;
      "title.size_max" = 1;
      "title.type" = "window";
      # Vi mode line numbers
      "vi_line_numbers.hidden" = "off";
      # Buflist bar - minimal width for vertical monitor
      "buflist.color_bg" = "default";
      "buflist.color_fg" = "default";
      "buflist.conditions" = "";
      "buflist.filling_left_right" = "vertical";
      "buflist.filling_top_bottom" = "columns_vertical";
      "buflist.hidden" = "off";
      "buflist.items" = "buflist";
      "buflist.position" = "left";
      "buflist.priority" = 0;
      "buflist.separator" = "on";
      "buflist.size" = 12;
      "buflist.size_max" = 12;
      "buflist.type" = "root";
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
    python = lib.mkIf cfg.slack.enable {
      description = "Python plugin";
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
      # Compact display for vertical monitor
      nick_prefix = "off";
      nick_prefix_empty = "off";
      display_conditions = "";
    };
    format = {
      # Minimal buffer format for vertical monitor - just short name, no indicator
      buffer = "\${color_hotlist}\${cut:10,…,\${short_name}}\${color:reset}";
      buffer_current = "\${color:white}\${cut:10,…,\${short_name}}\${color:reset}";
      hotlist = " \${color:69}\${hotlist}\${color:reset}";
      # No number to save space
      number = "";
      indent = "";
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

  # Slack config - workspace section added dynamically via init command
  # to read token from sops secret at runtime
  slackConfig = {
    look = {
      channel_name_typing_prefix = ">";
      part_closes_buffer = "on";
      show_buflist_duplicates = "on";
      workspace_name_display = "short";
      # Compact display settings for vertical monitor
      display_reaction_nicks = "off";
      render_emoji_as = "emoji";
      thread_broadcast_prefix = "↳";
    };
    notifications = {
      rich_text = "on";
      show_reaction_adds = "on";
      show_reaction_adds_changed = "on";
      show_typing = "off";
    };
    color = {
      # Minimal color scheme for cleaner look
      channel_prefix = "default";
      dm_prefix = "default";
      message_join = 141;
      message_quit = 135;
      reaction_prefix = 239;
      reaction_suffix = 239;
    };
  };

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
    configure = { availablePlugins, ... }: {
      scripts = cfg.additionalScripts;
      plugins = [
        availablePlugins.python
        availablePlugins.perl
        availablePlugins.lua
        availablePlugins.ruby
      ];
      init = ''
        /set plugins.var.python.vimode.no_warn on
        /set plugins.var.python.vimode.search_vim on
        /vimode bind_keys
      '';
    };
  };

  # Wrapper script that sets slack token before launching weechat
  weechatWrapper = pkgs.writeShellScriptBin "weechat" ''
    WEECHAT_DIR="${weechatHomeDir}"
    PLUGINS_CONF="$WEECHAT_DIR/plugins.conf"

    # Set slack token from sops secret before weechat starts
    if [ -f /run/secrets/slack_api_token ]; then
      SLACK_TOKEN=$(cat /run/secrets/slack_api_token)
      if [ -f "$PLUGINS_CONF" ]; then
        # Remove existing slack token line if present
        ${pkgs.gnused}/bin/sed -i '/^python\.slack\.slack_api_token/d' "$PLUGINS_CONF"
        # Ensure [var] section exists
        if ! grep -q '^\[var\]' "$PLUGINS_CONF"; then
          echo "" >> "$PLUGINS_CONF"
          echo "[var]" >> "$PLUGINS_CONF"
        fi
        # Add token after [var] section
        ${pkgs.gnused}/bin/sed -i "/^\[var\]/a python.slack.slack_api_token = \"$SLACK_TOKEN\"" "$PLUGINS_CONF"
      fi
    fi

    exec ${lib.getExe weechatPkg} --dir "$WEECHAT_DIR" "$@"
  '';
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
    slack = {
      enable = lib.mkEnableOption "Slack integration via wee-slack plugin";
      token = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Slack API token for workspace connection (xoxb-...)";
      };
      autoConnect = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically connect to Slack on WeeChat startup";
      };
      workspaces = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            token = lib.mkOption {
              type = lib.types.str;
              description = "Slack API token for this workspace (xoxb-...)";
            };
            autoConnect = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to auto-connect this workspace";
            };
          };
        });
        default = { };
        description = "Multiple Slack workspaces with their tokens";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.variables.WEECHAT_HOME = weechatHomeDir;

    sops.secrets.slack_api_token = {
      path = "/run/secrets/slack_api_token";
      owner = cfg.username;
      mode = "0400";
    };

    jvf.wrappers.users.${cfg.username}.programs.weechat = {
      command =
        if cfg.slack.enable
        then "${lib.getExe weechatWrapper} @"
        else "${lib.getExe weechatPkg} --dir ${weechatHomeDir} @";
      packages = [
        cfg.package
        pkgs.aspell
        pkgs.aspellDicts.en
        pkgs.aspellDicts.pt_BR
        pkgs.python3
      ] ++ cfg.additionalScripts;
      configs = {
        "weechat.conf" = weechatConfig;
        "plugins.conf" = pluginsConfig;
        "spell.conf" = spellConfig;
        "irc.conf" = ircConfig;
        "buflist.conf" = buflistConfig;
        "trigger.conf" = triggerConfig;
        "alias.conf" = aliasConfig;
      } // lib.optionalAttrs cfg.slack.enable {
        "slack.conf" = slackConfig;
      };
    };
  };
}
