{ lib, ... }:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.obsidian;

      # Desktop entry for the wrapper so it appears in Rofi
      obsidianDesktopItem = pkgs.makeDesktopItem {
        name = "obsidian";
        desktopName = "Obsidian";
        exec = "obsidian %u";
        icon = "obsidian";
        terminal = false;
        type = "Application";
        categories = [ "Office" ];
        mimeTypes = [ "x-scheme-handler/obsidian" ];
      };
    in
    {
      options.jvf.programs.obsidian.username = lib.mkOption {
        type = lib.types.str;
        default = config.jvf.core.username;
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.obsidian = {
          packages = [
            pkgs.hunspellDicts.en_US
            pkgs.hunspellDicts.pt_BR
            obsidianDesktopItem
          ];
          command = lib.getExe pkgs.obsidian;
          env = {
            DICPATH = "${pkgs.hunspellDicts.en_US}/lib/hunspell:${pkgs.hunspellDicts.pt_BR}/lib/hunspell";
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-obsidian = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-obsidian = mkConfig { isDarwin = true; };
}
