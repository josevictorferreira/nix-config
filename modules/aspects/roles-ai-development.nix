# Aspect: roles-ai-development
# Bundles AI/LLM development tools and vibe coding assistants.
# Enables AI-related program aspects and installs user-level AI packages.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.ai-development = {
        enable = lib.mkEnableOption "AI development tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for installing packages to.";
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
      cfg = config.jvf.roles.ai-development;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        # Enable AI program aspects
        jvf.programs = {
          "ck-search".enable = true;
          opencode.enable = true;
          claudecode.enable = true;
          cursor.enable = true;
          droid.enable = true;
          gemini = {
            enable = true;
            antigravity.enable = true;
          };
        };

        # LLM proxy disabled by default
        jvf.services.llm-proxy.enable = false;

        # Cursor integration with shared configs
        jvf.programs.cursor = {
          baseRules = config.jvf.aiTools.baseRule.content;
          agents = config.jvf.programs.opencode.agents;
          commands = config.jvf.programs.opencode.commands;
          skills = config.jvf.programs.opencode.skills;
          mcps = config.jvf.programs.claudecode.mcps;
        };

        users.users."${cfg.username}".packages = [
          pkgs.code-cursor
          pkgs.cursor-cli
          pkgs.goose-cli
        ];
      };
    };
in
{
  flake.modules.nixos.roles-ai-development = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-ai-development = mkConfig { isDarwin = true; };
}
