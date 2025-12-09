# AI-Tools Module Refactoring Plan

## Executive Summary

Refactor the `modules/common/ai-tools/` module from a simple attrset-exposing pattern to a proper NixOS module pattern with:
- Individual module definitions for each MCP server, agent, and command
- Enable/disable options at granular level
- Proper consumer integration (opencode, claudecode, future tools)
- Type-safe options with validation
- Platform-specific handling built into modules

## Current Architecture Analysis

### Current Structure
```
modules/common/ai-tools/
├── default.nix          # Exposes attrsets directly
├── lib.nix              # Helper functions (mkAgent, mkCommand, etc.)
├── agents.nix           # Aggregates all agents
├── commands.nix         # Aggregates all commands
├── mcp.nix              # Aggregates all MCP servers
├── checks.nix           # Validation and stats
├── scripts.nix          # Additional scripts
├── agents/              # Individual agent files
├── commands/            # Individual command files
├── mcp/                 # Individual MCP server files
└── scripts/             # Script files
```

### Current Problems
1. **No granular control**: Can't enable/disable individual agents, commands, or MCPs
2. **Hardcoded consumers**: Each consumer (opencode, claudecode) imports and transforms data manually
3. **Platform handling scattered**: Platform checks duplicated in multiple places
4. **No configuration merging**: Can't customize agent prompts or MCP settings per-consumer
5. **Tight coupling**: Consumers directly import ai-tools, no abstraction layer

## Target Architecture

### New Module Structure
```
modules/common/ai-tools/
├── default.nix              # Main module with jvf.aiTools options
├── lib.nix                  # Updated helper functions
├── types.nix                # Custom types for agents, commands, MCPs
├── agents/
│   ├── default.nix          # Agent aggregator module
│   ├── nix/
│   │   ├── default.nix      # Module for nix-expert agent
│   │   ├── flake-expert.nix # Module for flake-expert
│   │   └── ...
│   └── ...
├── commands/
│   ├── default.nix          # Command aggregator module
│   └── ...
├── mcp/
│   ├── default.nix          # MCP aggregator module
│   ├── playwright.nix       # Module for playwright MCP
│   ├── context7.nix         # Module for context7 MCP
│   └── ...
└── consumers/
    ├── default.nix          # Consumer config generators
    ├── opencode.nix         # Opencode-specific transformations
    └── claudecode.nix       # Claudecode-specific transformations
```

### Option Schema Design

```nix
# Main options structure
jvf.aiTools = {
  # Global enable
  enable = mkEnableOption "AI tools integration";
  
  # MCP Servers
  mcp = {
    playwright = {
      enable = mkEnableOption "Playwright MCP server";
      package = mkPackageOption pkgs "playwright-mcp" {};
      executable = mkOption { type = types.path; ... };
      # Consumer-specific output (read-only computed)
    };
    context7 = {
      enable = mkEnableOption "Context7 MCP server";
      apiKeyEnvVar = mkOption { type = types.str; default = "CONTEXT7_API_KEY"; };
    };
    # ... other MCPs
  };
  
  # Agents
  agents = {
    nix-expert = {
      enable = mkEnableOption "Nix Expert agent";
      name = mkOption { type = types.str; default = "Nix Expert"; };
      description = mkOption { type = types.str; ... };
      tools = mkOption { type = types.listOf types.str; default = ["context7" "mcp-nixos"]; };
      prompt = mkOption { type = types.lines; ... };
      # Allow consumers to extend/override
    };
    # ... other agents
  };
  
  # Commands
  commands = {
    commit-msg = {
      enable = mkEnableOption "Commit Message command";
      name = mkOption { ... };
      prompt = mkOption { ... };
    };
    # ... other commands
  };
  
  # Consumer configurations (computed from above)
  consumers = {
    opencode = {
      agents = mkOption { type = types.attrsOf types.str; readOnly = true; };
      commands = mkOption { type = types.attrsOf types.str; readOnly = true; };
      mcp = mkOption { type = json.type; readOnly = true; };
    };
    claudecode = {
      skills = mkOption { type = types.attrsOf types.str; readOnly = true; };
      commands = mkOption { type = types.attrsOf types.str; readOnly = true; };
    };
  };
};
```

