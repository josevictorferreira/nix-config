{ ... }:
let
  mkMistralVibeOptions =
    { config, lib, ... }:
    {
      options.jvf.programs.mistral-vibe = {
        enable = lib.mkEnableOption "Enable mistral vibe program";
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username to install the program";
        };
      };
    };

  mistralVibeModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.mistral-vibe;

      textual-speedups = pkgs.python3.pkgs.buildPythonPackage rec {
        pname = "textual-speedups";
        version = "0.2.1";
        pyproject = true;

        src = pkgs.fetchPypi {
          pname = "textual_speedups";
          inherit version;
          hash = "sha256-cs8Pe97t4BU2e1m3C89yS6LDCAqGQevF65SzatFTaCQ=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          name = "${pname}-${version}";
          hash = "sha256-Bz4ocEziOlOX4z5F9EDry99YofeGyxL/6OTIf/WEgK4=";
        };

        nativeBuildInputs = [
          pkgs.rustPlatform.cargoSetupHook
          pkgs.rustPlatform.maturinBuildHook
          pkgs.cargo
          pkgs.rustc
          pkgs.maturin
        ];

        pythonImportsCheck = [ "textual_speedups" ];

        meta = with lib; {
          description = "Optional Rust speedups for Textual TUI framework";
          homepage = "https://github.com/willmcgugan/textual-speedups";
          license = licenses.mit;
          sourceProvenance = with sourceTypes; [ fromSource ];
          platforms = platforms.all;
        };
      };

      python = pkgs.python3.override {
        self = python;
        packageOverrides = _final: _prev: { };
      };

      mistralVibePkg = python.pkgs.buildPythonApplication rec {
        pname = "mistral-vibe";
        version = "1.3.2";
        pyproject = true;

        src = pkgs.fetchFromGitHub {
          owner = "mistralai";
          repo = "mistral-vibe";
          rev = "v${version}";
          hash = "sha256-K3S1F6tnvni3W5n8ukd/3s+yiReRRJ/0RBanbkIw1UU=";
        };

        build-system = with python.pkgs; [
          hatchling
          hatch-vcs
        ];

        dependencies = with python.pkgs; [
          aiofiles
          httpx
          mcp
          packaging
          pexpect
          pydantic
          pydantic-settings
          pyperclip
          pytest-xdist
          python-dotenv
          rich
          textual
          textual-speedups
          tomli-w
          watchfiles
        ];

        pythonRelaxDeps = [
          "pydantic"
          "pydantic-settings"
          "watchfiles"
        ];

        pythonImportsCheck = [ "vibe" ];

        meta = with lib; {
          description = "Minimal CLI coding agent by Mistral AI - open-source command-line coding assistant powered by Devstral";
          homepage = "https://github.com/mistralai/mistral-vibe";
          license = licenses.asl20;
          sourceProvenance = with sourceTypes; [ fromSource ];
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
          mainProgram = "vibe";
        };
      };
    in
    {
      imports = [ mkMistralVibeOptions ];

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.mistral-vibe = {
          packages = [
            mistralVibePkg
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-mistral-vibe = mistralVibeModule;
  flake.modules.darwin.programs-mistral-vibe = mistralVibeModule;
}
