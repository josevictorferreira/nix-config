# Aspect: services-llm-proxy
# LLM API Key Proxy service with sops secrets integration.
# NixOS: systemd service with StateDirectory.
# Darwin: launchd agent with KeepAlive.
{ ... }:
let
  mkLlmProxyOptions =
    { lib, ... }:
    {
      options.jvf.services.llm-proxy = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 18000;
          description = "Port to run the proxy on.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          description = "The llm-proxy package to use.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.services.llm-proxy;

      # Define the python environment
      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
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
        ]
      );

      # Define source
      src = pkgs.fetchFromGitHub {
        owner = "Mirrowel";
        repo = "LLM-API-Key-Proxy";
        rev = "main";
        hash =
          if isDarwin then
            "sha256-1r6d6nkycs3dli21dvbvi2gfad39gnspsjx952myw8skkav2jw2j"
          else
            "sha256-iGWTTCZMpAM8bHXGrq5lmNZzzzy6cAoz6Q7JXVrg/5Y=";
      };

      # State directory for writable files
      stateDir = "/var/lib/llm-proxy";

      # Define the package using writeShellScriptBin
      llmProxyPkg = pkgs.writeShellScriptBin "llm-proxy" ''
        set -euo pipefail

        # Create state directory structure
        mkdir -p ${stateDir}/{logs,oauth_creds}

        # Link source files to state directory
        for item in ${src}/*; do
          name=$(basename "$item")
          if [ ! -e "${stateDir}/$name" ]; then
            ln -sf "$item" "${stateDir}/$name"
          fi
        done

        # Wait up to 5 seconds for proxy key to appear (sops activation)
        for i in {1..5}; do
          [ -f /run/secrets/llm_proxy_api_key ] && break
          sleep 1
        done

        # Generate .env file from sops secrets
        {
          # Proxy Auth
          if [ -f /run/secrets/llm_proxy_api_key ]; then
            echo "PROXY_API_KEY=\"$(cat /run/secrets/llm_proxy_api_key)\""
          fi
          echo "SKIP_OAUTH_INIT_CHECK=true"
          echo ""

          # Gemini
          if [ -f /run/secrets/gemini_api_key ]; then
            echo "GEMINI_1_API_KEY=\"$(cat /run/secrets/gemini_api_key)\""
          fi
          echo ""

          # OpenRouter
          if [ -f /run/secrets/openrouter_api_key_code_agent ]; then
            echo "OPENROUTER_1_API_KEY=\"$(cat /run/secrets/openrouter_api_key_code_agent)\""
          fi
          echo ""

          # Minimax
          if [ -f /run/secrets/minimax_api_key ]; then
            echo "MINIMAX_API_BASE=\"https://api.minimax.io/v1\""
            echo "MINIMAX_1_API_KEY=\"$(cat /run/secrets/minimax_api_key)\""
            echo "MINIMAX_MODELS='[\"MiniMax-M2.1\",\"MiniMax-M2.1-lightning\",\"MiniMax-M2\",\"abab6.5s-chat\",\"abab6.5-chat\",\"video-01\"]'"
          fi
          echo ""

          # Z-AI (Zhipu AI)
          if [ -f /run/secrets/z_ai_api_key ]; then
            echo "ZAI_API_BASE=\"https://open.bigmodel.cn/api/paas/v4/\""
            echo "ZAI_1_API_KEY=\"$(cat /run/secrets/z_ai_api_key)\""
            echo "ZAI_MODELS='[\"glm-4.7\",\"glm-4.6\",\"glm-4.5-air\",\"glm-4\",\"glm-4-air\",\"glm-4-flash\",\"glm-4v\",\"glm-4v-plus\"]'"
          fi
          echo ""

          # Antigravity
          # Numbered format: ANTIGRAVITY_N_ACCESS_TOKEN and ANTIGRAVITY_N_REFRESH_TOKEN are both required for discovery
          if [ -f /run/secrets/antigravity_account_1_refresh_token ]; then
            echo "ANTIGRAVITY_1_ACCESS_TOKEN=\"dummy\""
            echo "ANTIGRAVITY_1_REFRESH_TOKEN=\"$(cat /run/secrets/antigravity_account_1_refresh_token)\""
            echo "ANTIGRAVITY_1_EMAIL=\"$(cat /run/secrets/antigravity_account_1_email)\""
          fi
          if [ -f /run/secrets/antigravity_account_2_refresh_token ]; then
            echo "ANTIGRAVITY_2_ACCESS_TOKEN=\"dummy\""
            echo "ANTIGRAVITY_2_REFRESH_TOKEN=\"$(cat /run/secrets/antigravity_account_2_refresh_token)\""
            echo "ANTIGRAVITY_2_EMAIL=\"$(cat /run/secrets/antigravity_account_2_email)\""
          fi
          echo "ANTIGRAVITY_DYNAMIC_MODELS=true"
          echo "ANTIGRAVITY_ENABLE_EXPERIMENTS=true"
          echo "ROTATION_MODE_ANTIGRAVITY=sequential"
          echo "MAX_CONCURRENT_REQUESTS_PER_KEY_ANTIGRAVITY=1"
        } > ${stateDir}/.env.tmp

        mv ${stateDir}/.env.tmp ${stateDir}/.env
        chmod 600 ${stateDir}/.env

        cd ${stateDir}
        exec ${pythonEnv}/bin/uvicorn src.proxy_app.main:app --host 0.0.0.0 "$@"
      '';
    in
    {
      imports = [ mkLlmProxyOptions ];

      config = (
        lib.mkMerge [
          # Default package
          {
            jvf.services.llm-proxy.package = lib.mkDefault llmProxyPkg;
          }

          # Sops secrets declarations
          {
            sops.secrets = {
              gemini_api_key = {
                mode = "0400";
              };
              openrouter_api_key_code_agent = {
                mode = "0400";
              };
              minimax_api_key = {
                mode = "0400";
              };
              z_ai_api_key = {
                mode = "0400";
              };
              antigravity_account_1_refresh_token = {
                mode = "0400";
              };
              antigravity_account_1_email = {
                mode = "0400";
              };
              antigravity_account_2_refresh_token = {
                mode = "0400";
              };
              antigravity_account_2_email = {
                mode = "0400";
              };
            };
          }

          # NixOS Service
          (lib.optionalAttrs (!isDarwin) {
            systemd.services.llm-proxy = {
              description = "LLM API Key Proxy Service";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              wants = [ "network-online.target" ];
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
        ]
      );
    };
in
{
  flake.modules.nixos.services-llm-proxy = mkConfig { isDarwin = false; };
  flake.modules.darwin.services-llm-proxy = mkConfig { isDarwin = true; };
}
