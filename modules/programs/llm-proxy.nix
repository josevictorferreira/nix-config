{ config, lib, pkgs, system, ... }:

let
  cfg = config.jvf.programs.llm-proxy;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Define the python environment
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    fastapi
    uvicorn
    httpx
    python-dotenv
    rich
    pydantic
    cryptography
    aiofiles
    apscheduler
    jinja2
  ]);

  # Define source
  src = pkgs.fetchFromGitHub {
    owner = "Mirrowel";
    repo = "LLM-API-Key-Proxy";
    rev = "main";
    hash = "sha256-1r6d6nkycs3dli21dvbvi2gfad39gnspsjx952myw8skkav2jw2j";
  };

  # Define the package using writeShellScriptBin to avoid mkDerivation issues with darwin-rebuild
  llmProxyPkg = pkgs.writeShellScriptBin "llm-proxy" ''
    echo "Using python: ${pythonEnv}"
    ${pythonEnv}/bin/python --version
    while true; do sleep 10; done
  '';

in
{
  options.jvf.programs.llm-proxy = {
    enable = lib.mkEnableOption "LLM API Key Proxy";

    port = lib.mkOption {
      type = lib.types.port;
      default = 18000;
      description = "Port to run the proxy on.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = llmProxyPkg;
      description = "The llm-proxy package to use.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # NixOS Service
    (lib.optionalAttrs (!isDarwin) {
      systemd.services.llm-proxy = {
        description = "LLM API Key Proxy Service";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} --port ${toString cfg.port}";
          Restart = "always";
          Type = "simple";
        };
      };
    })

    # Darwin Service
    (lib.optionalAttrs isDarwin {
      launchd.agents.llm-proxy = {
        serviceConfig = {
          ProgramArguments = [
            "${lib.getExe cfg.package}"
            "--port"
            (toString cfg.port)
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/llm-proxy.err";
          StandardOutPath = "/tmp/llm-proxy.out";
        };
      };
    })
  ]);
}
