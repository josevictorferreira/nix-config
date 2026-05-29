# Aspect: programs-opencode
# Defines jvf.programs.opencode options for OpenCode AI coding tool.
# NixOS: FHS environment wrapper for glibc compatibility + package via wrappers + config via jvf.home.
# Darwin: direct execution + package via wrappers + config via jvf.home.
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
      wrapperDefs = import ./_/wrapper.nix {
        inherit pkgs;
        inherit (cfg) version;
      };
      inherit (wrapperDefs) shellScriptBinLinux shellScriptBinDarwin;

      # Build config directory as a derivation for jvf.home
      opencodeConfigs =
        (inputs.lib.aiTools.mkOpencodeMdConfigs "agent" cfg.agents)
        // (inputs.lib.aiTools.mkOpencodeMdConfigs "command" cfg.commands)
        // (inputs.lib.aiTools.mkSkillsConfigs cfg.skills)
        // {
          "AGENTS.md" = cfg.baseRules;
          "opencode.json" = cfg.settings;
          "oh-my-openagent.json" = cfg.ohMyOpenCodeSettings;
        }
        // cfg.extraConfigFiles;

      opencodeConfigDir = pkgs.linkFarm "opencode-config" (
        lib.mapAttrsToList (
          fileName: fileValue:
          let
            filePath =
              if lib.isDerivation fileValue then
                fileValue
              else if builtins.isString fileValue then
                pkgs.writeText "opencode-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" fileValue
              else if builtins.isAttrs fileValue then
                pkgs.writeText "opencode-${builtins.replaceStrings [ "/" ] [ "-" ] fileName}" (
                  inputs.lib.generators.toFileFormatStr (lib.last (lib.splitString "." fileName)) fileValue
                )
              else
                fileValue;
          in
          {
            name = fileName;
            path = filePath;
          }
        ) opencodeConfigs
      );
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
        # Default settings
        jvf.programs.opencode.settings = {
          theme = lib.mkDefault "tokyonight";
          mcp = lib.mkDefault (
            lib.mapAttrs (name: mcpCfg: inputs.lib.aiTools.transformMcpOptions "opencode" mcpCfg) cfg.mcps
          );
          instructions = [
            ".docs/rules.md"
          ];

          compaction = {
            prune = false;
            auto = true;
          };

          watcher = {
            ignore = [
              "dcp.jsonc"
              "dcp.json"
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

          small_model = "ninerouter/pippin";
          default_agent = "engineer";
        };

        # Config materialization via jvf.home
        jvf.home.users.${cfg.username}.items = {
          ".hindsight" = {
            kind = "dir";
            mode = "copy";
            source = pkgs.linkFarm "hindsight-config" [
              {
                name = "opencode.json";
                path = pkgs.writeText "hindsight-opencode.json" (
                  builtins.toJSON {
                    hindsightApiUrl = "https://hindsight-api.josevictor.me";
                    # Per-project memory isolation, shared with Claude Code.
                    # gitProject = basename of the main worktree root from
                    # `git rev-parse --git-common-dir`; falls back to cwd
                    # basename when not in a repo. Matches Claude Code's
                    # `project` field with resolveWorktrees=true.
                    dynamicBankId = true;
                    dynamicBankGranularity = [ "gitProject" ];
                    autoRecall = true;
                    autoRetain = true;
                    recallBudget = "mid";
                  }
                );
              }
              {
                name = "claude-code.json";
                path = pkgs.writeText "hindsight-claude-code.json" (
                  builtins.toJSON {
                    hindsightApiUrl = "https://hindsight-api.josevictor.me";
                    # Per-project memory isolation, shared with opencode.
                    # Claude Code's `project` field uses git-common-dir
                    # resolution when resolveWorktrees=true (the default),
                    # so it produces the same string as opencode's
                    # `gitProject` for any given repo.
                    dynamicBankId = true;
                    dynamicBankGranularity = [ "project" ];
                    resolveWorktrees = true;
                    autoRecall = true;
                    autoRetain = true;
                    recallBudget = "mid";
                    enableKnowledgeTools = true;
                    # Exclude tool_use / tool_result blocks from retained transcripts.
                    # retain.py defaults to True when key is absent; must set explicitly.
                    retainToolCalls = false;
                  }
                );
              }
            ];
            preserve = [ ];
          };
          ".config/opencode" = {
            kind = "dir";
            mode = "copy";
            source = opencodeConfigDir;
            preserve = [
              "dcp.jsonc"
              "dcp.json"
            ];
          };

          # Plugin-state sentinel: runs ONLY when the declared plugin list changes.
          # Performs a surgical cleanup of opencode's plugin runtime (node_modules,
          # lockfiles, plugin-wrapper binaries like `opencode.mcpflow-real`) while
          # preserving the main opencode binary so rebuilds don't force a 142 MB
          # re-download. Version bumps are handled separately by the wrapper,
          # which compares the declared version against ~/.opencode/.installed-version.
          ".cache/opencode-nix-state/plugins.json" = {
            kind = "file";
            mode = "copy";
            text = builtins.toJSON (cfg.settings.plugin or [ ]);
            postInstall = ''
              OPENCODE_HOME="$HOME_DIR/.opencode"
              if [ -d "$OPENCODE_HOME" ]; then
                echo "[opencode] Plugin list changed; clearing plugin state (keeping opencode binary)."
                rm -rf "$OPENCODE_HOME/node_modules" \
                       "$OPENCODE_HOME/package.json" \
                       "$OPENCODE_HOME/package-lock.json"
                # Remove plugin-installed wrapper binaries (e.g. opencode.mcpflow-real,
                # opencode.bak) but leave the main `opencode` binary in place.
                if [ -d "$OPENCODE_HOME/bin" ]; then
                  find "$OPENCODE_HOME/bin" -maxdepth 1 -type f \
                    -name 'opencode.*' -delete 2>/dev/null || true
                fi
              fi
              # Remove the obsolete combined sentinel from earlier iterations.
              rm -f "$HOME_DIR/.cache/opencode-nix-state/install.json"
            '';
          };
        };

        # Wrappers config (packages only)
        jvf.wrappers.users.${cfg.username}.programs.opencode = {
          packages = [
            pkgs.bun
          ]
          ++ lib.optional isDarwin shellScriptBinDarwin
          ++ lib.optional (!isDarwin) shellScriptBinLinux;
        };
      };
    };
in
{
  flake.modules.nixos.programs-opencode = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-opencode = mkConfig { isDarwin = true; };
}
