# _/settings.nix - Default Weechat settings
{ lib, ... }:
{
  jvf.programs.weechat.settings = lib.mkDefault {
    weechat = {
      bar = {
        input.items = "mode_indicator+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]";
        status.items = "[time],[buffer_last_number],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_zoom+buffer_filter,scroll,[lag],[hotlist],completion,cmd_completion";
        buflist = {
          position = "left";
          size = "25";
          size_max = "30";
        };
        activetitle = {
          priority = "500";
          conditions = "\${active}";
          color_fg = "white";
          color_bg = "31";
          separator = "on";
        };
        title = {
          conditions = "\${inactive}";
          color_fg = "black";
          color_bg = "31";
        };
        nicklist = {
          color_fg = "229";
          separator = "on";
          conditions = "\${nicklist} && \${window.number} == 1";
          size_max = "20";
          size = "16";
        };
      };
      look = {
        mouse = "on";
        color_nick_offline = "yes";
        buffer_time_format = "\${253}%H\${245}%M";
        prefix_align = "none";
        prefix_align_min = "0";
        prefix_align_max = "14";
        save_config_on_exit = "off";
        prefix_same_nick = "⤷";
        prefix_suffix = "│";
        prefix_action = " •";
        read_marker_string = "─";
        separator_horizontal = "=";
        prefix_network = "▬▬";
        prefix_join = "▬▬▶";
        prefix_quit = "◀▬▬";
        bar_more_down = "▼";
        bar_more_left = "◀";
        bar_more_right = "▶";
        bar_more_up = "▲";
        color_inactive_message = "off";
        color_inactive_prefix = "off";
        color_inactive_prefix_buffer = "off";
        color_inactive_window = "off";
        day_change_message_1date = "▬▬▶ %a, %d %b %Y ◀▬▬";
        day_change_message_2dates = "▬▬▶ %%a, %%d %%b %%Y (%a, %d %b %Y) ◀▬▬";
        item_buffer_filter = "•";
      };
      color = {
        chat_time = "239";
        chat_host = "31";
        chat_nick_colors = "25,31,37,43,49,61,67,73,79,85,97,103,109,115,121,133,139,145,151,157,163,169,175,181,187,193,199,205,211,217,223,229";
        chat_highlight = "lightred";
        chat_highlight_bg = "default";
        bar_more = "229";
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
        chat_prefix_join = "121";
        chat_prefix_quit = "131";
      };
      plugin = {
        autoload = "*,!lua,!tcl,!ruby,!fifo,!xfer,!guile,!javascript";
      };
    };
    aspell = {
      check = {
        default_dict = "en";
        suggestions = "3";
      };
      color = {
        suggestions = "*green";
      };
    };
    logger = {
      level = {
        irc = "0";
      };
      mask = {
        irc = "%Y/$server/$channel.%m-%d.log";
      };
    };
    irc = {
      look = {
        server_buffer = "independent";
        smart_filter = "on";
        buffer_switch_autojoin = "off";
        buffer_switch_join = "off";
        color_nicks_in_nicklist = "on";
        part_closes_buffer = "on";
      };
      color = {
        message_join = "121";
        message_quit = "131";
        nick_prefixes = "q:lightred;a:lightcyan;o:121;h:lightmagenta;v:229;*:lightblue";
      };
      server_default = {
        away_check = "5";
        away_check_max_nicks = "25";
      };
      network = {
        ban_mask_default = "*!*@\$host";
      };
    };
    buflist = {
      format = {
        indent = "";
      };
    };
    plugins.var.python = {
      vimode = {
        no_warn = "on";
        search_vim = "on";
      };
    };
    plugins.var.perl.highmon.alignment = "nchannel";
  };
}
