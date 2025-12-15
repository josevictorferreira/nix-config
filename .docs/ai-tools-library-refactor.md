# AI-Tools Library Refactor Plan

## Summary
Refactor the AI-Tools module to pass functions defined in `modules/common/ai-tools/lib.nix` through `modules/common/ai-tools/default.nix` to all nested imported modules, replacing all references to `inputs.lib.aiTools` and `inputs.lib.strings`.

## Strategy
Use `_module.args` to expose `aiToolsLib` containing all helper functions (including `kebabToHuman`) to all submodules. This is the idiomatic Nix approach for passing additional arguments to imported modules without modifying their function signatures.

## Implementation Phases

### Phase 1: Extend local lib.nix with kebabToHuman
Add the `kebabToHuman` function to `modules/common/ai-tools/lib.nix` so all string helpers are co-located.

- [ ] 1.1 Add `kebabToHuman` function to `modules/common/ai-tools/lib.nix`
- [ ] 1.2 Run `make format` and `make lint` to validate

### Phase 2: Update default.nix to expose aiToolsLib
Modify `modules/common/ai-tools/default.nix` to import `./lib.nix` and expose it via `_module.args.aiToolsLib`.

- [ ] 2.1 Update `modules/common/ai-tools/default.nix` to import `./lib.nix` and set `_module.args.aiToolsLib`
- [ ] 2.2 Run `make format` and `make lint` to validate

### Phase 3: Update agents to use aiToolsLib
Replace `inputs.lib.aiTools` → `aiToolsLib` and `inputs.lib.strings.kebabToHuman` → `aiToolsLib.kebabToHuman` in agent files.

- [ ] 3.1 Update `agents/frontend/shadcn-ui-architect.nix`
- [ ] 3.2 Update `agents/frontend/ui-ux-architect.nix`
- [ ] 3.3 Update `agents/general/code-reviewer.nix`
- [ ] 3.4 Update `agents/general/documentation-writer.nix`
- [ ] 3.5 Run `make format` and `make lint` to validate

### Phase 4: Update commands to use aiToolsLib
Replace references in all command files.

- [ ] 4.1 Update `commands/general/deep-check.nix`
- [ ] 4.2 Update `commands/general/dependency-audit.nix`
- [ ] 4.3 Update `commands/general/style-audit.nix`
- [ ] 4.4 Update `commands/git/add-and-format.nix`
- [ ] 4.5 Update `commands/git/commit-changes.nix`
- [ ] 4.6 Update `commands/implementation/ask.nix`
- [ ] 4.7 Update `commands/implementation/do.nix`
- [ ] 4.8 Update `commands/implementation/implement-feature.nix`
- [ ] 4.9 Update `commands/implementation/implement-fix.nix`
- [ ] 4.10 Update `commands/implementation/implement-refactoring.nix`
- [ ] 4.11 Update `commands/implementation/implement-tests.nix`
- [ ] 4.12 Update `commands/nix/flake-update.nix`
- [ ] 4.13 Update `commands/nix/nix-check.nix`
- [ ] 4.14 Update `commands/nix/nix-module-lint.nix`
- [ ] 4.15 Update `commands/nix/nix-module-scaffold.nix`
- [ ] 4.16 Run `make format` and `make lint` to validate

### Phase 5: Update MCP modules to use aiToolsLib
Replace references in all MCP files.

- [ ] 5.1 Update `mcp/chrome-devtools.nix`
- [ ] 5.2 Update `mcp/ck.nix`
- [ ] 5.3 Update `mcp/context7.nix`
- [ ] 5.4 Update `mcp/mcp-nixos.nix`
- [ ] 5.5 Update `mcp/playwright.nix`
- [ ] 5.6 Update `mcp/podman-mcp.nix`
- [ ] 5.7 Update `mcp/shadcn.nix`
- [ ] 5.8 Run `make format` and `make lint` to validate

### Phase 6: Update skills to use aiToolsLib
Replace references in all skill files.

- [ ] 6.1 Update `skills/auditing-security.nix`
- [ ] 6.2 Update `skills/creating-nix-modules.nix`
- [ ] 6.3 Update `skills/developing-containers.nix`
- [ ] 6.4 Update `skills/managing-flakes.nix`
- [ ] 6.5 Update `skills/managing-rails-events.nix`
- [ ] 6.6 Update `skills/pythonic-scraping-websites.nix`
- [ ] 6.7 Update `skills/ruby-stealth-scraping.nix`
- [ ] 6.8 Update `skills/writing-nix-code.nix`
- [ ] 6.9 Update `skills/creating-skills.nix`
- [ ] 6.10 Run `make format` and `make lint` to validate

### Phase 7: Update consumer modules
Update `opencode`, `claudecode`, and `cursor` modules to use the localized library.

- [ ] 7.1 Update `modules/programs/opencode/default.nix`
- [ ] 7.2 Update `modules/programs/claudecode.nix`
- [ ] 7.3 Update `modules/programs/cursor.nix`
- [ ] 7.4 Run `make format` and `make lint` to validate

### Phase 8: Final validation
- [ ] 8.1 Run `make check` to validate flake structure
- [ ] 8.2 Run `make rebuild` to test full system build
- [ ] 8.3 Verify no remaining `inputs.lib.aiTools` or `inputs.lib.strings` references

## Change Pattern

### Before (in submodules):
```nix
{ config, lib, inputs, ... }:
let
  agentFullName = inputs.lib.strings.kebabToHuman agentName;
  agentDef = inputs.lib.aiTools.mkAgentModule { ... };
in
{ ... }
```

### After (in submodules):
```nix
{ config, lib, aiToolsLib, ... }:
let
  agentFullName = aiToolsLib.kebabToHuman agentName;
  agentDef = aiToolsLib.mkAgentModule { ... };
in
{ ... }
```

### In default.nix:
```nix
{ lib, ... }:
let
  aiToolsLib = import ./lib.nix { inherit lib; };
in
{
  _module.args.aiToolsLib = aiToolsLib;
  imports = [ ... ];
}
```

## Success Criteria
- All 38 `inputs.lib.aiTools` references replaced with `aiToolsLib`
- All 22 `inputs.lib.strings.kebabToHuman` references replaced with `aiToolsLib.kebabToHuman`
- `make format`, `make lint`, `make check` pass
- `make rebuild` succeeds
- No functional changes to module outputs
