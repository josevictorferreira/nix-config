# Aspect: programs-opencode
# Defines jvf.programs.opencode options for OpenCode AI coding tool.
# NixOS: FHS environment wrapper for glibc compatibility + config via wrappers.
# Darwin: direct execution + config via wrappers.
_:
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
          theme = lib.mkDefault "tokyonight";
          mcp = lib.mkDefault (
            lib.mapAttrs (name: mcpCfg: inputs.lib.aiTools.transformMcpOptions "opencode" mcpCfg) cfg.mcps
          );
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

          watcher = {
            ignore = [
              "node_modules/**"
              "dist/**"
              ".git/**"
              "build/**"
              ".bundle/**"
              "__pycache__/**"
              ".ck/**"
              ".bun_cache/**"
            ];
          };

          small_model = "alibaba-coding-plan/qwen3-coder-next";
        };

        # ── Wrappers config ───────────────────────────────────────────
        jvf.wrappers.users.${cfg.username}.programs.opencode = {
          preserveFiles = [
            "dcp.jsonc"
          ];
          packages = [
            pkgs.bun
          ]
          ++ lib.optional isDarwin shellScriptBinDarwin
          ++ lib.optional (!isDarwin) shellScriptBinLinux;
          configs = lib.mkMerge [
            (inputs.lib.aiTools.mkOpencodeMdConfigs "agent" cfg.agents)
            (inputs.lib.aiTools.mkOpencodeMdConfigs "command" cfg.commands)
            (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
            {
              "AGENTS.md" = cfg.baseRules;
              "opencode.json" = cfg.settings;
              "oh-my-opencode.json" = cfg.ohMyOpenCodeSettings;
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