---

## Implementation Phases

### Phase 1: Foundation - Types and Core Module Structure

**Objective**: Create the foundational types and main module skeleton without breaking existing functionality.

**Tasks**:

1.1. Create `types.nix` with custom types:
   - `agentType` - submodule for agent definitions
   - `commandType` - submodule for command definitions  
   - `mcpLocalType` - submodule for local MCP servers
   - `mcpRemoteType` - submodule for remote MCP servers

1.2. Update `lib.nix` to include:
   - `mkAgentModule` - creates a module from agent definition
   - `mkCommandModule` - creates a module from command definition
   - `mkMcpModule` - creates a module from MCP definition
   - Keep existing functions for backward compatibility

1.3. Create new `default.nix` skeleton:
   - Define `jvf.aiTools.enable` option
   - Import types and lib
   - Leave agents/commands/mcp as empty submodules initially

**Test for Phase 1**:
```bash
# Test 1.1: Verify flake evaluation still works
nix flake check

# Test 1.2: Verify types can be imported
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools --json 2>&1 | grep -q "enable"
```

---

### Phase 2: MCP Server Modules

**Objective**: Convert all MCP servers to individual modules with enable options.

**Tasks**:

2.1. Create `mcp/default.nix` as aggregator module:
   - Imports all individual MCP modules
   - Provides `jvf.aiTools.mcp` options namespace

2.2. Convert `playwright.nix` to module format:
   ```nix
   { lib, pkgs, config, system, ... }:
   let
     cfg = config.jvf.aiTools.mcp.playwright;
     isDarwin = builtins.match ".*-darwin" system != null;
   in {
     options.jvf.aiTools.mcp.playwright = {
       enable = lib.mkEnableOption "Playwright MCP server";
       package = lib.mkPackageOption pkgs "playwright-mcp" {};
       executable = lib.mkOption {
         type = lib.types.path;
         default = if isDarwin 
           then lib.getExe pkgs.google-chrome 
           else lib.getExe pkgs.chromium;
       };
     };
     
     config.jvf.aiTools.mcp.playwright._output = lib.mkIf cfg.enable {
       opencode = {
         type = "local";
         enabled = true;
         command = [
           (lib.getExe cfg.package)
           "--executable-path"
           cfg.executable
         ];
       };
       claudecode = { ... };
     };
   }
   ```

2.3. Convert remaining MCP servers:
   - `context7.nix` - remote MCP
   - `mcp-nixos.nix` - platform-specific (Linux only)
   - `chrome-devtools.nix`
   - `shadcn.nix`
   - `podman-mcp.nix`

2.4. Update main `default.nix` to aggregate MCP outputs

**Test for Phase 2**:
```bash
# Test 2.1: Verify MCP modules can be enabled/disabled
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.mcp.playwright.enable

# Test 2.2: Verify platform-specific MCP (mcp-nixos) is only available on Linux
nix eval .#nixosConfigurations.nixos-desktop.config.jvf.aiTools.mcp.mcp-nixos.enable

# Test 2.3: Verify MCP output is generated correctly
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.mcp.playwright._output.opencode --json
```

---

### Phase 3: Agent Modules

**Objective**: Convert all agents to individual modules with enable options.

**Tasks**:

3.1. Create `agents/default.nix` as aggregator module:
   - Imports all agent category modules
   - Provides `jvf.aiTools.agents` options namespace

3.2. Create category aggregators (`agents/nix/default.nix`, etc.):
   - Each category imports its individual agents
   - Provides namespace like `jvf.aiTools.agents.nix-expert`

