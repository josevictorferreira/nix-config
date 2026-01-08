{ config, lib, pkgs, system, ... }:

let
  cfg = config.jvf.programs.llm-proxy;
  isDarwin = builtins.match ".*-darwin" system != null;

  # Define the package
  llmProxyPkg = pkgs.python3.pkgs.buildPythonApplication {
    pname = "llm-proxy";
    version = "0.0.1";
    format = "other"; # No setup.py/pyproject.toml, manual install

    src = pkgs.fetchFromGitHub {
      owner = "Mirrowel";
      repo = "LLM-API-Key-Proxy";
      rev = "main";
      hash = "sha256-1r6d6nkycs3dli21dvbvi2gfad39gnspsjx952myw8skkav2jw2j";
    };

    propagatedBuildInputs = with pkgs.python3.pkgs; [
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
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/llm-proxy
      cp -r src $out/share/llm-proxy/
      # Create a dummy requirements.txt if needed or copy it
      # cp requirements.txt $out/share/llm-proxy/ || true

      mkdir -p $out/bin
      
      # Create wrapper script
      cat > $out/bin/llm-proxy <<EOF
      #!/bin/sh
      export PYTHONPATH=$PYTHONPATH:$out/share/llm-proxy
      exec ${pkgs.python3}/bin/python -m uvicorn src.proxy_app.main:app --app-dir $out/share/llm-proxy --host 0.0.0.0 --port \''${LLM_PROXY_PORT:-18000} "\$@"
      EOF
      
      chmod +x $out/bin/llm-proxy

      runHook postInstall
    '';

    meta = {
      description = "LLM API Key Proxy";
      homepage = "https://github.com/Mirrowel/LLM-API-Key-Proxy";
      platforms = lib.platforms.all;
    };
  };

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

  config = lib.mkIf cfg.enable {
    # NixOS Service
    systemd.services.llm-proxy = lib.mkIf (!isDarwin) {
      description = "LLM API Key Proxy Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --port ${toString cfg.port}";
        Restart = "always";
        Type = "simple";
      };
    };

    # Darwin Service
    launchd.agents.llm-proxy = lib.mkIf isDarwin {
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
        WorkingDirectory = "/tmp"; # Run somewhere safe
      };
    };
  };
}
