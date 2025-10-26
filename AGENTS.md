# AGENTS.md - NixOS Configuration Codebase Guide

## Build/Lint/Test Commands
- Format: `make format` or `nix fmt .`
- Lint/check: `make lint` or `nix fmt -- --check .`
- Rebuild system: `make rebuild` (auto-detects macOS/NixOS)
- Full check: `make check` (runs lint + `nix flake check --show-trace`)
- Update flake: `make update` (updates flake.lock)

## Code Style
- Language: Nix (flake-based configuration)
- Formatter: `nixpkgs-fmt` (defined in flake.nix:160)
- Imports: Use named arguments `{ lib, pkgs, config, ... }:` at top
- Use `inherit` for cleaner variable passing: `inherit (lib) mkIf mkEnableOption;`
- Options: Define with `lib.mkOption` or `lib.mkEnableOption`
- Naming: camelCase for variables, kebab-case for module files
- Module structure: imports → options → config pattern
- Custom lib: Available as `jvfLib` in specialArgs (see flake.nix:86)
- Import pattern: `jvfLib.filesystem.importModulesInDir` for directory modules
- Never commit secrets; use sops-nix for sensitive data
- No comments unless documenting complex logic
