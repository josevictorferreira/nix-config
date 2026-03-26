# _/scripts.nix - Weechat script derivations and defaults
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.jvf.programs.weechat;

  # Vimode script derivation
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

  # Bufcat script derivation (buflist categorization)
  bufcatScript = pkgs.stdenv.mkDerivation {
    pname = "bufcat";
    version = "0.1";

    src = ./bufcat;

    installPhase = ''
      runHook preInstall
      install -D bufcat.py $out/share/bufcat.py
      install -D bufcat.json $out/share/bufcat.json
      runHook postInstall
    '';

    meta = {
      description = "WeeChat buflist categorization script";
      license = lib.licenses.gpl3Plus;
    };
  };

  # Default scripts that are always included
  defaultScripts = [
    pkgs.weechatScripts.highmon
    pkgs.weechatScripts.colorize_nicks
    pkgs.weechatScripts.weechat-go
    pkgs.weechatScripts.url_hint
    pkgs.weechatScripts.multiline
    pkgs.weechatScripts.weechat-notify-send
    pkgs.weechatScripts.buffer_autoset
    pkgs.weechatScripts.weechat-grep
    viModeScript
  ];
in
{
  config = lib.mkMerge [
    {
      # Bufcat is not in plugins.scripts: nixpkgs prepends many /script load …; long run-commands can
      # drop or fail late loads. Load via absolute /python load in prependInitCommands (init.nix).
      jvf.programs.weechat.plugins.scripts = defaultScripts;
    }
    (lib.mkIf cfg.bufcat.enable {
      jvf.programs.weechat.prependInitCommands = [
        "/python load ${bufcatScript}/share/bufcat.py"
      ];
      jvf.wrappers.users.${cfg.username}.programs.weechat = {
        packages = lib.mkAfter [ bufcatScript ];
        # Always read JSON from the derivation so flake changes apply (a one-time copy to
        # ~/.local/share/weechat/bufcat.json would never update). Override with bufcat.configPath.
        env = {
          BUFCAT_CONFIG_PATH =
            if cfg.bufcat.configPath != null then cfg.bufcat.configPath else "${bufcatScript}/share/bufcat.json";
        };
      };
    })
  ];
}
