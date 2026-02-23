{ ... }:
let
  mkCkSearchOptions =
    { config, lib, ... }:
    {
      options.jvf.programs."ck-search" = {
        enable = lib.mkEnableOption "CK Search tool";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          description = "The ck-search package to install.";
        };
      };
    };

  mkCkSearchConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs."ck-search";

      ckSearchPkg = pkgs.rustPlatform.buildRustPackage rec {
        pname = "ck-search";
        version = "0.7.0";

        src = pkgs.fetchFromGitHub {
          owner = "BeaconBay";
          repo = "ck";
          rev = version;
          hash = "sha256-CZsayq1JxOhGaT9iTNVKcyqGGnJlxcjDAbcMKArtR6k=";
        };

        cargoHash = "sha256-+74XPcv/mnG7GAG6H8QJe6EtyO2xWhHXvdyTGSPwZeI=";

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
      imports = [ mkCkSearchOptions ];

      config = lib.mkIf cfg.enable {
        jvf.programs."ck-search".package = lib.mkDefault ckSearchPkg;

        users.users."${cfg.username}".packages = [
          (lib.mkDefault ckSearchPkg)
        ];
      };
    };
in
{
  flake.modules.nixos.programs-ck-search = mkCkSearchConfig { isDarwin = false; };
  flake.modules.darwin.programs-ck-search = mkCkSearchConfig { isDarwin = true; };
}
