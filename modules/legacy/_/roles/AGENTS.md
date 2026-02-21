# ROLES AGENTS

**Path:** `modules/roles/`
**Pattern:** Feature Bundles / Profiles

## OVERVIEW
Roles are the primary architecture for feature delivery. They bundle related programs, system settings, and packages into high-level opt-in profiles (e.g., `development`, `gaming`).

## STRUCTURE
```
modules/roles/
├── default.nix           # Role aggregation/imports
├── development.nix       # Core dev stack (NVim, Tmux, etc.)
├── ai-development.nix    # LLM/Agent tools
├── gaming.nix            # Steam, emulators, performance tweaks
└── ...                   # Specialized feature sets
```

## WHERE TO LOOK
- **Enable a Role**: `hosts/<hostname>/default.nix` or role-specific machine file.
- **Define New Role**: Create `<name>.nix` in `modules/roles/` and add to `default.nix`.
- **Bundle Logic**: Inside each role file using `lib.mkIf cfg.enable`.

## CONVENTIONS
- **Namespace**: `jvf.roles.<name>.enable` (Required).
- **Opt-in**: `default = false` (Required).
- **Username Passthrough**: Most roles accept a `username` option to install user-space packages.
- **Atomic Imports**: Roles should import the specific `modules/programs/` or `modules/system/` modules they need.

## ANTI-PATTERNS
- **Implicit Enabling**: Roles must NEVER be enabled by default.
- **Cross-Role Dependencies**: Roles should be independent. If shared logic exists, move to `modules/common`.
- **System-wide Bloat**: Avoid putting machine-specific hardware config in roles.
- **Home Manager**: BANNED. Roles use `users.users.<name>.packages` and native config.

## EXAMPLE
```nix
jvf.roles.development = {
  enable = true;
  username = "josevictorferreira";
};
```
