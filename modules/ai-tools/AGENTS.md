# AI Tools DSL

**Parent:** [../../AGENTS.md](../../AGENTS.md)

## OVERVIEW
AI coding assistant configuration DSL. Skills, commands, agents, MCP servers for opencode/claudecode/droid/gemini.

## STRUCTURE
```
ai-tools/
├── default.nix    # Main aggregator, enables subsystem
├── agents.nix     # Agent definitions (ui-ux-architect, swiss-minimalist-designer...)
├── commands.nix   # Slash commands (add-and-format, commit-changes, feat-*...)
├── mcp.nix        # MCP server configs
├── rules.nix      # Rule definitions
├── scripts.nix    # Script definitions
└── skills.nix     # Skill definitions (auditing-security, browser-debug-tools...)
```

## WHERE TO LOOK
| Task | File | Pattern |
|------|------|---------|
| **New Skill** | `skills.nix` | Add to `skillOptions_*` attrset |
| **New Command** | `commands.nix` | Add to `commands` attrset |
| **New Agent** | `agents.nix` | Add to `oldApiAgents` or `newApiAgents` |
| **MCP Server** | `mcp.nix` | Add to appropriate config block |

## DSL PATTERNS

### Skills (skills.nix)
```nix
skillOptions_<name> = {
  name = "skill-name";
  description = "Short desc";
  tags = [ "explorer" "documentation" ];
  allowed-tools = [ "Read" "Grep" "Glob" ];
  prompt = ''<skill prompt>'';
};
```
Applied via `mkSkillConfig` to all 4 programs.

### Commands (commands.nix)
```nix
<command-name> = {
  name = "command-name";
  description = "Short desc";
  agent = "";  # Optional agent assignment
  prompt = ''<command prompt>'';
};
```

### Agents (agents.nix)
```nix
# Old API (mode, model, temperature, permission, tools, prompt)
oldApiAgents.<name> = { ... };

# New API (different structure)
newApiAgents.<name> = { ... };
```
Applied via `mkAgentConfig` to all 4 programs.

## CONVENTIONS
- **Kebab-case** names throughout
- **Prompt first line** = title (`# Title Case`)
- **All 4 programs** receive same config (opencode, claudecode, droid, gemini)
- **Tags**: `explorer`, `documentation`, `browser` for categorization
- **Tool allowlisting**: explicit `allowed-tools` / `tools` arrays

## ANTI-PATTERNS
- **Hardcoding program list** - use `programs` variable
- **Skipping prompt structure** - always include title, sections
- **Missing description** - required for UI display
