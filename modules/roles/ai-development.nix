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
        programs-ck-search
        programs-opencode
        programs-claudecode
        programs-cursor
        programs-droid
        programs-gemini
        services-llm-proxy
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

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

  darwinModule =
    { config
    , pkgs
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
        programs-ck-search
        programs-opencode
        programs-claudecode
        programs-cursor
        programs-droid
        programs-gemini
        services-llm-proxy
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

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
  flake.modules.nixos.roles-ai-development = nixosModule;
  flake.modules.darwin.roles-ai-development = darwinModule;
}
