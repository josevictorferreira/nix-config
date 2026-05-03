_:
let
  mkForgeCodeOptions =
    { config, lib, ... }:
    {
      options.jvf.programs.forgecode = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          description = "The forgecode package to install.";
        };
      };
    };

  forgeCodeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.forgecode;

      forgeCodePkg = pkgs.rustPlatform.buildRustPackage rec {
        pname = "forgecode";
        version = "0.1.0-dev";

        src = pkgs.fetchFromGitHub {
          owner = "tailcallhq";
          repo = "forgecode";
          rev = "82ae187a3c3a2703e0c408605c20f3aca3368291";
          hash = "sha256-YqMq/Z65v83pDrYmH7K7RD5HLfexziTJ1AKBukNubDA=";
        };

        cargoHash = "sha256-lWXYGlEkE6OXygKwdjmx4MRymXRc6P0PmIg/sk1W4Fw=";

        cargoBuildFlags = [
          "-p"
          "forge_main"
          "--bin"
          "forge"
        ];

        nativeBuildInputs = with pkgs; [
          cmake
          nasm
          perl
          pkg-config
          protobuf
        ];

        buildInputs =
          with pkgs;
          [
            sqlite
          ]
          ++ lib.optionals stdenv.isLinux [
            libxkbcommon
            libx11
            libxext
            libxfixes
            libxcb
            wayland
          ]
          ++ lib.optionals stdenv.isDarwin [
            libiconv
          ];

        PROTOC = "${pkgs.protobuf}/bin/protoc";
        PROTOC_INCLUDE = "${pkgs.protobuf}/include";
        APP_VERSION = version;

        postInstall = ''
          mkdir -p $out/share/zsh/plugins/forgecode
          cp -r shell-plugin/* $out/share/zsh/plugins/forgecode/
        '';

        doCheck = false;

        meta = with lib; {
          description = "forge: AI enabled pair programmer for Claude, GPT, O Series, Grok, Deepseek, Gemini and 300+ models";
          homepage = "https://forgecode.dev";
          license = licenses.mit;
          mainProgram = "forge";
          platforms = platforms.unix;
        };
      };
    in
    {
      imports = [ mkForgeCodeOptions ];

      config = {
        jvf.programs.forgecode.package = lib.mkDefault forgeCodePkg;

        users.users."${cfg.username}".packages = [
          (lib.mkDefault forgeCodePkg)
          pkgs.fzf
          pkgs.bat
          pkgs.fd
        ];

        # Zsh plugin integration
        programs.zsh.interactiveShellInit = lib.mkAfter ''
          # ForgeCode Zsh Plugin
          if [ -f ${forgeCodePkg}/share/zsh/plugins/forgecode/forge.plugin.zsh ]; then
            source ${forgeCodePkg}/share/zsh/plugins/forgecode/forge.plugin.zsh
          fi
        '';
      };
    };
in
{
  flake.modules.nixos.programs-forgecode = forgeCodeModule;
  flake.modules.darwin.programs-forgecode = forgeCodeModule;
}
