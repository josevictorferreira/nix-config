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

      # Wrapper environment (symlinkJoin of wrapper script + packages)
      obsidianWrapperEnv = pkgs.symlinkJoin {
        name = "obsidian-env";
        paths = [
          (pkgs.writeShellScriptBin "obsidian" ''
            export DICPATH="${pkgs.hunspellDicts.en_US}/lib/hunspell:${pkgs.hunspellDicts.pt_BR}/lib/hunspell"
            exec ${lib.getExe pkgs.obsidian} "$@"
          '')
          pkgs.hunspellDicts.en_US
          pkgs.hunspellDicts.pt_BR
        ];
      };

      # Desktop entry with full path to wrapper
      obsidianDesktopItem = pkgs.makeDesktopItem {
        name = "obsidian";
        desktopName = "Obsidian";
        exec = "${obsidianWrapperEnv}/bin/obsidian %u";
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
        # Install both desktop item and wrapper to user profile
        users.users."${cfg.username}".packages = [ obsidianDesktopItem obsidianWrapperEnv ];
      };
    };
in
{
  flake.modules.nixos.programs-obsidian = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-obsidian = mkConfig { isDarwin = true; };
}
