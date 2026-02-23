# Aspect: ai-tools-mcp
# Consolidates all MCP server configurations for AI tools.
# Each server is individually toggleable via jvf.aiTools.mcp.<name>.enable.
# Legacy status preserved: most servers default-disabled (were commented out),
# only zai-mcp-server defaults to enabled.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.aiTools.mcpServers = {
        enableAll = lib.mkEnableOption "all MCP servers";
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      mkMcpModule = inputs.lib.aiTools.mkMcpModule;

      # --- playwriter ---
      playwriterDef = mkMcpModule {
        name = "playwriter";
        tags = [ ];
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [
              (lib.getExe' pkgs.nodejs "npx")
              "playwriter@latest"
            ];
          };
          claudecode = {
            type = "stdio";
            command = (lib.getExe' pkgs.nodejs "npx");
            args = [
              "playwriter@latest"
            ];
          };
        };
      };

      # --- context7 ---
      context7Def = mkMcpModule {
        name = "context7";
        tags = [ "documentation" ];
        mcpOptions = {
          opencode = {
            enabled = true;
            type = "local";
            command = [
              "npx"
              "-y"
              "@upstash/context7-mcp"
              "--api-key"
              "{env:CONTEXT7_API_KEY}"
            ];
          };
          claudecode = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@upstash/context7-mcp"
              "--api-key"
              "{env:CONTEXT7_API_KEY}"
            ];
          };
          droid = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@upstash/context7-mcp"
              "--api-key"
              "{env:CONTEXT7_API_KEY}"
            ];
          };
        };
      };

      # --- chrome-devtools ---
      npx = lib.getExe' pkgs.nodejs "npx";
      defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
      chromeDevtoolsDef = mkMcpModule {
        name = "chrome-devtools";
        tags = [ "browser" ];
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [
              npx
              "-y"
              "chrome-devtools-mcp@latest"
              "--headless=true"
              "--isolated=true"
              "--executablePath=${defaultBrowser}"
            ];
          };
          claudecode = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "chrome-devtools-mcp@latest"
              "--headless=true"
              "--isolated=true"
              "--executablePath=${defaultBrowser}"
            ];
          };
          droid = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "chrome-devtools-mcp@latest"
              "--headless=true"
              "--isolated=true"
              "--executablePath=${defaultBrowser}"
            ];
          };
        };
      };

      # --- shadcn ---
      shadcnDef = mkMcpModule {
        name = "shadcn";
        tags = [ "frontend" ];
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [
              "${pkgs.bun}/bin/bunx"
              "--bun"
              "shadcn@latest"
              "mcp"
            ];
          };
          claudecode = {
            type = "stdio";
            command = "${pkgs.bun}/bin/bunx";
            args = [
              "--bun"
              "shadcn@latest"
              "mcp"
            ];
          };
        };
      };

      # --- zai-mcp-server ---
      zaiMcpServerDef = mkMcpModule {
        name = "zai-mcp-server";
        tags = [ "explorer" ];
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [
              "${lib.getExe' pkgs.nodejs "npx"}"
              "-y"
              "@z_ai/mcp-server"
            ];
            environment = {
              "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
              "Z_AI_MODE" = "ZAI";
            };
          };
          claudecode = {
            type = "stdio";
            command = "${lib.getExe' pkgs.nodejs "npx"}";
            args = [
              "-y"
              "@z_ai/mcp-server"
            ];
            env = {
              "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
              "Z_AI_MODE" = "ZAI";
            };
          };
          droid = {
            type = "stdio";
            command = "${lib.getExe' pkgs.nodejs "npx"}";
            args = [
              "-y"
              "@z_ai/mcp-server"
            ];
            env = {
              "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
              "Z_AI_MODE" = "ZAI";
            };
          };
        };
      };

      # --- web-reader ---
      webReaderDef = mkMcpModule {
        name = "web-reader";
        tags = [ "explorer" ];
        mcpOptions = {
          opencode = {
            type = "remote";
            enabled = true;
            url = "https://api.z.ai/api/mcp/web_reader/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          claudecode = {
            type = "http";
            url = "https://api.z.ai/api/mcp/web_reader/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          droid = {
            type = "http";
            url = "https://api.z.ai/api/mcp/web_reader/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
        };
      };

      # --- web-search-prime ---
      webSearchPrimeDef = mkMcpModule {
        name = "web-search-prime";
        tags = [ "explorer" ];
        mcpOptions = {
          opencode = {
            type = "remote";
            enabled = true;
            url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          claudecode = {
            type = "http";
            url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          droid = {
            type = "http";
            url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
        };
      };

      # --- zread ---
      zreadDef = mkMcpModule {
        name = "zread";
        tags = [ "explorer" ];
        mcpOptions = {
          opencode = {
            type = "remote";
            enabled = true;
            url = "https://api.z.ai/api/mcp/zread/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          claudecode = {
            type = "http";
            url = "https://api.z.ai/api/mcp/zread/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
          droid = {
            type = "http";
            url = "https://api.z.ai/api/mcp/zread/mcp";
            headers = {
              Authorization = "Bearer {env:Z_AI_API_KEY}";
            };
          };
        };
      };

      # --- ck ---
      ckDef = mkMcpModule {
        name = "ck";
        tags = [ "explorer" ];
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [
              "${lib.getExe config.jvf.programs."ck-search".package}"
              "--serve"
            ];
          };
          claudecode = {
            type = "stdio";
            command = "${lib.getExe config.jvf.programs."ck-search".package}";
            args = [
              "--serve"
            ];
          };
          droid = {
            type = "stdio";
            command = "${lib.getExe config.jvf.programs."ck-search".package}";
            args = [
              "--serve"
            ];
          };
        };
      };

      # --- mcp-nixos (NixOS-only) ---
      mcpNixosDef = mkMcpModule {
        name = "mcp-nixos";
        tags = [ "nix" ];
        mcpNames = {
          opencode = "mcp-nixos";
          claudecode = "nixos-mcp";
        };
        mcpOptions = {
          opencode = {
            type = "local";
            enabled = true;
            command = [ (lib.getExe pkgs.mcp-nixos) ];
          };
          claudecode = {
            type = "stdio";
            enabled = true;
            command = lib.getExe pkgs.mcp-nixos;
          };
        };
      };

      cfg = config.jvf.aiTools.mcp;
    in
    {
      imports = [ mkOptions ];

      # Define all MCP server options
      options.jvf.aiTools.mcp = {
        playwriter = playwriterDef.options;
        context7 = context7Def.options;
        "chrome-devtools" = chromeDevtoolsDef.options;
        shadcn = shadcnDef.options;
        "zai-mcp-server" = zaiMcpServerDef.options;
        "web-reader" = webReaderDef.options;
        "web-search-prime" = webSearchPrimeDef.options;
        zread = zreadDef.options;
        ck = ckDef.options;
      }
      // lib.optionalAttrs (!isDarwin) {
        "mcp-nixos" = mcpNixosDef.options // {
          enable = mcpNixosDef.options.enable // {
            default = false;
          };
        };
      };

      config = lib.mkMerge (
        [
          # Individual server configs
          (lib.mkIf cfg.playwriter.enable playwriterDef.config)
          (lib.mkIf cfg.context7.enable context7Def.config)
          (lib.mkIf cfg."chrome-devtools".enable (
            chromeDevtoolsDef.config
            // {
              jvf.aiTools.skills."browser-debug-tools".mcp = {
                command = npx;
                args = [
                  "-y"
                  "chrome-devtools-mcp@latest"
                  "--headless=true"
                  "--isolated=true"
                  "--executablePath=${defaultBrowser}"
                ];
              };
            }
          ))
          (lib.mkIf cfg.shadcn.enable shadcnDef.config)
          (lib.mkIf cfg."zai-mcp-server".enable zaiMcpServerDef.config)
          (lib.mkIf cfg."web-reader".enable webReaderDef.config)
          (lib.mkIf cfg."web-search-prime".enable webSearchPrimeDef.config)
          (lib.mkIf cfg.zread.enable zreadDef.config)
          (lib.mkIf cfg.ck.enable ckDef.config)
        ]
        # mcp-nixos: NixOS-only
        ++ lib.optional (!isDarwin) (lib.mkIf cfg."mcp-nixos".enable mcpNixosDef.config)
      );
    };
in
{
  flake.modules.nixos.ai-tools-mcp = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-mcp = mkConfig { isDarwin = true; };
}
