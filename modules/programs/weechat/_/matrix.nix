# _/matrix.nix - Matrix protocol plugin for Weechat
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.jvf.programs.weechat;

  # Secret paths for Matrix
  secretPaths = {
    matrixUrl = "/run/secrets/matrix_server_url";
    matrixUser = "/run/secrets/matrix_server_username";
    matrixPass = "/run/secrets/matrix_server_password";
  };

  # Matrix plugin (Rust-based) derivation
  weechatMatrixRs = pkgs.rustPlatform.buildRustPackage {
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
      pkgs.weechat
      sqlite
    ];

    postInstall = ''
      mkdir -p $out/lib/weechat/plugins
      cp $out/lib/libmatrix.so $out/lib/weechat/plugins/matrix.so 2>/dev/null || true
      cp $out/lib/libmatrix.dylib $out/lib/weechat/plugins/matrix.so 2>/dev/null || true
    '';

    passthru.pluginFile = "${placeholder "out"}/lib/weechat/plugins/matrix.so";

    meta = with lib; {
      description = "Rust Matrix plugin for Weechat";
      homepage = "https://github.com/poljar/weechat-matrix-rs";
      license = licenses.isc;
      platforms = platforms.unix;
    };
  };

  # Matrix setup script
  matrixSetupScript = pkgs.writeShellScript "weechat-matrix-setup" ''
    echo "/secure set matrix_password $(cat ${secretPaths.matrixPass})"
    echo "/matrix server add homelab-matrix $(cat ${secretPaths.matrixUrl})"
    echo "/set matrix-rust.server.homelab-matrix.username $(cat ${secretPaths.matrixUser})"
    echo "/set matrix-rust.server.homelab-matrix.password $(cat ${secretPaths.matrixPass})"
    echo "/matrix connect homelab-matrix"
  '';
in
{
  config = lib.mkIf cfg.matrix.enable {
    # Make matrix plugin available via option (default.nix will use this)
    jvf.programs.weechat.matrixPlugin = weechatMatrixRs;

    # SOPS secrets for Matrix
    sops.secrets = {
      matrix_server_url = {
        path = secretPaths.matrixUrl;
        owner = cfg.username;
        mode = "0400";
      };
      matrix_server_username = {
        path = secretPaths.matrixUser;
        owner = cfg.username;
        mode = "0400";
      };
      matrix_server_password = {
        path = secretPaths.matrixPass;
        owner = cfg.username;
        mode = "0400";
      };
    };

    # Pass matrix setup script to init
    jvf.programs.weechat.extraInitCommands = lib.mkDefault [
      "/exec -oc ${matrixSetupScript}"
    ];
  };
}
