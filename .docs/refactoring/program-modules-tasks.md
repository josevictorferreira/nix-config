

---

## Implementation Tasks

### Phase 1: Tier 1 - High Priority (Complex Modules)

#### Program: opencode (1103 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 1.1 | Create `options.nix` - Extract all option definitions (username, baseRules, agents, skills, commands, mcps, ohMyOpenCodeSettings, settings) | High | Medium | None |
| 1.2 | Create `wrapper.nix` - Extract FHS environment, wrapper script generation, and ohMyOpenCodePath | High | Medium | None |
| 1.3 | Create `config/formatter.nix` - Extract 6 formatter definitions (black, prettier, isort, etc) | Medium | Low | None |
| 1.4 | Create `config/lsp.nix` - Extract 15 LSP server configs (pyright, typescript, gopls, etc) | Medium | Low | None |
| 1.5 | Create `config/permission.nix` - Extract 50+ bash permission patterns | Medium | Low | None |
| 1.6 | Create `config/provider.nix` - Extract 5 providers with 30+ model configs | Medium | Low | None |
| 1.7 | Create `config/plugins.nix` - Extract plugin list definitions | Low | Low | None |
| 1.8 | Refactor `default.nix` - Import all submodules, maintain exports | High | Low | 1.1-1.7 |
| 1.9 | Verify nix flake check passes | High | Low | 1.8 |

#### Program: zsh (1023 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 2.1 | Create `options.nix` - Extract all option definitions (username, setAsDefaultShell, plugins, workspace, secrets) | High | Medium | None |
| 2.2 | Create `external-plugins.nix` - Extract 6 GitHub plugin fetches | Medium | Medium | None |
| 2.3 | Create `inline-plugins/ai-shell-assist.nix` - Extract AI shell assist functions | Low | Low | None |
| 2.4 | Create `inline-plugins/als.nix` - Extract alias listing functions | Low | Low | None |
| 2.5 | Create `inline-plugins/kubernetes.nix` - Extract kubectl helper functions | Low | Low | None |
| 2.6 | Create `inline-plugins/nix-utils.nix` - Extract nix utility functions | Low | Low | None |
| 2.7 | Create `inline-plugins/notes.nix` - Extract notes management functions | Low | Low | None |
| 2.8 | Create `inline-plugins/run-livebook.nix` - Extract livebook runner | Low | Low | None |
| 2.9 | Create `inline-plugins/todo.nix` - Extract todo management functions | Low | Low | None |
| 2.10 | Create `inline-plugins/base64.nix` - Extract base64 utilities | Low | Low | None |
| 2.11 | Create `inline-plugins/git-ai-commit.nix` - Extract git commit helper | Low | Low | None |
| 2.12 | Create `aliases/base.nix` - Extract base aliases | Low | Low | None |
| 2.13 | Create `aliases/navigation.nix` - Extract navigation aliases | Low | Low | None |
| 2.14 | Create `aliases/notes.nix` - Extract notes aliases | Low | Low | None |
| 2.15 | Create `aliases/dev.nix` - Extract development aliases | Low | Low | None |
| 2.16 | Create `aliases/projects.nix` - Extract project directory aliases | Low | Low | None |
| 2.17 | Create `aliases/k8s.nix` - Extract kubernetes aliases | Low | Low | None |
| 2.18 | Create `aliases/work.nix` - Extract work-specific aliases | Low | Low | None |
| 2.19 | Create `shell-init/environment.nix` - Extract environment setup | Medium | Low | None |
| 2.20 | Create `shell-init/login.nix` - Extract login shell setup | Medium | Low | None |
| 2.21 | Create `shell-init/history.nix` - Extract history configuration | Medium | Low | None |
| 2.22 | Create `shell-init/completion.nix` - Extract completion settings | Medium | Low | None |
| 2.23 | Create `shell-init/keybindings.nix` - Extract keybinding configs | Medium | Low | None |
| 2.24 | Refactor `default.nix` - Import all submodules | High | Medium | 2.1-2.23 |
| 2.25 | Verify nix flake check passes | High | Low | 2.24 |

