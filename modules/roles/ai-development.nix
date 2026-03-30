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
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # Claude Code settings (permissions, default mode)
        jvf.programs.claudecode.settings = {
          permissions = {
            allow = [
              "Bash(cat:*)"
              "Bash(echo:*)"
              "Bash(ldd:*)"
              "Bash(bash:*)"
              "Bash(readlink:*)"
              "Bash(zsh:*)"
              "Bash(hash:*)"
              "Bash(set:*)"
              "Bash(git log:*)"
              "Bash(sudo nixos-rebuild switch:*)"
              "Bash(nix-instantiate:*)"
              "Bash(nix flake:*)"
              "Bash(nix --extra-experimental-features 'nix-command flakes' flake check)"
            ];
            deny = [ ];
            ask = [ ];
            defaultMode = "dontAsk";
          };
        };

        # Cursor integration with shared configs
        jvf.programs.cursor = {
          baseRules = config.jvf.aiTools.baseRule.content;
          inherit (config.jvf.programs.opencode) agents;
          inherit (config.jvf.programs.opencode) commands;
          inherit (config.jvf.programs.opencode) skills;
        };

        users.users."${cfg.username}".packages = [
          pkgs.code-cursor
          pkgs.cursor-cli
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
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # Claude Code settings (permissions, default mode)
        jvf.programs.claudecode.settings = {
          permissions = {
            allow = [
              "Bash(cat:*)"
              "Bash(echo:*)"
              "Bash(ldd:*)"
              "Bash(bash:*)"
              "Bash(readlink:*)"
              "Bash(zsh:*)"
              "Bash(hash:*)"
              "Bash(set:*)"
              "Bash(git log:*)"
              "Bash(sudo nixos-rebuild switch:*)"
              "Bash(nix-instantiate:*)"
              "Bash(nix flake:*)"
              "Bash(nix --extra-experimental-features 'nix-command flakes' flake check)"
            ];
            deny = [ ];
            ask = [ ];
            defaultMode = "dontAsk";
          };
        };

        # Cursor integration with shared configs
        jvf.programs.cursor = {
          baseRules = config.jvf.aiTools.baseRule.content;
          inherit (config.jvf.programs.opencode) agents;
          inherit (config.jvf.programs.opencode) commands;
          inherit (config.jvf.programs.opencode) skills;
        };

        users.users."${cfg.username}".packages = [
          pkgs.code-cursor
          pkgs.cursor-cli
        ];
      };
    };
in
{
  flake.modules.nixos.roles-ai-development = nixosModule;
  flake.modules.darwin.roles-ai-development = darwinModule;
}
