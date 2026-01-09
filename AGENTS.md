# AGENTS.md

## Pre-Implementation

Before starting any implementation, read `.docs/rules/*` for project-specific lessons and gotchas.

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

The `modules/common/ai-tools/` tree is now a first-class NixOS module (Phase 7). Agents, commands, and MCP servers live under `jvf.aiTools.*` with enable flags and computed consumer outputs under `config.jvf.aiTools.consumers.*`. Legacy Markdown-string definitions are deprecated and will emit traces when encountered.

### Creating New Agents or Commands

Use the module form with `lib.mkAgentModule` / `lib.mkCommandModule` inside an options assignment:

```nix
# Example: modules/common/ai-tools/agents/frontend/my-agent.nix
{ lib, ... }:
{
  options.jvf.aiTools.agents."my-agent" = (lib.mkAgentModule {
    name = "My Agent";
    description = "Brief description of what this agent does";
    tools = [ "shadcn" "playwright" ];
    prompt = ''
      You are a specialized agent...
      
      Your responsibilities include:
      - Task 1
      - Task 2
    '';
  }).options;
}
```

**Required Fields:**
- `name`: Display name of the agent/command
- `description`: Brief description (used in documentation)
- `prompt`: Multi-line string containing the agent's instructions

**Optional Fields:**
- `tools`: List of MCP tools this agent uses (e.g., `["shadcn", "playwright"]`)
- `_output`: Computed consumer output (read-only; normally set by consumer modules)

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
├── mcp/                # MCP servers (local/remote)
├── consumers/          # Consumer transformations (opencode, claudecode)
└── types.nix / lib.nix # Shared helpers and types
```

Each subdirectory contains:
- Individual `.nix` files (one per agent/command/MCP)
- Category `default.nix` aggregators
- A top-level `default.nix` that imports aggregators and exports options/consumers

### Adding a New MCP Server

MCP servers are defined in `modules/common/ai-tools/mcp/` with one file per server, using `lib.mkMcpModule`:

```nix
# Example: modules/common/ai-tools/mcp/my-mcp.nix
{ lib, pkgs, config, system, ... }:

let
  cfg = config.jvf.aiTools.mcp.my-mcp;
  isDarwin = builtins.match ".*-darwin" system != null;
inn
{
  options.jvf.aiTools.mcp.my-mcp = (lib.mkMcpModule {
    options = {
      package = lib.mkPackageOption pkgs "my-mcp" { };
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = lib.mdDoc "Arguments passed to the MCP executable.";
      };
    };
  }).options;

  config = lib.mkIf cfg.enable {
    jvf.aiTools.mcp.my-mcp._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [ (lib.getExe cfg.package) ] ++ cfg.args;
      };
    };
  };
}
```

**MCP Configuration Fields:**
- `enable`: Toggle for the MCP server
- `package`: Package providing the MCP (for local MCPs)
- `url`/`headers`: For remote MCPs
- `_output`: Computed consumer output (read-only; set in `config`)

**Platform-Specific MCPs:**
Use conditionals for platform-specific servers:
```nix
{ lib, system, ... }:

let
  isDarwin = builtins.match ".*-darwin" system != null;
inn
lib.mkIf (!isDarwin) {
  options.jvf.aiTools.mcp."mcp-nixos" = (lib.mkMcpModule { }).options;

  config = lib.mkIf config.jvf.aiTools.mcp."mcp-nixos".enable {
    # linux-only output
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

The AI-Tools module exports all definitions via `modules/common/ai-tools/default.nix` and computed consumer outputs under `config.jvf.aiTools.consumers`:

```nix
# In modules/common/ai-tools/default.nix
imports = [
  ./mcp/default.nix
  ./agents/default.nix
  ./commands/default.nix
  ./consumers/default.nix
];

config = lib.mkIf cfg.enable {
  jvf.aiTools.mcpOutputs = lib.mapAttrs (_: mcpCfg: mcpCfg._output or { }) cfg.mcp;
};
```

Consumers (like `opencode` or `claudecode`) now use computed outputs:
```nix
{
  settings = {
    agents = config.jvf.aiTools.consumers.opencode.agents;
    commands = config.jvf.aiTools.consumers.opencode.commands;
    mcp = config.jvf.aiTools.consumers.opencode.mcp;
    toolSettings = config.jvf.aiTools.consumers.opencode.toolSettings;
  };
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

- `mkAgentModule { ... }`: Create an agent options module
- `mkCommandModule { ... }`: Create a command options module
- `mkMcpModule { ... }`: Create an MCP options module
- `extractTools`: Get all tools from agents/commands
- `mkToolDisableSettings`: Generate tool disable settings from tool list
- (Deprecated during migration) `toMarkdownPrompt`/`toClaudeMarkdownPrompt`/`toOpencodeMarkdownPrompt`

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

**New Module Format:**
```nix
{ lib, ... }:
{
  options.jvf.aiTools.agents."my-agent" = (lib.mkAgentModule {
    name = "Agent Name";
    description = "Brief description";
    prompt = ''
      You are a specialized agent...
    '';
  }).options;
}
```

**Consumer Usage (opencode example):**
```nix
{
  settings = {
    agents = config.jvf.aiTools.consumers.opencode.agents;
    commands = config.jvf.aiTools.consumers.opencode.commands;
    mcp = config.jvf.aiTools.consumers.opencode.mcp;
  };
}
```

**Note:** The old Markdown string format is deprecated; helper functions remain only for migration warnings.

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
