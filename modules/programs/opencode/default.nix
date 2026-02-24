# Aspect: programs-opencode
# Defines jvf.programs.opencode options for OpenCode AI coding tool.
# NixOS: FHS environment wrapper for glibc compatibility + config via wrappers.
# Darwin: direct execution + config via wrappers.
{ ... }:
let
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
      cfg = config.jvf.programs.opencode;

      # Import wrapper definitions
      wrapperDefs = import ./_/wrapper.nix { inherit pkgs; };
      inherit (wrapperDefs) shellScriptBinLinux shellScriptBinDarwin;
    in
    {
      imports = [
        ./options.nix
        ./config/formatter.nix
        ./config/lsp.nix
        ./config/permission.nix
        ./config/provider.nix
        ./config/plugins.nix
      ];

      config = {
        # ── Default settings ──────────────────────────────────────────────
        jvf.programs.opencode.settings = {
          theme = lib.mkDefault "one-dark";
          mcp = lib.mkDefault cfg.mcps;
          disabled_providers = lib.mkDefault [
            "opencode"
            "copilot"
            "github-copilot-enterprise"
            "copilot-enterprise"
            "github-models"
            "minimax-cn"
          ];

          instructions = [
            ".docs/rules.md"
          ];

          tools = lib.mkDefault (
            builtins.listToAttrs (
              map (name: {
                name = "${name}*";
                value = false;
              }) (builtins.attrNames cfg.mcps)
            )
          );

          watcher = {
            ignore = [
              "node_modules/**"
              "dist/**"
              ".git/**"
              "build/**"
              ".bundle/**"
              "__pycache__/**"
              ".ck/**"
            ];
          };

          model = "zai-coding-plan/glm-4.7:fast";
          small_model = "copilot/grok-code-fast-1";
        };

        # ── Wrappers config ───────────────────────────────────────────
        jvf.wrappers.users.${cfg.username}.programs.opencode = {
          preserveFiles = [
            "antigravity-accounts.json"
            "node_modules"
            "dcp.jsonc"
            "package.json"
            "bun.lock"
          ];
          packages = [
            pkgs.bun
          ]
          ++ lib.optional isDarwin shellScriptBinDarwin
          ++ lib.optional (!isDarwin) shellScriptBinLinux;
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "agent" cfg.agents)
            (inputs.lib.aiTools.mkOpencodeMdConfigs config.jvf.aiTools.mcp "command" cfg.commands)
            (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
            {
              "AGENTS.md" = cfg.baseRules;
              "opencode.json" = cfg.settings;
              "oh-my-opencode.json" = cfg.ohMyOpenCodeSettings;
              "antigravity.json" = {
                account_selection_strategy = "round-robin";
                switch_on_first_rate_limit = true;
                pid_offset_enabled = true;
              };
              "toolbox.jsonc" = {
                mcp = cfg.mcps;
              };
              "toolbox.json" = {
                mcp = cfg.mcps;
              };
            }
          ];
        };
      };
    };
in
{
  flake.modules.nixos.programs-opencode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-opencode = mkConfig { isDarwin = true; };
}
