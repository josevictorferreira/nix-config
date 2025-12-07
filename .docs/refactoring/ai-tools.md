# AI-Tools Module Refactoring Plan

## Overview
This document outlines the comprehensive refactoring plan for the `modules/common/ai-tools/` module. The goal is to transition from Markdown-string-based configurations to pure Nix attrsets for agents and commands, centralize MCP (Model Context Protocol) configurations in a dedicated section, and ensure seamless integration with consumer modules like `opencode` and `claudecode`.

**Key Objectives:**
1. **Structured Agent/Command Definitions**: Replace attrsets with Markdown prompt strings (e.g., `{ agent1 = ''markdown''; }`) with structured Nix attrsets (e.g., `{ agent1 = { name, description, tools?, prompt, ... }; }`).
2. **Centralized MCP Configurations**: Introduce an `mcp/` subdirectory with one file **per MCP server** (e.g., `mcp/shadcn.nix`, `mcp/context7.nix`), each containing agent-specific quirks (e.g., `{ opencode = { ... }; claudecode? = { ... }; }`), eliminating duplication.
3. **Consumer Updates**: Update `modules/programs/opencode/` and `modules/programs/claudecode/` to import and use the shared `ai-tools` configurations dynamically.

**Non-Goals:**
- No changes to existing agent/command logic or prompts (preserve functionality).
- No new features; focus on refactoring structure.
- Maintain cross-platform compatibility (NixOS/Darwin).

## Current State Analysis
```
modules/common/ai-tools/
├── agents/
│   ├── frontend/     # index.nix folds shadcn-ui-architect.nix, ui-ux-architect.nix
│   ├── general/      # index.nix folds code-reviewer.nix, etc.
│   ├── infra/        # index.nix folds container-expert.nix
│   ├── nix/          # index.nix folds flake-expert.nix, etc.
│   ├── project/      # index.nix folds system-config-expert.nix
│   ├── rails/        # index.nix folds rails-event-store-specialist.nix
│   └── scraping/     # index.nix folds ethical-scraper.nix
├── commands/
│   ├── general/      # index.nix folds ask.nix, do.nix, etc.
│   ├── git/          # index.nix folds add-and-format.nix, etc.
│   ├── nix/          # index.nix folds flake-update.nix, etc.
│   ├── project/      # index.nix folds changelog.nix
│   └── quality/      # index.nix folds deep-check.nix, etc.
├── scripts/
│   └── prompt-enhancer.nix
├── agents.nix        # Folds all agent index.nix files
├── commands.nix      # Folds all command index.nix files
├── default.nix       # Exports { commands, agents, scripts }
└── scripts.nix
```
- **Agents/Commands**: Each `.nix` file exports `{ name = \"Agent Name\"; prompt = ''long markdown''; }`.
- **MCP Duplication**: Hardcoded in `modules/programs/opencode/mcp.nix` (shadcn, context7, playwright, etc.). `claudecode.nix` currently has no MCP.
- **Consumers**: `opencode` and `claudecode` reference agents/commands directly or via strings.

## Proposed Structure
```
modules/common/ai-tools/
├── agents/           # Unchanged dir structure, but files refactored to structured attrsets
│   └── ... (individual agent files: { name, description, tools, prompt, ... })
├── commands/         # Unchanged dir structure, refactored similarly
│   └── ... 
├── mcp/              # NEW: Per-MCP configs with per-agent quirks
│   ├── shadcn.nix    # { opencode = { type, command, ... }; claudecode? = { ... }; }
│   ├── context7.nix  # ...
│   ├── playwright.nix
│   ├── chrome-devtools.nix
│   ├── podman-mcp.nix
│   └── mcp-nixos.nix # Linux-only
│   └── ... (other MCPs as needed)
├── scripts/          # Unchanged
├── agents.nix        # Updated to fold structured agents
├── commands.nix      # Updated to fold structured commands
├── mcp.nix           # NEW: Folds all mcp/*.nix into nested attrset { shadcn.opencode = ...; }
├── default.nix       # Export { agents, commands, scripts, mcp }
└── lib.nix           # NEW: Shared types, generators (e.g., mkAgent, toMarkdown)
```

### Schema Definitions (in `lib.nix`)
```nix
lib.types.submodule ({ config, ... }: {
  options = {
    name = lib.mkOption { type = lib.types.str; };
    description = lib.mkOption { type = lib.types.str; };
    tools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    prompt = lib.mkOption { type = lib.types.lines; };  # Multi-line string
    # Optional: settings, envVars, etc.
  };
});
```
- Agents and commands share this base schema.
- Generators: `mkAgent`, `mkCommand` for consistent creation.
- `toPromptString` to generate Markdown if needed for legacy.