3.3. Convert agent files to module format:
   ```nix
   # agents/nix/nix-expert.nix
   { lib, config, ... }:
   let
     cfg = config.jvf.aiTools.agents.nix-expert;
   in {
     options.jvf.aiTools.agents.nix-expert = {
       enable = lib.mkEnableOption "Nix Expert agent";
       name = lib.mkOption {
         type = lib.types.str;
         default = "Nix Expert";
       };
       description = lib.mkOption {
         type = lib.types.str;
         default = "Nix and NixOS configuration specialist";
       };
       tools = lib.mkOption {
         type = lib.types.listOf lib.types.str;
         default = [ "context7" "mcp-nixos" ];
       };
       prompt = lib.mkOption {
         type = lib.types.lines;
         default = ''
           You are a Nix expert...
         '';
       };
     };
     
     # No config section - agents are pure data
   }
   ```

3.4. Convert all agent categories:
   - `nix/` - nix-expert, flake-expert, module-expert
   - `general/` - all general agents
   - `frontend/` - frontend agents
   - `infra/` - infrastructure agents
   - `project/` - project management agents
   - `rails/` - Rails agents
   - `scraping/` - web scraping agents

**Test for Phase 3**:
```bash
# Test 3.1: Verify agent can be enabled
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.agents.nix-expert.enable

# Test 3.2: Verify agent prompt can be customized
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.agents.nix-expert.prompt --raw | head -5

# Test 3.3: Verify all agents are available
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.agents --json | jq 'keys'
```

---

### Phase 4: Command Modules

**Objective**: Convert all commands to individual modules with enable options.

**Tasks**:

4.1. Create `commands/default.nix` as aggregator module

4.2. Create category aggregators (`commands/git/default.nix`, etc.)

4.3. Convert command files to module format (same pattern as agents)

4.4. Convert all command categories:
   - `git/` - commit-msg, review, add-and-format, etc.
   - `nix/` - nix-specific commands
   - `general/` - general commands
   - `quality/` - code quality commands
   - `project/` - project management commands

**Test for Phase 4**:
```bash
# Test 4.1: Verify command can be enabled
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.commands.commit-msg.enable

# Test 4.2: Verify all commands are available
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.commands --json | jq 'keys'
```

---

### Phase 5: Consumer Integration Layer

**Objective**: Create consumer-specific configuration generators.

**Tasks**:

5.1. Create `consumers/default.nix`:
   - Aggregates all consumer transformations
   - Provides `jvf.aiTools.consumers` options

5.2. Create `consumers/opencode.nix`:
   - Transform agents to opencode markdown format
   - Transform commands to opencode markdown format
   - Transform MCP configs to opencode format
   - Generate tool disable settings

5.3. Create `consumers/claudecode.nix`:
   - Transform agents to claudecode skill format
   - Transform commands to claudecode format

5.4. Expose computed consumer configs:
   ```nix
   jvf.aiTools.consumers = {
     opencode = {
       agents = { ... };    # Computed from enabled agents
       commands = { ... };  # Computed from enabled commands
       mcp = { ... };       # Computed from enabled MCPs
       toolSettings = { ... }; # Tool disable settings
     };
     claudecode = {
       skills = { ... };
       commands = { ... };
     };
   };
   ```

**Test for Phase 5**:
```bash
# Test 5.1: Verify opencode consumer output is generated
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.consumers.opencode.agents --json | jq 'keys | length'

# Test 5.2: Verify claudecode consumer output is generated
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.consumers.claudecode.skills --json | jq 'keys | length'

# Test 5.3: Verify MCP output format is correct for opencode
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.consumers.opencode.mcp.playwright --json
```

---

### Phase 6: Update Consumer Modules

**Objective**: Update opencode and claudecode modules to use the new aiTools module.

**Tasks**:

6.1. Update `modules/programs/opencode/default.nix`:
   - Remove direct ai-tools import
   - Use `config.jvf.aiTools.consumers.opencode`
   - Simplify the module significantly

