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
    matrixPassword = "/run/secrets/matrix_server_password";
  };

  matrixSecureUsernameName = "homelab-matrix-username";
  matrixSecurePasswordName = "homelab-matrix-password";

  # Use a locally pinned build because the newer nixpkgs revision fails
  # with an upstream Rust/matrix-sdk regression.
  weechatMatrixRs = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "weechat-matrix-rs";
    version = "0-unstable-2025-06-11";

    src = pkgs.fetchFromGitHub {
      owner = "poljar";
      repo = "weechat-matrix-rs";
      rev = "b3512393350f119c12830f3da347b92a0f3136f8";
      hash = "sha256-QFfN1/L3tzvLZNGrjF0zcowwtHpRL2GAdu7lRpNhULk=";
    };

    cargoHash = "sha256-cbF4ytAyyMhTfChCyxRg+jxwCAEpRd+bFTIqD6PCH6Y=";

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.rustPlatform.bindgenHook
    ];

    buildInputs = [
      pkgs.weechat
      pkgs.openssl
      pkgs.sqlite
    ];

    postInstall = ''
      mkdir -p $out/lib/weechat/plugins
      mv $out/lib/libmatrix${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} $out/lib/weechat/plugins/matrix${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}
    '';

    passthru = {
      pluginFile = "${finalAttrs.finalPackage}/lib/weechat/plugins/matrix${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";
    };

    meta = {
      description = "Rust plugin for WeeChat to communicate over Matrix";
      homepage = "https://github.com/poljar/weechat-matrix-rs";
      license = lib.licenses.isc;
      platforms = lib.platforms.unix;
    };
  });

  # Matrix setup script
  matrixSetupScript = pkgs.writeShellScript "weechat-matrix-setup" ''
    matrixUrl=$(tr -d '\n' < ${secretPaths.matrixUrl})

    matrixUser=$(tr -d '\n' < ${secretPaths.matrixUser})
    matrixPassword=$(tr -d '\n' < ${secretPaths.matrixPassword})

    echo "/mute /secure set ${matrixSecureUsernameName} $matrixUser"
    echo "/mute /secure set ${matrixSecurePasswordName} $matrixPassword"

    # NOTE: matrix-rust.conf must NOT contain a [server] section for homelab-matrix.
    # /matrix server add has no duplicate guard: MatrixServer::new calls
    # new_string_option(...).expect(...), which panics and aborts WeeChat if the
    # option already exists (i.e. was loaded from the config file).
    echo "/matrix server add homelab-matrix $matrixUrl"
    # No backslash before the sec.data reference: /exec -oc does not evaluate
    # dollar-brace expressions, so a backslash is stored verbatim and the plugin
    # ends up logging in as "\<username>".
    echo '/set matrix-rust.server.homelab-matrix.username ''${sec.data.${matrixSecureUsernameName}}'
    echo '/set matrix-rust.server.homelab-matrix.password ''${sec.data.${matrixSecurePasswordName}}'
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
      matrix_server_password = {
        path = secretPaths.matrixPassword;
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
