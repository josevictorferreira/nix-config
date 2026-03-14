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
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (inputs.lib.aiTools) mkMcpModule;

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
      }
      // lib.optionalAttrs (!isDarwin) {
      };

      config = lib.mkMerge ([
        # Individual server configs
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
      ]);
    };
in
{
  flake.modules.nixos.ai-tools-mcp = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-mcp = mkConfig { isDarwin = true; };
}