6.2. Update `modules/programs/claudecode.nix`:
   - Remove direct ai-tools import
   - Use `config.jvf.aiTools.consumers.claudecode`

6.3. Remove deprecated code:
   - Remove `mkMdConfigs` functions from consumers
   - Remove direct aiTools imports

**Test for Phase 6**:
```bash
# Test 6.1: Full system rebuild
make rebuild

# Test 6.2: Verify opencode config is generated correctly
cat ~/.config/opencode/config.json | jq '.mcp | keys'

# Test 6.3: Verify agent markdown files are created
ls ~/.config/opencode/agent/
```

---

### Phase 7: Validation and Cleanup

**Objective**: Update validation, remove deprecated code, update documentation.

**Tasks**:

7.1. Update `checks.nix`:
   - Validate against new module options
   - Add assertions for required MCP tools
   - Validate agent tool references against enabled MCPs

7.2. Cleanup deprecated code in `lib.nix`:
   - Remove legacy format support (if no longer needed)
   - Keep backward-compatible functions marked deprecated

7.3. Update `AGENTS.md`:
   - Document new module pattern
   - Provide migration examples
   - Update usage examples

7.4. Add assertions:
   ```nix
   assertions = [
     {
       assertion = cfg.agents.nix-expert.enable -> cfg.mcp.context7.enable;
       message = "nix-expert agent requires context7 MCP to be enabled";
     }
   ];
   ```

**Test for Phase 7**:
```bash
# Test 7.1: Validation checks pass
nix build .#checks.x86_64-linux.ai-tools-all-checks

# Test 7.2: Rebuild succeeds with new module
make rebuild

# Test 7.3: Documentation is accurate
make lint
```

---

### Phase 8: Role Integration

**Objective**: Enable aiTools configurations via roles.

**Tasks**:

8.1. Update `modules/roles/ai-development.nix`:
   - Enable aiTools by default for ai-development role
   - Enable relevant MCPs, agents, commands for the role

8.2. Create role-specific presets:
   ```nix
   jvf.roles.ai-development.enable = true;
   # Automatically enables:
   # - jvf.aiTools.enable
   # - jvf.aiTools.mcp.context7.enable
   # - jvf.aiTools.mcp.playwright.enable
   # - jvf.aiTools.agents.nix-expert.enable
   # - etc.
   ```

8.3. Allow role customization:
   - Users can still disable specific agents/MCPs
   - Priority system: role defaults < user overrides

**Test for Phase 8**:
```bash
# Test 8.1: Role enables aiTools
nix eval .#nixosConfigurations.<hostname>.config.jvf.aiTools.enable --json
# Should return true when ai-development role is enabled

# Test 8.2: Individual overrides work
# Add jvf.aiTools.agents.nix-expert.enable = false; in config
# Verify agent is disabled despite role enabling it
```

---

## Migration Guide

### For Users

```nix
# Before (implicit - everything enabled)
jvf.roles.ai-development.enable = true;

# After (explicit control)
jvf.roles.ai-development.enable = true;

# Optionally customize
jvf.aiTools = {
  mcp.playwright.enable = false;  # Disable specific MCP
  agents.nix-expert.prompt = lib.mkAfter ''
    Additional context for my projects...
  '';
};
```

### For Module Authors

```nix
# Before
let
  aiTools = import ../common/ai-tools { inherit lib pkgs system; };
in
{
  settings.mcp = lib.mapAttrs (name: cfg: cfg.opencode) aiTools.mcp;
}

# After
{
  settings.mcp = config.jvf.aiTools.consumers.opencode.mcp;
}
```

---

## Implementation Todo List

### Phase 1: Foundation (Day 1)
- [x] 1.1 Create `types.nix` with agent, command, MCP types
- [x] 1.2 Update `lib.nix` with module creation helpers
- [x] 1.3 Create new `default.nix` skeleton with jvf.aiTools.enable
- [x] **TEST**: Run `nix flake check` and verify basic evaluation

