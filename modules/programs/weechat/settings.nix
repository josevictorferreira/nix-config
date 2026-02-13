{
  weechat = {
    bar = {
      input.items = "mode_indicator+[input_prompt]+(away),[input_search], [input_paste],input_text,[vi_buffer]";
      status.items = "[time],[buffer_last_number],buffer_number+:+buffer_name+(buffer_modes)+{buffer_nicklist_count}+buffer_zoom+buffer_filter,scroll,[lag],[hotlist],completion,cmd_completion";
      buflist = {
        position = "left";
        size_max = "24";
      };
    };
    look = {
      color_nick_offline = "yes";
      buffer_time_format = "%H:%M";
      prefix_align = "none";
      prefix_align_max = "0";
      save_config_on_exit = "off";
      prefix_same_nick = "⤷";
      prefix_suffix = "│";
      prefix_action = " •";
      read_marker_string = "─";
      separator_horizontal = "";
      prefix_network = "▬▬";
    };
    color = {
      chat_time = "darkgray";
      chat_host = "cyan";
      chat_nick_colors = "1,2,3,4,6,7,9,10,11,12,13,14,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,182,183,184,244,225,226,227";
      chat_highlight = "*16";
      chat_highlight_bg = "9";
    };
  };
  buflist.look = {
    sort = "plugin,number";
    add_newline = "on";
  };
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
}
