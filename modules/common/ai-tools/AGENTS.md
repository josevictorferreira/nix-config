# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Commit:** N/A (Dynamic)
**Branch:** main

## OVERVIEW
Infrastructure for AI behavior. Defines high-level abstractions for Agents, Commands, MCP, and Skills.

- **Agents**: Personas with specific prompts/toolsets (Sub-agents in OpenCode).
- **Commands**: Slash command abstractions (`/refactor`, `/commit-changes`).
- **MCP**: Protocol configs for local/remote tool servers.
- **Skills**: Domain-specific knowledge blocks (Rails, Nix, Security).
- **Consumers**: Transformation layer in `lib/ai-tools.nix` that adapts Nix modules to tool-specific formats (Markdown/YAML/TOML) for OpenCode, ClaudeCode, and Gemini.

## STRUCTURE
```
modules/common/ai-tools/
├── agents/      # Persona definitions (frontend, general, ruby, nix)
├── commands/    # Slash command implementations (git, nix, ruby, features)
├── mcp/         # MCP server definitions (chrome, context7, shadcn)
├── skills/      # Domain-specific knowledge (rails, containers, nix)
├── rules.nix    # Base rule definitions (global constraints)
└── default.nix  # Main module aggregator
```

## WHERE TO LOOK
- `lib/ai-tools.nix`: Factory functions (`mkAgentModule`, etc.) in root `lib/`.
- `modules/common/ai-tools/default.nix`: Aggregates all AI sub-modules.
- `modules/common/ai-tools/rules.nix`: Global AI behavior constraints.

## CONVENTIONS
### Migration: Markdown -> Nix Modules
**Deprecated**: Plain Markdown strings for prompts.
**Required**: Use `lib.mkAgentModule`, `lib.mkCommandModule`, or `lib.mkMcpModule`.

### Creating an Agent
```nix
options.jvf.aiTools.agents."my-agent" = (lib.mkAgentModule {
  name = "My Agent";
  description = "Brief purpose";
  tools = [ "mcp-server-name" ];
  prompt = ''
    You are...
    Guidelines...
  '';
}).options;
```

## ANTI-PATTERNS
- **Raw Strings**: NO plain MD strings for new agents. Use factory functions.
- **Implicit Tools**: List tools explicitly in `tools` attribute.
- **Logic in Default**: Keep `default.nix` as an aggregator only.
- **Hardcoded Paths**: Use `lib.getExe` or `pkgs` references for MCP commands.
