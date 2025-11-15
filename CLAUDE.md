# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a single-flake Nix configuration managing both NixOS (desktop) and Darwin (MacBook) systems without Home Manager. It uses a custom modular architecture with role-based configuration and SOPS for secret management.

## Common Commands

### Building and Deployment

```bash
# Rebuild system configuration (auto-detects platform)
make rebuild

# Rebuild NixOS only
sudo nixos-rebuild switch --flake .#nixos-desktop --show-trace

# Rebuild Darwin only
sudo darwin-rebuild switch --flake .#macos-macbook --show-trace

# Update flake inputs
sudo nix flake update

# Clean nix store
make clean
```

### Development and Linting

```bash
# Format all nix files
make format

# Check formatting (used in CI)
make lint

# Validate flake
make check
```

### Secrets Management

```bash
# Edit encrypted secrets
make secrets

# Update keys for secrets file
make up_keys
```

## Architecture

### Flake Structure

The `flake.nix` configures two systems from a single flake:
- **nixos-desktop**: x86_64-linux with Hyprland
- **macos-macbook**: aarch64-darwin

Separate nixpkgs inputs are used (`nixpkgs` for Linux, `nixpkgs-darwin` for macOS) to avoid compatibility issues.

### Module System (`jvf.*` namespace)

Custom module hierarchy that works across both platforms:

```nix
# Activation pattern in host configs
jvf.users.enable = true;
jvf.system.networking.enable = true;
jvf.system.nix-daemon.enable = true;
jvf.services.sops.enable = true;
jvf.roles.development.enable = true;
jfv.desktop.hyprland.enable = true;  # NixOS only
```

**Module organization:**
- `modules/system/` - Core system configuration (networking, locale, security, audio, etc.)
- `modules/services/` - Services (sops, polkit, ollama, virtualization)
- `modules/roles/` - Role definitions that compose program modules
- `modules/programs/` - Individual program configurations
- `modules/desktop/` - Desktop environment (Hyprland)
- `modules/hardware/` - Hardware-specific modules

### Role-Based Configuration

**9 composable roles** (activate in host config via `jvf.roles.<name>.enable = true`):

1. `development` - Core dev tools (git, neovim, zsh, tmux, terminals)
2. `aiDevelopment` - Vibe coding tools (Cursor, Goose, opencode, claudecode)
3. `opsDevelopment` - DevOps tools (kubectl, helm, awscli, k9s)
4. `monitoring` - Observability tools
5. `communication` - Chat/communication apps
6. `designing` - Design tools
7. `media` - Media consumption tools
8. `gaming` - Gaming platforms (Steam, Wine, Lutris) - NixOS only
9. `networkStorage` - NAS/storage tools

Each role module:
- Imports relevant program modules from `modules/programs/`
- Defines `options.jvf.roles.<name>.enable`
- Conditionally activates programs and adds user packages

### Host Configuration Pattern

Each host (nixos-desktop, macos-macbook) follows this structure:

1. **Imports modules** - All needed modules are imported at top
2. **Sets variables** - Uses `variables.nix` for host-specific values
3. **Activates base modules** - `jvf.users`, `jvf.system.*`, `jvf.services.*`
4. **Activates roles** - Selects which roles to enable
5. **Hardware config** - NixOS hosts include hardware-specific configuration

### Secret Management

Uses **SOPS with age encryption**:
- Secrets file: `secrets/secrets.enc.yaml`
- Keys located at `/etc/sops/age/keys.txt`
- SSH key must be converted to age format: `ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt`
- Service module auto-included in both NixOS and Darwin configs

### Custom Library Functions (`lib/`)

- `lib/generators.nix` - Custom config generators (TOML, YAML, INI)
  - Use `toFileFormatStr` for unified config generation
- `lib/filesystem.nix` - `modulesInDir` for auto-importing modules
- `lib/git.nix` - `cloneRepoText` for cross-platform git operations

### Key Design Decisions

1. **No Home Manager**: Intentionally avoided to maintain a unified configuration interface across NixOS and Darwin with simpler mental model.

2. **Username propagation**: Username is passed via `specialArgs` and referenced as `${username}` in configs.

3. **Explicit module activation**: All modules require explicit `enable = true` flag (no auto-enabling).

4. **User module structure**: User configuration is under `jvf.users.users.<username>` with required `enable` flags:
   ```nix
   jvf.users = {
     enable = true;
     users.${username} = {
       enable = true;
       description = "...";
       authorizedKeys = [ ... ];
     };
   };
   ```

5. **Platform divergence**: Some modules only work on specific platforms (e.g., Hyprland on NixOS, some gaming tools Linux-only). Modules should check `pkgs.system` or `os` flag when needed.

## Common Patterns

### Adding a New Program

1. Create module at `modules/programs/<name>.nix`
2. Define options under `jvf.programs.<name>`
3. Configure the program in the `config` section
4. Add to relevant role(s) or import directly in host config

### Adding a New Role

1. Create file at `modules/roles/<name>.nix`
2. Import needed program modules
3. Define `options.jvf.roles.<name>.enable`
4. In `config`, add packages and enable programs based on the flag
5. Import the role file in `modules/roles/default.nix`
6. Activate in host config via `jvf.roles.<name>.enable = true`

### Platform-Specific Code

```nix
# Check OS type
lib.optionalString (os == "nixos") ''
  # Linux-only code
''

# Or check system
lib.optionalString (pkgs.system == "x86_64-linux") ''
  # x86_64 Linux specific code
''
```
