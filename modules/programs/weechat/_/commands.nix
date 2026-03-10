# _/commands.nix - Default Weechat commands and filters
{ lib, ... }:
{
  jvf.programs.weechat = {
    extraCommands = lib.mkDefault [
    ];

    # Buflist filter commands
    autohideFilterCommands = lib.mkDefault [
      # Discord: hide nested (categories and channels), keep only #Discord parent
      # WhatsApp: hide contacts, keep only bridge parent
    ];
  };
}
