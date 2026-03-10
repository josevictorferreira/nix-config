# _/commands.nix - Default Weechat commands and filters
{ lib, ... }:
{
  jvf.programs.weechat = {
    extraCommands = lib.mkDefault [
      "/trigger add upgrade_scripts signal day_changed"
      "/trigger set upgrade_scripts command \"/script update\\;\\;wait 10s \\;\\;script upgrade\""
      "/alias add cq allpv /buffer close"
      "/alias add slap /me slaps $1 around a bit with a large trout"
      "/alias add customgrep /input delete_line\\;\\;input insert /grep log */$server/$channel.* -a ^\\[\\d{2}:\\d{2}:\\d{2}\\] <%{escape $1}>\\x20"
      "/alias add ptpburl /exec -sh -hsignal ptpburl $* 2>&1 | curl -sF c=@- https://ptpb.pw/?u=1"
      "/trigger add ptpburl hsignal ptpburl"
      "/trigger set ptpburl command \"/command -buffer \${buffer.full_name} core /input delete_line\\;\\;command -buffer \${buffer.full_name} core /input insert \${out}\""
      "/key bindctxt cursor @item(buffer_nicklist):v /window \${_window_number}\\;\\;voice \${nick}"
      "/filter addreplace irc_smart *,!irc.undernet.* irc_smart_filter *"
      "/bar del activetitle"
      "/bar add activetitle window top 1 0 buffer_title"
    ];

    # Buflist filter commands
    autohideFilterCommands = lib.mkDefault [
      # Discord: hide nested (categories and channels), keep only #Discord parent
      ''/filter add buflist_hide_discord_nested * * ^#Discord\..*''
      # WhatsApp: hide contacts, keep only bridge parent
      ''/filter add buflist_hide_whatsapp_nested * * ^#WhatsApp.*\..*''
    ];
  };
}
