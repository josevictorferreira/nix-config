{ lib
, pkgs
,
}:
let
  weechatMatrixRs =
    let
      pkg = pkgs.rustPlatform.buildRustPackage {
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
in
{
  native = [
    "python"
    "perl"
    "lua"
    "ruby"
  ];

  matrix = weechatMatrixRs;

  scripts = [
    pkgs.weechatScripts.highmon
    pkgs.weechatScripts.colorize_nicks
    pkgs.weechatScripts.wee-slack
    pkgs.weechatScripts.url_hint
    pkgs.weechatScripts.multiline
    pkgs.weechatScripts.weechat-notify-send
    viModeScript
  ];
}
