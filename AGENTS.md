# AGENTS.md

## Build/Lint/Test Commands

```bash
# Format all nix files (required before committing)
make format

# Check formatting without making changes
make lint

# Validate flake structure
make check

# Rebuild system configuration (auto-detects platform)
make rebuild

# Update flake inputs
make update

# Clean nix store
make clean
```

## Code Style Guidelines

### Nix Formatting
- Use `nixpkgs-fmt` for all .nix files (enforced via `make lint`)
- Run `make format` before committing any changes

### Module Structure
All modules follow this pattern:
```nix
{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.<category>.<name>;
in
{
  options.jvf.<category>.<name> = {
    enable = lib.mkEnableOption "description";
    # other options using lib.mkOption
  };

  config = lib.mkIf cfg.enable {
    # configuration here
  };
}
```

### Naming Conventions
- Module files: `kebab-case.nix` (e.g., `opencode.nix`, `development.nix`)
- Option names: `jvf.<category>.<name>` (e.g., `jvf.roles.development.enable`)
- Local variables: Use `cfg` for config, descriptive names for others
- Functions: Descriptive names with hyphens (e.g., `mkMdConfigs`)

### Imports
- Group imports at top of file
- Use relative paths for modules in same directory
- Use absolute paths from repo root for cross-module imports
- Import specific modules, not entire directories

### Error Handling
- Use `lib.mkIf cfg.enable` to conditionally enable configurations
- Provide sensible defaults using `lib.mkOption` with `default`
- Use `lib.optional` and `lib.optionals` for conditional lists

### Types and Options
- Always specify types: `lib.types.bool`, `lib.types.str`, `lib.types.listOf`, etc.
- Use `lib.mkEnableOption` for simple enable flags
- For complex types, use `pkgs.formats.<type>.type` (e.g., `json.type`)

### Platform-Specific Code
```nix
# Check OS type
isDarwin = builtins.match ".*-darwin" system != null;

# Use lib.optionalString for conditional strings
lib.optionalString (os == "nixos") ''
  # Linux-only code
''
```

## Architecture Notes

- **No Home Manager**: This repo intentionally avoids Home Manager
- **Role-based**: Use `jvf.roles.<name>.enable = true` to activate feature sets
- **Explicit activation**: All modules require explicit `enable = true`
- **Cross-platform**: Modules should work on both NixOS and Darwin where possible

## AI-Tools Module Usage

The `modules/common/ai-tools/` module provides structured definitions for AI agents, commands, and MCP (Model Context Protocol) servers. As of the Phase 7 refactor, all definitions use pure Nix attrsets instead of Markdown strings.

### Creating New Agents or Commands

All agents and commands should use the structured format defined in `lib.nix`:

```nix
# Example: modules/common/ai-tools/agents/frontend/my-agent.nix
{ lib }:

lib.mkAgent {
  name = "My Agent";
  description = "Brief description of what this agent does";
  tools = [ "shadcn" "playwright" ];  # Optional, defaults to []
  prompt = ''
    You are a specialized agent...
    
    Your responsibilities include:
    - Task 1
    - Task 2
  '';
}
```

**Required Fields:**
- `name`: Display name of the agent/command
- `description`: Brief description (used in documentation)
- `prompt`: Multi-line string containing the agent's instructions

**Optional Fields:**
- `tools`: List of MCP tools this agent uses (e.g., `["shadcn", "playwright"]`)

### Directory Structure for Agents/Commands

```
modules/common/ai-tools/
├── agents/
│   ├── frontend/       # Frontend-focused agents
│   ├── general/        # General-purpose agents
│   ├── infra/          # Infrastructure agents
│   ├── nix/            # Nix-specific agents
│   ├── project/        # Project management agents
│   └── ...
├── commands/
│   ├── general/        # General commands
│   ├── git/            # Git-related commands
│   ├── nix/            # Nix-specific commands
│   └── ...
```

Each subdirectory contains:
- Individual `.nix` files (one per agent/command)
- An `index.nix` that folds all files in the directory

### Adding a New MCP Server

MCP servers are defined in `modules/common/ai-tools/mcp/` with one file per server:

```nix
# Example: modules/common/ai-tools/mcp/my-mcp.nix
{ lib, system, ... }:

{
  my-mcp = {
    opencode = {
      type = "local";  # or "remote"
      enabled = true;
      command = [ "npx" "-y" "@my-org/my-mcp" ];
      args = [ "--some-arg" ];
    };
    # Optional: claudecode-specific config
    # claudecode = { ... };
  };
}
```

**MCP Configuration Fields:**
- `type`: Either `"local"` (spawned process) or `"remote"` (network)
- `enabled`: Boolean to enable/disable the MCP server
- `command`: List of command parts (for local MCPs)
- `args`: Optional additional arguments (for local MCPs)

**Platform-Specific MCPs:**
Use conditionals for platform-specific servers:
```nix
{ lib, system, ... }:

let
  isDarwin = builtins.match ".*-darwin" system != null;
in
lib.optionalAttrs (!isDarwin) {
  # Linux-only MCP
  mcp-nixos = { ... };
}
```

### Consumer Integration

The AI-Tools module exports all definitions via `modules/common/ai-tools/default.nix`:

```nix
{
  agents = { ... };    # All agents as attrset
  commands = { ... };  # All commands as attrset
  mcp = { ... };       # All MCP servers as attrset
  scripts = { ... };   # Additional scripts
}
```

Consumers (like `opencode` or `claudecode`) import via:
```nix
let
  aiTools = config.jvf.common.aiTools;
in
{
  # Use agents
  settings.agents = lib.mapAttrsToList (name: cfg: {
    inherit (cfg) name;
    prompt = cfg.prompt;
  }) aiTools.agents;
  
  # Use MCP servers (opencode example)
  settings.mcp = lib.mapAttrs (name: mcpCfg: mcpCfg.opencode) aiTools.mcp;
}
```

### Helper Functions (from lib.nix)

- `mkAgent { name, description, prompt, tools ? [] }`: Create structured agent
- `mkCommand { ... }`: Alias for `mkAgent` (same structure)
- `foldAiDefinitions`: Fold multiple definitions into single attrset
- `importAiFile`: Import agent/command file (handles functions or plain attrsets)
- `toMarkdownPrompt`: Extract prompt string (for backward compatibility)
- `extractTools`: Get all tools from agents/commands
- `mkToolDisableSettings`: Generate tool disable settings from tool list

### Migration from Old Format

**Old Format (DEPRECATED):**
```nix
{
  my-agent = ''
    # Agent Name
    You are a specialized agent...
  '';
}
```

**New Format:**
```nix
{ lib }:

lib.mkAgent {
  name = "Agent Name";
  description = "Brief description";
  prompt = ''
    You are a specialized agent...
  '';
}
```

**Note:** The old Markdown string format is deprecated but still supported during the transition period via `toMarkdownPrompt` helper.

### Validation

After adding/modifying agents, commands, or MCP servers:

1. **Format**: `make format`
2. **Lint**: `make lint`
3. **Check**: `make check`
4. **Test**: `make rebuild`

All definitions are validated to ensure:
- Required fields are present
- Types are correct
- Platform-specific code works on target platforms
