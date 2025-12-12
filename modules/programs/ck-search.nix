{
  lib,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs."ck-search";
  rust_overlay = import (
    builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"
  );
  pkgs = import <nixpkgs> { overlays = [ rust_overlay ]; };
  rustVersion = "1.88.0";
  rust = pkgs.rust-bin.stable.${rustVersion}.default;
  rustPlatform = pkgs.makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };
  ckSearchPkg = rustPlatform.buildRustPackage rec {
    pname = "ck-search";
    version = "0.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "BeaconBay";
      repo = "ck";
      rev = version;
      hash = "sha256-qUzrKbv5OTmXyIb3N67c4R/49eYkegp/5RbqUSq/ixg=";
    };

    cargoHash = "sha256-0fKfGis3h8sMs1lXWStEXpnLA/hUo5NTeL2KcU96qfg=";

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
      onnxruntime
    ];

    buildAndTestSubdir = "ck-cli";

    cargoBuildFlags = [
      "--features"
      "vendored-openssl"
    ];

    preBuild = ''
      export ORT_SKIP_DOWNLOAD=1
      export ORT_DOWNLOAD_DISABLED=1
    '';

    doCheck = false;

    meta = with lib; {
      description = "Semantic grep by embedding - find code by meaning, not just keywords";
      homepage = "https://github.com/BeaconBay/ck";
      license = with licenses; [
        mit
        asl20
      ];
      mainProgram = "ck";
      platforms = platforms.all;
    };
  };
in
{
  options.jvf.programs."ck-search" = {
    enable = lib.mkEnableOption "Enable CK Search tool";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [
      ckSearchPkg
    ];
  };
}
