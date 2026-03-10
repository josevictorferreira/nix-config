# _/scripts.nix - Weechat script derivations and defaults
{
  lib,
  pkgs,
  ...
}:
let
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
  # Merge user scripts with defaults
  jvf.programs.weechat.plugins.scripts = lib.mkDefault defaultScripts;
}