### Phase 2: MCP Modules (Day 2-3)
- [x] 2.1 Create `mcp/default.nix` aggregator module
- [x] 2.2 Convert `playwright.nix` to module format
- [x] 2.3 Convert `context7.nix` to module format
- [x] 2.4 Convert `mcp-nixos.nix` to module format (platform-specific)
- [x] 2.5 Convert `chrome-devtools.nix` to module format
- [x] 2.6 Convert `shadcn.nix` to module format
- [x] 2.7 Convert `podman-mcp.nix` to module format
- [x] 2.8 Update main default.nix to aggregate MCP outputs
- [ ] **TEST**: Verify MCP enable/disable works and output format is correct

### Phase 3: Agent Modules (Day 4-5)
- [x] 3.1 Create `agents/default.nix` aggregator module
- [x] 3.2 Create `agents/nix/default.nix` category module
- [x] 3.3 Convert nix-expert, flake-expert, module-expert to modules
- [x] 3.4 Create and convert `agents/general/` category
- [x] 3.5 Create and convert `agents/frontend/` category
- [x] 3.6 Create and convert `agents/infra/` category
- [x] 3.7 Create and convert `agents/project/` category
- [x] 3.8 Create and convert `agents/rails/` category
- [x] 3.9 Create and convert `agents/scraping/` category
- [ ] **TEST**: Verify all agents can be enabled/disabled individually

### Phase 4: Command Modules (Day 6)
- [ ] 4.1 Create `commands/default.nix` aggregator module
- [ ] 4.2 Create and convert `commands/git/` category
- [ ] 4.3 Create and convert `commands/nix/` category
- [ ] 4.4 Create and convert `commands/general/` category
- [ ] 4.5 Create and convert `commands/quality/` category
- [ ] 4.6 Create and convert `commands/project/` category
- [ ] **TEST**: Verify all commands can be enabled/disabled individually

### Phase 5: Consumer Integration (Day 7)
- [ ] 5.1 Create `consumers/default.nix` aggregator
- [ ] 5.2 Create `consumers/opencode.nix` with transformations
- [ ] 5.3 Create `consumers/claudecode.nix` with transformations
- [ ] 5.4 Expose computed consumer configs in main module
- [ ] **TEST**: Verify consumer output format matches expected structure

### Phase 6: Update Consumers (Day 8)
- [ ] 6.1 Update `modules/programs/opencode/default.nix`
- [ ] 6.2 Update `modules/programs/claudecode.nix`
- [ ] 6.3 Remove deprecated code from consumers
- [ ] **TEST**: Full system rebuild and verify config files are correct

### Phase 7: Validation and Cleanup (Day 9)
- [ ] 7.1 Update `checks.nix` for new module structure
- [ ] 7.2 Add assertions for tool dependencies
- [ ] 7.3 Cleanup deprecated code in `lib.nix`
- [ ] 7.4 Update `AGENTS.md` documentation
- [ ] **TEST**: Run validation checks and verify all pass

### Phase 8: Role Integration (Day 10)
- [ ] 8.1 Update `modules/roles/ai-development.nix`
- [ ] 8.2 Create role-specific presets
- [ ] 8.3 Test role customization with overrides
- [ ] **TEST**: Verify roles correctly enable/disable aiTools components

---

## Success Criteria

1. **Granular Control**: Can enable/disable any individual MCP, agent, or command
2. **Type Safety**: All options have proper types with validation
3. **Platform Handling**: Platform-specific MCPs auto-detect and configure correctly
4. **Consumer Abstraction**: opencode/claudecode use computed configs, not direct imports
5. **Customization**: Users can extend/override agent prompts and MCP settings
6. **Backward Compatibility**: Existing configurations continue to work during migration
7. **Documentation**: AGENTS.md updated with new patterns and examples
8. **Validation**: All checks pass, assertions prevent invalid configurations