## Detailed Implementation Steps

### Phase 1: Schema and Shared Lib (1-2 hours)
1. Create `modules/common/ai-tools/lib.nix`:
   - Define `types.agent` and `types.command` (submodules).
   - Helper functions: `mkAgent`, `mkCommand`, `agentsToAttrset`.
2. Test schema with a sample agent.

**Validation**: `nix eval --raw .#checks.aiTools.schema` (add simple check).

### Phase 2: Refactor Agents (4-6 hours)
1. **Individual Files**: Update each agent `.nix` (e.g., `agents/frontend/shadcn-ui-architect.nix`):
   ```nix
   { lib }: lib.mkAgent {
     name = "Shadcn UI Architect";
     description = "Specializes in Shadcn UI components";
     tools = [ "shadcn" ];
     prompt = ''
       You are a Shadcn UI Architect...
     '';
   }
   ```
2. **Index Files**: Update to fold structured attrsets (unchanged logic).
3. **agents.nix**: No major changes (still folds index.nix).

**Migration Strategy**:
- Preserve exact prompt text.
- Extract `name` from filename or existing doc.
- Add `description` from context.
- Set `tools = []` initially; populate later.

### Phase 3: Refactor Commands (3-4 hours)
- Identical process to agents.
- Commands may need `args?`, `examples?` in schema.

### Phase 4: MCP Centralization (2-3 hours)
1. Create `mcp/` dir.
2. Create individual `mcp/<mcp-name>.nix` files by extracting from `programs/opencode/mcp.nix`:
   - `mcp/shadcn.nix`: `{ opencode = { type = "local"; enabled = true; command = [ ... ]; }; }`
   - `mcp/context7.nix`: `{ opencode = { type = "remote"; ... }; }`
   - `mcp/playwright.nix`, `mcp/chrome-devtools.nix`, `mcp/podman-mcp.nix`
   - `mcp/mcp-nixos.nix` (Linux-only)
   - (claudecode entries added later if needed)
3. Create `mcp.nix` to fold all:
   ```nix
   { lib, system, ... }:
   lib.foldl' lib.recursiveUpdate {} (
     builtins.map (file: import (./mcp + "/${file}") { inherit lib system; })
     (builtins.attrNames (builtins.readDir ./mcp))
   );
   ```
5. Update `default.nix` to export `mcp`.

**Platform Handling**: Preserve `isDarwin` logic.

### Phase 5: Update Consumers (2 hours)
1. **opencode/default.nix**:
   - Import `aiTools = config.jvf.common.aiTools;`.
   - `settings.mcp = lib.mapAttrs (name: cfg: cfg.opencode) aiTools.mcp;`
   - `settings.agents = lib.mapAttrsToList (name: cfg: mkMarkdownAgent cfg) aiTools.agents;`
   - `settings.commands = lib.mapAttrsToList (name: cfg: mkMarkdownCommand cfg) aiTools.commands;`
   - Remove hardcoded `mcp.nix`.
2. **claudecode/default.nix**: 
   - Update `mkMdConfigs` to use structured `aiTools.agents`/`commands` via generator functions (no MCP needed yet).
3. **Dynamic Tool Disabling**: Generate `settings.tools` from `flatten (lib.mapAttrsToList (name: cfg: cfg.tools or []) aiTools.agents)`.

### Phase 6: Testing and Validation (1-2 hours)
1. **Local Tests**:
   - `make rebuild`
   - Verify `jvf.common.aiTools.agents` structure: `nix eval ...`
   - Check opencode/claudecode configs.
2. **Flake Checks**:
   - Add assertions: All agents have `name/description/prompt`.
   - MCP enabled tools match agent tools.
3. **Edge Cases**:
   - Darwin vs NixOS.
   - Empty tools lists.

### Phase 7: Documentation and Cleanup (30 min)
1. Update `AGENTS.md` with new usage.
2. Deprecate old Markdown format (warnings).
3. `make format && make lint && make check`.

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| Prompt breakage | Copy-paste exactly; diff before/after. |
| Schema rigidity | Optional fields; backward compat via `legacyPrompt?`. |
| MCP differences | Per-file customization. |
| Consumer breakage | Phased rollout; assertions. |

## Timeline
- **Total**: 13-19 hours.
- **Milestones**: Phase 1-3 (Day 1), Phase 4-5 (Day 2), Phase 6-7 (Day 2).

## Post-Refactor Enhancements (Future)
- Tool auto-discovery.
- Prompt templating.
- Validation for prompt quality.