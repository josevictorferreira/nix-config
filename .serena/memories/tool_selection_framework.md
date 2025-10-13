# MCP Tool Selection Framework for Nix Configuration Project

## Project Context Analysis
- **Project Type**: Cross-platform Nix configuration (NixOS + macOS)
- **Language**: Nix (declarative configuration language)
- **Scale**: Medium (~50+ files across multiple directories)
- **Complexity**: High (modular structure, external subtrees, secrets management)

## Serena MCP Capabilities Match
✅ **Optimal For:**
- Symbol operations (rename, extract, move configuration functions)
- LSP-style navigation across Nix modules
- Project context and cross-session persistence
- Multi-language analysis (Nix + Shell + Lua configs)
- Memory management for complex configuration relationships
- Semantic understanding of dependency chains in flake.nix

## Morphllm MCP Capabilities Match
⚡ **Optimal For:**
- Pattern-based updates (version bumps, URL changes)
- Bulk text replacements (path updates, formatting)
- Style enforcement across multiple .nix files
- Fast operations when semantic understanding not critical
- Git subtree management automation
- Bulk configuration property updates

## Decision Matrix

### Operation Routing Rules

**Direct to Serena:**
- Symbol operations: rename function/variable across files
- Project memory: save/load configuration context
- Cross-language dependencies: Nix ↔ Shell ↔ Lua integration
- Complex refactoring: module reorganization, dependency changes

**Direct to Morphllm:**
- Pattern replacements: update URLs, version numbers
- Bulk formatting: enforce Nix style across files
- Text substitutions: change import paths, package names
- Git operations: subtree sync, commit message updates

**Complexity-Based Routing:**
- **Score >0.6** → Serena (semantic understanding needed)
- **Score <0.4** → Morphllm (speed prioritized)
- **0.4-0.6** → Feature-based analysis

### Scoring Factors
```yaml
file_count:
  1-2: 0.2 points
  3-5: 0.4 points  
  6-10: 0.6 points
  11+: 0.8 points

operation_type:
  symbol_rename: 0.8 points
  pattern_replace: 0.2 points
  complex_refactor: 0.9 points
  bulk_edit: 0.3 points

language_complexity:
  nix_only: 0.3 points
  multi_lang: 0.6 points
  external_deps: 0.4 points

framework_knowledge:
  configuration_patterns: 0.3 points
  flake_semantics: 0.5 points
  module_system: 0.6 points
```

## Performance Trade-offs
- **Serena**: Higher accuracy, semantic understanding, session persistence
- **Morphllm**: Faster execution, pattern efficiency, bulk operations

## Integration Patterns
- **Analysis Phase**: Serena (context discovery)
- **Implementation Phase**: Morphllm (pattern updates) → Serena (symbol changes)
- **Validation Phase**: Serena (semantic validation)
- **Memory Phase**: Serena (project persistence)