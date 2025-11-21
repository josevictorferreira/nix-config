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
