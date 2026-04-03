# Aspect: ai-tools-mcp
# Consolidates all MCP server configurations for AI tools.
# Each server is individually toggleable via jvf.aiTools.mcp.<name>.enable.
# Legacy status preserved: most servers default-disabled (were commented out),
# only zai-mcp-server defaults to enabled.
_:
let
  mkOptions = _: { };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      inherit (inputs.lib.aiTools) mkMcpModule;

      # Grafana MCP reads GRAFANA_*; zsh only exports GRAFANA_WORK_* from /run/secrets.
      # Cursor MCP is spawned by the GUI — no zsh shellInit — so read secrets here too.
      grafanaWorkSecret = key: ''"$(_grafanaSecret /run/secrets/${key})"'';
      grafanaMcpWrapper = pkgs.writeShellScript "mcp-grafana-wrapper" ''
        _grafanaSecret() {
          [ -r "$1" ] && ${lib.getExe' pkgs.coreutils "cat"} "$1" || true
        }
        export GRAFANA_URL=''${GRAFANA_URL:-''${GRAFANA_WORK_URL:-${grafanaWorkSecret "grafana_work_url"}}}
        export GRAFANA_SERVICE_ACCOUNT_TOKEN=''${GRAFANA_SERVICE_ACCOUNT_TOKEN:-''${GRAFANA_WORK_SERVICE_ACCOUNT_TOKEN:-${grafanaWorkSecret "grafana_work_service_account_token"}}}
        export GRAFANA_USERNAME=''${GRAFANA_USERNAME:-''${GRAFANA_WORK_USERNAME:-${grafanaWorkSecret "grafana_work_username"}}}
        export GRAFANA_PASSWORD=''${GRAFANA_PASSWORD:-''${GRAFANA_WORK_PASSWORD:-${grafanaWorkSecret "grafana_work_password"}}}
        export GRAFANA_ORG_ID=''${GRAFANA_ORG_ID:-1}
        exec ${lib.getExe pkgs.mcp-grafana} "$@"
      '';

      # --- context7 ---
      # All npx-based MCPs use wrapper scripts that pin PATH to their own Node,
      # preventing nix develop shells from injecting a different Node version.
      npx = lib.getExe' pkgs.nodejs "npx";
      nodeBin = lib.getBin pkgs.nodejs + "/bin";
      defaultBrowser = lib.getExe pkgs.brave;

      context7Def = mkMcpModule {
        name = "context7";
        programs = [ "cursor" "claudecode" ];
        mcpOptions = {
          enabled = true;
          type = "local";
          command = pkgs.writeShellScript "mcp-context7-wrapper" ''
            export PATH="${nodeBin}:$PATH"
            exec ${npx} -y @upstash/context7-mcp --api-key "''${CONTEXT7_API_KEY}" "$@"
          '';
          args = [ ];
        };
      };

      # --- chrome-devtools ---
      chromeDevtoolsDef = mkMcpModule {
        name = "chrome-devtools";
        programs = [ "claudecode" ];
        mcpOptions = {
          type = "local";
          enabled = true;
          command = pkgs.writeShellScript "mcp-chrome-devtools-wrapper" ''
            export PATH="${nodeBin}:$PATH"
            exec ${npx} -y chrome-devtools-mcp@latest \
              --headless=true \
              --isolated=true \
              --executablePath=${defaultBrowser} \
              "$@"
          '';
          args = [ ];
        };
      };

      # --- playwriter ---
      playwriterDef = mkMcpModule {
        name = "playwriter";
        programs = [ "claudecode" ];
        mcpOptions = {
          type = "local";
          enabled = true;
          command = pkgs.writeShellScript "mcp-playwriter-wrapper" ''
            export PATH="${nodeBin}:$PATH"
            exec ${npx} -y playwriter@latest "$@"
          '';
          args = [ ];
        };
      };

      # --- grafana ---
      grafanaDef = mkMcpModule {
        name = "grafana";
        programs = [ "opencode" ];
        mcpOptions = {
          type = "local";
          enabled = true;
          command = grafanaMcpWrapper;
          args = [ ];
        };
      };

      # --- grafana-work ---
      grafanaWorkDef = mkMcpModule {
        name = "grafana-work";
        programs = [
          "claudecode"
          "cursor"
        ];
        mcpOptions = {
          command = grafanaMcpWrapper;
          args = [ ];
          type = "local";
          enabled = true;
        };
      };

      cfg = config.jvf.aiTools.mcp;
    in
    {
      imports = [ mkOptions ];

      # Define all MCP server options
      options.jvf.aiTools.mcp = {
        context7 = context7Def.options;
        "chrome-devtools" = chromeDevtoolsDef.options;
        playwriter = playwriterDef.options;
        grafana = grafanaDef.options;
        grafanaWork = grafanaWorkDef.options;
      }
      // lib.optionalAttrs (!isDarwin) { };

      config = lib.mkMerge ([
        # Individual server configs
        (lib.mkIf cfg.context7.enable context7Def.config)
        (lib.mkIf cfg.grafana.enable grafanaDef.config)
        (lib.mkIf cfg.grafanaWork.enable grafanaWorkDef.config)
        (lib.mkIf cfg.playwriter.enable playwriterDef.config)
        (lib.mkIf cfg."chrome-devtools".enable chromeDevtoolsDef.config)
      ]);
    };
in
{
  flake.modules.nixos.ai-tools-mcp = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-mcp = mkConfig { isDarwin = true; };
}
