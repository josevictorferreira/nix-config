{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.weechat;
  slackSecretPath = "/run/secrets/slack_api_token";
  matrixUrlPath = "/run/secrets/matrix_server_url";
  matrixUserPath = "/run/secrets/matrix_server_username";
  matrixPassPath = "/run/secrets/matrix_server_password";

  weechatSettings = {
    weechat = {
      bar = {
        input.items = "[buffer_name]+[input_prompt]+(away),[input_search],[input_paste],input_text";
        status.items = "[time],[buffer_count],[buffer_plugin],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_filter,[lag],[spell_dict],[spell_suggest],completion,scroll";
        buflist = {
          position = "left";
          size_max = "24";
        };
      };
      look = {
        color_nick_offline = "yes";
        save_config_on_exit = "off";
        prefix_same_nick = "⤷";
        prefix_action = " •";
        # UI from guide (WeeChat 2.8+)
        bar_more_down = "";
        bar_more_up = "";
        bar_more_left = "◀";
        bar_more_right = "▶";
        buffer_notify_default = "message";
        buffer_time_format = ''"''${color:245}%H''${color:253}%M"'';
        color_inactive_message = "off";
        color_inactive_prefix = "off";
        color_inactive_prefix_buffer = "off";
        color_inactive_window = "off";
        day_change_message_1date = ''"▬▬▶ %a, %d %b %Y ◀▬▬"'';
        day_change_message_2dates = ''"▬▬▶ %%a, %%d %%b %%Y (%a, %d %b %Y) ◀▬▬"'';
        hotlist_add_conditions = ''"''${away} || ''${buffer.num_displayed} == 0"'';
        item_buffer_filter = "•";
        prefix_align_min = "0";
        prefix_align_max = "10";
        prefix_align = "right";
        prefix_join = "▬▬▶";
        prefix_quit = "◀▬▬";
        prefix_suffix = "│";
        read_marker_string = "─";
        separator_horizontal = "";
      };
      color = {
        bar_more = "229";
        chat_time = "239";
        chat_host = "31";
        chat_prefix_join = "121";
        chat_prefix_quit = "131";
        chat_nick_colors = "cyan,magenta,green,brown,lightblue,lightcyan,lightmagenta,lightgreen,blue";
        chat_highlight = "lightred";
        chat_highlight_bg = "default";
        chat_prefix_more = "31";
        chat_prefix_suffix = "31";
        chat_read_marker = "31";
        chat_delimiters = "31";
        separator = "31";
        status_data_highlight = "163";
        status_data_msg = "229";
        status_data_private = "121";
        status_more = "229";
        status_name = "121";
        status_name_ssl = "121";
      };
    };
    irc = {
      look = {
        server_buffer = "independent";
        color_nicks_in_nicklist = "on";
        part_closes_buffer = "on";
        buffer_switch_autojoin = "off";
        buffer_switch_join = "off";
      };
      color = {
        message_join = "121";
        message_quit = "131";
        nick_prefixes = "q:lightred;a:lightcyan;o:121;h:lightmagenta;v:229;*:lightblue";
      };
    };
    buflist = {
      look = {
        sort = "plugin,number";
        add_newline = "on";
        signals_refresh = "irc_server_connected,relay_client_connected,relay_client_disconnected";
        display_conditions = ''"''${buffer.hidden}==0 && ''${if:''${bar_item.name}=~^(buflist|buflist2)$?''${if:''${type}=~^(channel|private)$&&''${buffer[''${info:irc_buffer,''${irc_server.name}}].local_variables.fold}==1?0:1}:''${if:''${bar_item.name}==buflist3&&''${buffer.local_variables.control_buffer}}}"'';
      };
      format = {
        hotlist_highlight = ''"''${color:163}"'';
        hotlist_message = ''"''${color:229}"'';
        hotlist_private = ''"''${color:121}"'';
      };
    };
    fset = {
      color = {
        line_selected_bg1 = "default";
        name_changed = "229";
        name_changed_selected = "*229";
        type = "121";
        type_selected = "*121";
        value = "31";
        value_changed = "229";
        value_changed_selected = "*229";
        value_selected = "*31";
      };
      format = {
        option1 = ''"''${if:''${selected_line}?''${color:*white}>>:  } ''${marked} ''${name}  ''${type}  ''${value2}"'';
      };
    };
    # Bar control (control_buffers window number; buflist real network name)
    "plugins.var.python.control_buffers_window" = "2";
    "plugins.var.python.buflist_real_net_name" = "1";
    # Smart filter (UI: hide join/part in inactive buffers)
    "irc.look.smart_filter" = "on";
    plugins.var.python = {
      slack = {
        autoconnect = "off";
        slack_api_token = "\${sec.data.slack_token}";
      };
      vimode = {
        no_warn = "on";
        search_vim = "on";
      };
    };
  };

  # Buflist/fset format strings (guide UI) - merged into flattened settings
  weechatSettingsBuflistFormat = {
    "buflist.format.buffer" =
      ''"''${if:''${bar_item.name}==buflist?''${format_name}:''${if:''${bar_item.name}==buflist2?''${if:''${type}==server?''${color:31,31}} ''${format_hotlist}:''${if:''${bar_item.name}==buflist3?''${format_name}}}}"'';
    "buflist.format.buffer_current" =
      ''"''${if:''${bar_item.name}==buflist?''${format_name}:''${if:''${bar_item.name}==buflist2?''${if:''${type}==server?''${color:31,31}} :''${if:''${bar_item.name}==buflist3?''${format_name}}}}"'';
    "buflist.format.number" =
      ''"''${if:''${current_buffer}?''${if:''${type}==server?''${color:*white,31}:''${color:*white}}''${hide:>,''${number}} :''${if:''${type}==server?''${color:black,31}:''${color:239}}''${number}''${if:''${number_displayed}?.: }}"'';
    "buflist.format.indent" =
      ''"''${if:''${type}==channel&&''${buffer.name}=~fr$||''${info:spell_dict,''${buffer.full_name}}=~^fr?''${color:blue}f :  }"'';
    "buflist.format.name" =
      ''"''${if:''${bar_item.name}==buflist?''${cutscr:+''${weechat.bar.buflist.size},''${if:''${type}==server?''${color:white}:''${color:''${weechat.color.chat_prefix_more}}}''${weechat.look.prefix_align_more},''${eval:''${format_number}''${indent}}''${if:''${type}==server?''${color:white,31}''${if:''${plugins.var.buflist_real_net_name}!=&&''${info:irc_server_isupport_value,''${name},NETWORK}?''${info:irc_server_isupport_value,''${name},NETWORK}:''${name}}:''${eval:''${color_hotlist}}''${name}}''${color:31}''${if:''${buffer.local_variables.filter}? ''${buffer.local_variables.filter}}}''${if:''${bar_item.name}==buflist3?''${if:''${window.buffer.full_name}==''${buffer.full_name}?''${color:31}''${\u2026}''${color:white,31} ''${cutscr:7,''${\u2026},''${name}} ''${color:reset}''${color:31}''${\u2026}:''${color:24}''${\u2026}''${color:darkgray,24} ''${cutscr:7,''${\u2026},''${name}} ''${color:reset}''${color:24}''${\u2026}}}}"'';
    "buflist.format.hotlist" =
      ''"''${if:''${lengthscr: ''${hotlist}} > ''${weechat.bar.buflist_hotlist.size}?''${cutscr:+''${calc:''${weechat.bar.buflist_hotlist.size} - 1},''${if:''${type}==server?''${color:white}:''${color:''${weechat.color.chat_prefix_more}}}''${weechat.look.prefix_align_more},''${hotlist}}:''${repeat:''${calc:''${weechat.bar.buflist_hotlist.size} - ''${lengthscr: ''${hotlist}}}, }''${hotlist}}}"'';
    "weechat.bar.fset.conditions" =
      ''"''${buffer.full_name} == fset.fset && ''${window.win_height} > 7"'';
  };

  # Flatten nested attrset to dot-notation keys
  flattenSettings =
    prefix: attrs:
    lib.concatLists (
      lib.mapAttrsToList (
        name: value:
        let
          key = if prefix == "" then name else "${prefix}.${name}";
        in
        if lib.isAttrs value then flattenSettings key value else [ { inherit key value; } ]
      ) attrs
    );

  flattenedSettings =
    flattenSettings "" weechatSettings ++ flattenSettings "" weechatSettingsBuflistFormat;

  # Matrix setup script - outputs all commands in sequence
  matrixSetupScript = pkgs.writeShellScript "weechat-matrix-setup" ''
    echo "/secure set matrix_password $(cat ${matrixPassPath})"
    echo "/matrix server add homelab-matrix $(cat ${matrixUrlPath})"
    echo "/set matrix-rust.server.homelab-matrix.username $(cat ${matrixUserPath})"
    echo "/set matrix-rust.server.homelab-matrix.password $(cat ${matrixPassPath})"
    echo "/matrix connect homelab-matrix"
  '';

  # Slack setup script - only sets token, connect happens via autoconnect setting
  slackSetupScript = pkgs.writeShellScript "weechat-slack-setup" ''
    echo "/secure set slack_token $(cat ${slackSecretPath})"
  '';

  # UI-only init commands from guide (bars, mouse, keys, triggers, filter)
  weechatInitUiCommands = [
    "/mouse enable"
    "/bar set buflist separator off"
    "/bar set buflist priority 2"
    "/bar set buflist size 15"
    "/bar add buflist_hotlist root left 3 1 buflist2"
    "/bar set buflist_hotlist priority 1"
    "/bar add control_buffers window top 1 1 buflist3"
    "/bar set control_buffers priority 499"
    "/bar set control_buffers conditions \${window.number} == \${if:\${plugins.var.control_buffers_window}?\${plugins.var.control_buffers_window}:2}"
    "/bar del title"
    "/bar add titlenosep window top 1 0 [#window_number],[window_is_active],buffer_title"
    "/bar set titlenosep priority 500"
    "/bar set titlenosep conditions \${window.number} == \${if:\${plugins.var.control_buffers_window}?\${plugins.var.control_buffers_window}:2}"
    "/bar set titlenosep color_fg white"
    "/bar set titlenosep color_bg 31"
    "/bar add titlesep window top 1 1 [#window_number],[window_is_active],buffer_title"
    "/bar set titlesep priority 500"
    "/bar set titlesep conditions \${window.number} != \${if:\${plugins.var.control_buffers_window}?\${plugins.var.control_buffers_window}:2}"
    "/bar set titlesep color_fg white"
    "/bar set titlesep color_bg 31"
    "/bar add rootstatus root bottom 1 1 [time],[buffer_count],[buffer_plugin],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_filter,[lag],[spell_dict],[spell_suggest],completion,scroll"
    "/bar set rootstatus color_fg 31"
    "/bar set rootstatus color_bg 234"
    "/bar set rootstatus priority 500"
    "/bar del status"
    "/bar set rootstatus name status"
    "/bar add rootinput root bottom 1 0 [buffer_name]+[input_prompt]+(away),[input_search],[input_paste],input_text"
    "/bar set rootinput color_bg black"
    "/bar set rootinput priority 1000"
    "/bar del input"
    "/bar set rootinput name input"
    "/bar set nicklist color_fg 229"
    "/bar set nicklist separator 1"
    "/bar set nicklist conditions \${nicklist} && \${window.number} == 1"
    "/bar set nicklist size_max 14"
    "/bar set nicklist size 14"
    "/bar add line_number root left 5 1 line_number"
    "/bar set line_number hidden on"
    "/filter add irc_smart * irc_smart_filter *"
    # Triggers: buflist scroll sync, refresh on resize, control_buffers
    "/trigger add buflist_scroll_buflist command_run \"/bar scroll buflist*\""
    "/trigger set buflist_scroll_buflist regex \"/.*/\${tg_command}/my_arguments /.* ([^ ]+)$/\${re:1}/my_arguments\""
    "/trigger set buflist_scroll_buflist command \"/bar scroll buflist * \${my_arguments};/bar scroll buflist_hotlist * \${my_arguments}\""
    "/trigger set buflist_scroll_buflist return_code ok_eat"
    "/trigger add buflist_refresh_options config \"weechat.bar.buflist.size*;weechat.bar.buflist_hotlist.size*;plugins.var.buflist_real_net_name\""
    "/trigger set buflist_refresh_options command \"/buflist refresh\""
    "/trigger add control_buffers_change_control_window config \"plugins.var.control_buffers_window\""
    "/trigger set control_buffers_change_control_window command \"/window refresh\""
    "/trigger add control_buffers_add_del_buffer hsignal add_del_buffer"
    "/trigger set control_buffers_add_del_buffer regex \"/.*/\${if:\${_chat}?\${_buffer_full_name}:\${full_name}}/my_full_name\""
    "/trigger set control_buffers_add_del_buffer command \"/mute buffer_autoset \${if:\${buffer_autoset.buffer.\${my_full_name}.localvar_set_control_buffer}?del \${my_full_name}.localvar_set_control_buffer:add \${my_full_name} localvar_set_control_buffer 1};/command -buffer \${my_full_name} * /buffer set localvar_set_control_buffer \${if:\${buffer_autoset.buffer.\${my_full_name}.localvar_set_control_buffer}?1:0}\""
    # Key bindings: mouse bar scroll, control_buffers drag/drop, buflist resize
    "/key bindctxt mouse @item(buflist)>bar(control_buffers):button1* hsignal:add_del_buffer"
    "/key bindctxt mouse @item(buflist2)>bar(control_buffers):button1* hsignal:add_del_buffer"
    "/key bindctxt mouse @chat(*)>bar(control_buffers):button1* hsignal:add_del_buffer"
    "/key bindctxt mouse @bar(control_buffers)>chat(*):button1* /mute set plugins.var.control_buffers_window \${_window_number2}"
    "/key bindctxt mouse @bar(buflist*):alt-wheel* /bar set \${_bar_name} size \${calc:\${weechat.bar.\${_bar_name}.size} \${if:\${_key}=~up$?-:+} 1}"
    "/key bindctxt mouse @item(buflist3):button1* /mute set plugins.var.control_buffers_previous_active_window \${window.number};/window \${_window_number};hsignal:buflist_mouse;/window \${plugins.var.control_buffers_previous_active_window}"
    "/key bindctxt cursor @item(buflist*):c hsignal:add_del_buffer;/cursor stop"
    "/key bindctxt cursor @item(buflist*):f /command -buffer irc.server.\${localvar_server} * /eval /buffer set localvar_set_fold \${if:\${buffer.local_variables.fold}?0:1};/cursor stop"
    "/key bindctxt cursor @item(buflist*):r /server raw c:\${\${if:\${localvar_type}==server?server:channel}}==\${localvar_channel};/cursor stop"
    "/key bindctxt cursor @item(buflist*):o /fset c:\${name}=*buffer_autoset.buffer.\${full_name}.* \${if:\${localvar_type}==server?|| \${name}=*\${full_name}.*};/cursor stop"
  ];

  weechatMatrixRs =
    let
      pkg = pkgs.rustPlatform.buildRustPackage rec {
        pname = "weechat-matrix-rs";
        version = "0.1.0-unstable-2025-01-15";

        src = pkgs.fetchFromGitHub {
          owner = "poljar";
          repo = "weechat-matrix-rs";
          rev = "4cc5777b630ba4d6a9c964248531f283178a4717";
          hash = "sha256-CF4xDoRYey9F8/XSW/euNb8IjZXyP6k0Nj61shsmyEo=";
        };

        cargoHash = "sha256-jAlBCmLJfWWAUHd3ySB930iqAVXMh6ueba7xS///Rt0=";

        nativeBuildInputs = with pkgs; [
          pkg-config
          cmake
          rustPlatform.bindgenHook
        ];

        buildInputs = with pkgs; [
          openssl
          weechat
          sqlite
        ];

        # Plugin outputs libmatrix.so
        postInstall = ''
          mkdir -p $out/lib/weechat/plugins
          cp $out/lib/libmatrix.so $out/lib/weechat/plugins/matrix.so || true
        '';

        meta = with lib; {
          description = "Rust Matrix plugin for Weechat";
          homepage = "https://github.com/poljar/weechat-matrix-rs";
          license = licenses.isc;
          platforms = platforms.unix;
        };
      };
    in
    pkg
    // {
      pluginFile = "${pkg}/lib/weechat/plugins/matrix.so";
    };

  weechatInit = lib.concatStringsSep "\n" (
    [
      # Set slack token from secret file and connect (single exec for all slack commands)
      "/exec -oc ${slackSetupScript}"
    ]
    ++ lib.optionals cfg.matrix.enable [
      # Matrix commands via single exec to ensure sequencing
      "/exec -oc ${matrixSetupScript}"
    ]
    ++ [
      (lib.concatStringsSep "\n" (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings))
    ]
    ++ weechatInitUiCommands
  );

  # Commands to run on startup (init commands separated by semicolons for -r flag)
  weechatInitCommands = lib.concatStringsSep ";" (
    [
      # Set slack token from secret file
      "/exec -oc ${slackSetupScript}"
      "/bar hide nicklist"
    ]
    ++ lib.optionals cfg.matrix.enable [
      # Matrix commands via single exec to ensure sequencing
      "/exec -oc ${matrixSetupScript}"
    ]
    ++ (map (s: "/set ${s.key} \"${s.value}\"") flattenedSettings)
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
        ]
        ++ lib.optionals cfg.matrix.enable [
          weechatMatrixRs
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
    matrix = {
      enable = lib.mkEnableOption "Matrix protocol support via weechat-matrix-rs";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.slack_api_token = {
      path = "/run/secrets/slack_api_token";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_url = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_url";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_username = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_username";
      owner = cfg.username;
      mode = "0400";
    };

    sops.secrets.matrix_server_password = lib.mkIf cfg.matrix.enable {
      path = "/run/secrets/matrix_server_password";
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
      # Don't use -r flag - init commands are already in the package via weechatInit
      command = "${lib.getExe cfg.package}";
    };
  };
}
