# Aspect: roles-ai-development
# Bundles AI/LLM development tools and vibe coding assistants.
# Imports AI-related program aspects and installs user-level AI packages.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.ai-development = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    { config
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.roles.ai-development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-lsp-mcp
        programs-opencode
        programs-claudecode
        programs-rtk
        programs-gemini
        programs-hermes-agent
        programs-forgecode
        programs-pi
        programs-vix
        programs-crush
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # AI Tools enables
        jvf.aiTools.mcp.chrome-devtools.enable = true;
        jvf.aiTools.mcp.jira.enable = true;
        jvf.aiTools.mcp.grafana.enable = false;

        jvf.aiTools.mcp.grafanaWork.enable = false;

        # Pi extension: hindsight_recall / hindsight_retain tools (Hindsight
        # long-term memory API), sourced from the my-pi-agent-plugins repo
        # (flake input, pinned in flake.lock). Pi's only extra tools: the
        # pi-mcp-adapter bridge, its MCP servers, and the web_search /
        # web_fetch extensions were all removed.
        jvf.programs.pi.extensionDirs.hindsight = "${inputs.pi-plugins}/extensions/hindsight";

        # Claude Code settings (YOLO mode — bypass all permission prompts)
        jvf.programs.claudecode.settings = {
          permissions = {
            defaultMode = "bypassPermissions";
          };
          attribution = {
            commit = "";
            pr = "";
          };
        };

        users.users."${cfg.username}".packages = [
          pkgs.pi-coding-agent
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , inputs
    , ...
    }:
    let
      cfg = config.jvf.roles.ai-development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-lsp-mcp
        programs-opencode
        programs-claudecode
        programs-rtk
        programs-gemini
        programs-hermes-agent
        programs-forgecode
        programs-pi
        programs-vix
        programs-crush
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # AI Tools enables
        jvf.aiTools.mcp.chrome-devtools.enable = true;
        jvf.aiTools.mcp.jira.enable = true;
        jvf.aiTools.mcp.grafana.enable = false;

        jvf.aiTools.mcp.grafanaWork.enable = false;

        # Pi extension: hindsight_recall / hindsight_retain tools (Hindsight
        # long-term memory API), sourced from the my-pi-agent-plugins repo
        # (flake input, pinned in flake.lock). Pi's only extra tools: the
        # pi-mcp-adapter bridge, its MCP servers, and the web_search /
        # web_fetch extensions were all removed.
        jvf.programs.pi.extensionDirs.hindsight = "${inputs.pi-plugins}/extensions/hindsight";

        # Claude Code settings (YOLO mode — bypass all permission prompts)
        jvf.programs.claudecode.settings = {
          permissions = {
            defaultMode = "bypassPermissions";
          };
          attribution = {
            commit = "";
            pr = "";
          };
        };

        users.users."${cfg.username}".packages = [
          pkgs.pi-coding-agent
        ];
      };
    };
in
{
  flake.modules.nixos.roles-ai-development = nixosModule;
  flake.modules.darwin.roles-ai-development = darwinModule;
}