#### Program: weechat (455 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 3.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 3.2 | Create `settings.nix` - Extract defaultSettings (weechat, aspell, logger, irc, buflist configs) | Medium | Low | None |
| 3.3 | Create `commands.nix` - Extract defaultExtraCommands (16 weechat commands) | Medium | Low | None |
| 3.4 | Create `matrix.nix` - Extract weechatMatrixRs package and Matrix-specific config | Medium | Medium | None |
| 3.5 | Create `scripts.nix` - Extract 11 script derivations | Low | Low | None |
| 3.6 | Create `filters.nix` - Extract buflist filter commands for Discord/WhatsApp/Slack | Low | Low | None |
| 3.7 | Create `init.nix` - Extract init script generation logic | Medium | Low | None |
| 3.8 | Create `vi-mode.nix` - Extract viModeScript derivation | Low | Low | None |
| 3.9 | Refactor `default.nix` - Import all submodules | High | Low | 3.1-3.8 |
| 3.10 | Verify nix flake check passes | High | Low | 3.9 |

---

### Phase 2: Tier 2 - Medium Priority

#### Program: claudecode (387 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 4.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 4.2 | Create `wrapper-scripts.nix` - Extract claudeCodeBin and claudeRouterBin | Medium | Medium | None |
| 4.3 | Create `fhs-environments.nix` - Extract FHS envs for both binaries | Medium | Medium | None |
| 4.4 | Create `router-config.nix` - Extract extensive routerSettings | Low | Low | None |
| 4.5 | Create `mcp-config.nix` - Extract platform-specific MCP config paths | Low | Low | None |
| 4.6 | Refactor `default.nix` - Import all submodules | High | Low | 4.1-4.5 |
| 4.7 | Verify nix flake check passes | High | Low | 4.6 |

#### Program: tmux (433 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 5.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 5.2 | Create `config.nix` - Extract tmux.conf as structured config | Medium | Low | None |
| 5.3 | Create `tmuxp-picker.nix` - Extract picker script (60 lines) | Medium | Medium | None |
| 5.4 | Create `sessions/chat.nix` - Extract chat session config | Low | Low | None |
| 5.5 | Create `sessions/main.nix` - Extract main session config | Low | Low | None |
| 5.6 | Create `sessions/monitoring.nix` - Extract monitoring session config | Low | Low | None |
| 5.7 | Create `sessions/homelab.nix` - Extract homelab session config | Low | Low | None |
| 5.8 | Create `sessions/valoris.nix` - Extract valoris session config | Low | Low | None |
| 5.9 | Create `sessions/valoris-backend.nix` - Extract valoris backend config | Low | Low | None |
| 5.10 | Create `sessions/valoris-frontend.nix` - Extract valoris frontend config | Low | Low | None |
| 5.11 | Create `sessions/ai-workspace.nix` - Extract AI workspace config | Low | Low | None |
| 5.12 | Create `sessions/work.nix` - Extract work session config | Low | Low | None |
| 5.13 | Refactor `default.nix` - Import all submodules | High | Medium | 5.1-5.12 |
| 5.14 | Verify nix flake check passes | High | Low | 5.13 |

#### Program: k9s (283 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 6.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 6.2 | Create `skin.nix` - Extract skin configuration (128 lines of YAML converted to Nix) | Medium | Low | None |
| 6.3 | Create `shortcuts.nix` - Extract shortcut definitions | Medium | Low | None |
| 6.4 | Create `templates.nix` - Extract resource templates | Medium | Low | None |
| 6.5 | Create `aliases.nix` - Extract command aliases | Low | Low | None |
| 6.6 | Create `views.nix` - Extract custom view definitions | Low | Low | None |
| 6.7 | Create `plugins.nix` - Extract plugin configurations | Low | Low | None |
| 6.8 | Refactor `default.nix` - Import all submodules | High | Low | 6.1-6.7 |
| 6.9 | Verify nix flake check passes | High | Low | 6.8 |

