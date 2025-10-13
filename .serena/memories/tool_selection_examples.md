# Tool Selection Examples for Nix Configuration

## Example 1: Package Version Update
**Operation**: "Update all Neovim to version 0.10.0"
**Analysis**: Pattern-based replacement across multiple files
**Complexity Score**: 0.3 (low)
**Selection**: Morphllm MCP
**Rationale**: Simple text replacement, speed prioritized

## Example 2: Rename Configuration Function
**Operation**: "Rename `myNeovimConfig` to `neovimSetup` across home-manager"
**Analysis**: Symbol operation requiring semantic understanding
**Complexity Score**: 0.8 (high)  
**Selection**: Serena MCP
**Rationale**: LSP-style symbol navigation, dependency tracking

## Example 3: Reorganize Module Structure
**Operation**: "Move gaming configurations from shared to nixos-desktop only"
**Analysis**: Complex refactoring with cross-file dependencies
**Complexity Score**: 0.9 (very high)
**Selection**: Serena MCP
**Rationale**: Semantic understanding of module imports, dependency chains

## Example 4: Update Git Subtree URLs
**Operation**: "Update nvim subtree URL to new repository"
**Analysis**: Pattern-based URL replacement in Makefile
**Complexity Score**: 0.2 (very low)
**Selection**: Morphllm MCP  
**Rationale**: Simple text substitution, no semantic analysis needed

## Example 5: Add New Development Tools
**Operation**: "Add Rust development environment to both platforms"
**Analysis**: Multiple file edits, cross-platform considerations
**Complexity Score**: 0.6 (medium)
**Selection**: Feature-based → Serena for planning, Morphllm for implementation
**Rationale**: Need semantic analysis for integration, then pattern-based edits