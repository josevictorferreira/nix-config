# Aspect: roles-ai-development
# Bundles AI/LLM development tools and vibe coding assistants.
# Imports AI-related program aspects and installs user-level AI packages.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  # Every extension directory in the my-pi-agent-plugins repo, pinned via the
  # pi-plugins flake input. Auto-discovered (pi auto-loads extensions/*/index.ts)
  # so adding a plugin upstream needs only `nix flake update pi-plugins` plus a
  # rebuild -- no edit here, and no drift between the nixos and darwin blocks.
  # Pure builtins: `lib` is not in scope at this level.
  piExtensionDirs =
    inputs:
    let
      root = "${inputs.pi-plugins}/extensions";
      entries = builtins.readDir root;
      names = builtins.filter (n: entries.${n} == "directory") (builtins.attrNames entries);
    in
    builtins.listToAttrs (map (n: { name = n; value = "${root}/${n}"; }) names);

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

        # Pi extensions, sourced from the my-pi-agent-plugins repo (flake input,
        # pinned in flake.lock): hindsight (long-term memory), context7 (library
        # docs), web-tools (web_search / web_fetch via Velox), codegraph
        # (semantic code search) and lsp (diagnostics after edit/write).
        # codegraph and lsp self-gate -- they register nothing without their
        # binaries. The pi-mcp-adapter bridge and its MCP servers stay removed.
        jvf.programs.pi.extensionDirs = piExtensionDirs inputs;

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

        # Pi extensions, sourced from the my-pi-agent-plugins repo (flake input,
        # pinned in flake.lock): hindsight (long-term memory), context7 (library
        # docs), web-tools (web_search / web_fetch via Velox), codegraph
        # (semantic code search) and lsp (diagnostics after edit/write).
        # codegraph and lsp self-gate -- they register nothing without their
        # binaries. The pi-mcp-adapter bridge and its MCP servers stay removed.
        jvf.programs.pi.extensionDirs = piExtensionDirs inputs;

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