#### Program: gemini (210 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 7.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 7.2 | Create `wrapper.nix` - Extract FHS environment and auto-update script | Medium | Medium | None |
| 7.3 | Create `settings.nix` - Extract default settings configuration | Low | Low | None |
| 7.4 | Refactor `default.nix` - Import all submodules | High | Low | 7.1-7.3 |
| 7.5 | Verify nix flake check passes | High | Low | 7.4 |

#### Program: droid (189 lines)
| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 8.1 | Create `options.nix` - Extract all option definitions | High | Medium | None |
| 8.2 | Create `tools.nix` - Extract DROID tools list | Medium | Low | None |
| 8.3 | Create `paths.nix` - Extract workspace path configurations | Low | Low | None |
| 8.4 | Refactor `default.nix` - Import all submodules | High | Low | 8.1-8.3 |
| 8.5 | Verify nix flake check passes | High | Low | 8.4 |

---

### Phase 3: Tier 3 - Low Priority / Keep Single File

These modules are cohesive and under 200 lines. No refactoring needed unless requirements change:

| Program | Lines | Decision | Rationale |
|---------|-------|----------|-----------|
| git | 132 | Keep single | Simple package + settings, cohesive |
| starship | 63 | Keep single | Data-only config, no logic |
| alacritty | 77 | Keep single | Simple terminal config |
| ghostty | 76 | Keep single | Simple terminal config |
| btop | 37 | Keep single | Minimal config |
| neovim | 102 | Keep single | Simple package list + clone |
| cursor | 70 | Keep single | Simple config |
| steam | 59 | Keep single | Simple game launch options |
| easyeffects | 69 | Keep single | Simple preset config |
| ck-search | 92 | Keep single | Simple package build |
| mistral-vibe | 138 | Keep single | Simple Python package build |

---

### Phase 4: Verification & Integration

| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|--------------|
| 9.1 | Run `nix flake check` for all refactored modules | High | Low | All Phase 1-3 |
| 9.2 | Verify Darwin configs evaluate on Linux (`nix eval .#darwinConfigurations...`) | High | Low | 9.1 |
| 9.3 | Test rebuild on nixos-desktop | High | Medium | 9.2 |
| 9.4 | Test rebuild on macos-macbook (if available) | Medium | Medium | 9.2 |
| 9.5 | Update AGENTS.md if module structure conventions change | Low | Low | 9.1 |

---

## Estimated Effort Summary

| Phase | Programs | Total Tasks | Est. Hours |
|-------|----------|-------------|------------|
| Phase 1 | 3 (opencode, zsh, weechat) | 44 | 16-20h |
| Phase 2 | 5 (claudecode, tmux, k9s, gemini, droid) | 37 | 12-16h |
| Phase 3 | 11 | 0 (no changes) | 0h |
| Phase 4 | Integration | 5 | 2-4h |
| **Total** | **19 programs** | **86 tasks** | **30-40h** |

---

## Implementation Notes

### Import Pattern for Submodules

```nix
# default.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.jvf.programs.<name>;
in
{
  imports = [
    ./options.nix
    ./wrapper.nix
    ./config/formatter.nix
    ./config/lsp.nix
    # ... etc
  ];
  
  # Re-export for flake.modules
  flake.modules.nixos.programs-<name> = { ... };
  flake.modules.darwin.programs-<name> = { ... };
}
```

### Submodule Template

```nix
# config/formatter.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.jvf.programs.<name>;
in
{
  # Only config section, no options (defined in options.nix)
  config = lib.mkIf cfg.<condition> {
    # formatter-specific config
  };
}
```

### Key Principles

1. **Options in one place** - All option definitions in `options.nix`
2. **No circular imports** - Submodules only depend on options, not each other
3. **Platform abstraction** - Use `mkConfig { isDarwin }` pattern consistently
4. **Maintain exports** - `flake.modules.nixos/darwin.programs-<name>` must remain functional
5. **Verify incrementally** - Run `nix flake check` after each program is refactored
