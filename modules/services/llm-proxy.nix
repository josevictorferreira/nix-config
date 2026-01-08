{ config, lib, pkgs, system, ... }:

let
  cfg = config.jvf.services.llm-proxy;
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
    colorlog
    litellm
    filelock
    aiohttp
  ]);

  # Define source
  src = pkgs.fetchFromGitHub {
    owner = "Mirrowel";
    repo = "LLM-API-Key-Proxy";
    rev = "main";
    hash =
      if isDarwin
      then "sha256-1r6d6nkycs3dli21dvbvi2gfad39gnspsjx952myw8skkav2jw2j"
      else "sha256-LUy/Et3Ew87eVCNygyMh+zsUU12k3cNDWo3jMgN+YEY=";
  };

  # Define the package using writeShellScriptBin
  stateDir = "/var/lib/llm-proxy";
  llmProxyPkg = pkgs.writeShellScriptBin "llm-proxy" ''
    # Create state directory structure
    mkdir -p ${stateDir}/{logs,oauth_creds}
    
    # Link source files to state directory
    for item in ${src}/*; do
      name=$(basename "$item")
      if [ ! -e "${stateDir}/$name" ]; then
        ln -sf "$item" "${stateDir}/$name"
      fi
    done
    
    cd ${stateDir}
    exec ${pythonEnv}/bin/uvicorn src.proxy_app.main:app --host 0.0.0.0 "$@"
  '';

in
{
  options.jvf.services.llm-proxy = {
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
          StateDirectory = "llm-proxy";
          WorkingDirectory = "/var/lib/llm-proxy";
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
