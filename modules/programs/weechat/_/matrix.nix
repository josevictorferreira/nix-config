# _/matrix.nix - Matrix protocol plugin for Weechat
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jvf.programs.weechat;

  # Secret paths for Matrix
  secretPaths = {
    matrixUrl = "/run/secrets/matrix_server_url";
    matrixUser = "/run/secrets/matrix_server_username";
    matrixAccessToken = "/run/secrets/matrix_server_access_token";
  };

  # Use weechat-matrix-rs from nixpkgs as it's better maintained
  # and the manual derivation was failing to build.
  weechatMatrixRs = pkgs.weechat-matrix-rs.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      pluginFile = "${pkgs.weechat-matrix-rs}/lib/weechat/plugins/matrix.so";
    };
  });

  # Matrix setup script
  matrixSetupScript = pkgs.writeShellScript "weechat-matrix-setup" ''
    echo "/plugin load matrix"
    echo "/matrix server add homelab-matrix $(cat ${secretPaths.matrixUrl})"
    echo "/set matrix-rust.server.homelab-matrix.username $(cat ${secretPaths.matrixUser})"
    echo "/set matrix-rust.server.homelab-matrix.access-token $(cat ${secretPaths.matrixAccessToken})"
    echo "/set matrix-rust.server.homelab-matrix.autoconnect on"
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
      matrix_server_access_token = {
        path = secretPaths.matrixAccessToken;
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
