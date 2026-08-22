# Implementation Plan: Nix Sandbox Development Environments

## Overview

This plan details the step-by-step implementation of the **Flake Templates** system for creating isolated, reproducible sandbox development environments. The implementation follows the "Flakes + process-compose with Central Library" approach from research, providing maximum control while keeping logic centralized.

**Related Documents**:
- [research.md](./research.md) - Solution evaluation and selection
- [spec.md](./spec.md) - Functional and non-functional requirements

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ~/.config/nix (Central Config)                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  flake.nix                                                       │   │
│  │  ├── outputs.lib.${system}.mkSandboxShell  ← Library function    │   │
│  │  ├── outputs.lib.${system}.pkgs            ← Package set access  │   │
│  │  └── outputs.templates.*                   ← Template registry   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  lib/                                                            │   │
│  │  ├── default.nix   ← Exports all lib modules                     │   │
│  │  └── sandbox.nix   ← NEW: mkSandboxShell implementation          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  templates/                                                      │   │
│  │  └── sandbox-postgres-ruby/                                      │   │
│  │      ├── flake.nix     ← Minimal project flake                   │   │
│  │      └── .gitignore    ← Ignore .sandbox-state/                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Project (After nix flake init)                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  flake.nix  ─────────┐                                          │   │
│  │  .gitignore          │  References central lib                  │   │
│  └──────────────────────┼──────────────────────────────────────────┘   │
│                         ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  .sandbox-state/  (generated on sandbox-up)                     │   │
│  │  ├── postgres/           ← PostgreSQL data                      │   │
│  │  ├── postgres-socket/    ← Unix socket                          │   │
│  │  ├── postgres.log        ← PostgreSQL logs                      │   │
│  │  └── process-compose.log ← Process manager logs                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Core Library (`lib/sandbox.nix`)

**Goal**: Create the central `mkSandboxShell` function that all templates will use.

**Priority**: Critical  
**Estimated Effort**: 2-3 hours

#### Step 1.1: Create `lib/sandbox.nix`

Create the file at `lib/sandbox.nix` with the following structure:

```nix
{ pkgs, system }:

{
  projectRoot,
  services ? { postgres = true; },
  packages ? [],
  env ? {},
  shellHook ? "",
}:

let
  # Port isolation via path hashing
  projectHash = builtins.hashString "sha256" (toString projectRoot);
  # Extract first 8 hex chars, convert to int, mod 1000
  portOffset = pkgs.lib.mod (
    builtins.foldl' (acc: c: acc * 16 + (
      if c >= "0" && c <= "9" then builtins.fromJSON c
      else if c == "a" then 10
      else if c == "b" then 11
      else if c == "c" then 12
      else if c == "d" then 13
      else if c == "e" then 14
      else 15
    )) 0 (pkgs.lib.stringToCharacters (builtins.substring 0 8 projectHash))
  ) 1000;
  pgPort = 5432 + portOffset;

  # State directories
  stateDir = "${toString projectRoot}/.sandbox-state";
  pgDataDir = "${stateDir}/postgres";
  pgSocketDir = "${stateDir}/postgres-socket";

  # PostgreSQL initialization script
  pgSetup = pkgs.writeShellScriptBin "sandbox-pg-setup" ''
    set -e
    mkdir -p "${pgDataDir}" "${pgSocketDir}"
    if [ ! -f "${pgDataDir}/PG_VERSION" ]; then
      echo "Initializing PostgreSQL..."
      ${pkgs.postgresql_16}/bin/initdb -D "${pgDataDir}" --no-locale --encoding=UTF8
      
      cat >> "${pgDataDir}/postgresql.conf" << EOF
port = ${toString pgPort}
unix_socket_directories = '${pgSocketDir}'
listen_addresses = '127.0.0.1'
EOF
      
      ${pkgs.postgresql_16}/bin/pg_ctl -D "${pgDataDir}" -l "${stateDir}/postgres.log" start -w
      ${pkgs.postgresql_16}/bin/createdb -p ${toString pgPort} -h "${pgSocketDir}" development || true
      ${pkgs.postgresql_16}/bin/pg_ctl -D "${pgDataDir}" stop -m fast
      echo "PostgreSQL initialized on port ${toString pgPort}"
    fi
  '';

  # process-compose configuration
  processComposeYaml = pkgs.writeText "process-compose.yaml" ''
    version: "0.5"
    log_location: ${stateDir}/process-compose.log
    
    processes:
      ${pkgs.lib.optionalString (services.postgres or false) ''
      postgres:
        command: ${pkgs.postgresql_16}/bin/postgres -D ${pgDataDir}
        readiness_probe:
          exec:
            command: ${pkgs.postgresql_16}/bin/pg_isready -p ${toString pgPort} -h ${pgSocketDir}
          initial_delay_seconds: 1
          period_seconds: 2
        availability:
          restart: on_failure
      ''}
  '';

  # Command scripts
  sandboxUp = pkgs.writeShellScriptBin "sandbox-up" ''
    ${pgSetup}/bin/sandbox-pg-setup
    exec ${pkgs.process-compose}/bin/process-compose up -f ${processComposeYaml} "$@"
  '';

  sandboxDown = pkgs.writeShellScriptBin "sandbox-down" ''
    ${pkgs.process-compose}/bin/process-compose down -f ${processComposeYaml} || true
    echo "Services stopped."
  '';

  sandboxStatus = pkgs.writeShellScriptBin "sandbox-status" ''
    echo "=== Sandbox Status ==="
    echo "PostgreSQL port: ${toString pgPort}"
    echo "State directory: ${stateDir}"
    echo ""
    ${pkgs.process-compose}/bin/process-compose ps -f ${processComposeYaml} 2>/dev/null || echo "Services not running"
  '';

in pkgs.mkShell {
  packages = [
    pkgs.process-compose
    pkgs.postgresql_16
    sandboxUp
    sandboxDown
    sandboxStatus
    pgSetup
  ] ++ packages;

  shellHook = ''
    export SANDBOX_ROOT="${toString projectRoot}"
    export SANDBOX_STATE="${stateDir}"
    export PGDATA="${pgDataDir}"
    export PGPORT="${toString pgPort}"
    export PGHOST="${pgSocketDir}"
    export DATABASE_URL="postgresql://localhost:${toString pgPort}/development?host=${pgSocketDir}"
    
    # Inherit host configs for code agents
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
    
    ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}
    
    echo ""
    echo "🚀 Sandbox environment ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 PostgreSQL port: ${toString pgPort}"
    echo "📁 State: ${stateDir}"
    echo ""
    echo "Commands:"
    echo "  sandbox-up      Start all services"
    echo "  sandbox-down    Stop all services"
    echo "  sandbox-status  Show service status"
    echo ""
    
    ${shellHook}
  '';
}
```

**Key Implementation Details**:

1. **Port Hashing Algorithm**: 
   - Hash the `projectRoot` path using SHA256
   - Take first 8 hex characters
   - Convert to integer and mod 1000
   - Add to base port 5432 → range 5432-6431

2. **State Isolation**:
   - All state in `.sandbox-state/` under project root
   - PostgreSQL data, socket, and logs are project-local

3. **Service Management**:
   - process-compose handles service lifecycle
   - Readiness probes ensure PostgreSQL is ready before reporting success

4. **XDG Passthrough**:
   - Preserves host's `XDG_CONFIG_HOME` and `XDG_DATA_HOME`
   - Enables code agents to access their configs

---

#### Step 1.2: Update `lib/default.nix`

Modify `lib/default.nix` to export the sandbox module:

```nix
{ lib
, pkgs
, ...
}:

let
  generators = import ./generators.nix { inherit lib pkgs; };
  filesystem = import ./filesystem.nix { inherit lib pkgs generators; };
  git = import ./git.nix { inherit lib pkgs; };
  aiTools = import ./ai-tools.nix { inherit lib pkgs; };
  strings = import ./strings.nix { inherit lib pkgs; };
  sandbox = import ./sandbox.nix { inherit pkgs; system = pkgs.system; };
in
{
  inherit
    generators
    filesystem
    git
    aiTools
    strings
    sandbox
    ;
  
  # Direct export for template convenience
  mkSandboxShell = sandbox;
}
```

**Note**: The `sandbox` function requires `system` to be passed. We'll need to ensure this is available.

---

### Phase 2: Flake Integration

**Goal**: Update `flake.nix` to export the library function and templates.

**Priority**: Critical  
**Estimated Effort**: 1-2 hours

#### Step 2.1: Modify `flake.nix` Outputs

Update the `flake.nix` to properly export `lib` per-system and add templates:

```nix
# Add after line 119 (after forAllSystems definition):

    in
    {
      # Updated lib export - now per-system attrset
      lib = forAllSystems (system:
        let
          pkgs = mkPkgs system;
          baseLib = import ./lib {
            lib = pkgs.lib;
            inherit pkgs;
          };
        in
        baseLib // {
          inherit pkgs;  # Expose pkgs for template package access
          mkSandboxShell = import ./lib/sandbox.nix { inherit pkgs system; };
        }
      );

      # NEW: Template registry
      templates = {
        sandbox-postgres-ruby = {
          path = ./templates/sandbox-postgres-ruby;
          description = "Sandbox with PostgreSQL 16 and Ruby 3.3";
        };
      };

      # Existing configurations remain unchanged
      nixosConfigurations = { ... };
      darwinConfigurations = { ... };
      formatter = ...;
    };
```

**Critical Changes**:

1. `lib` output changes from a function to a per-system attrset
2. Each system's lib includes:
   - All existing lib functions (`generators`, `filesystem`, etc.)
   - `pkgs` - the package set for that system
   - `mkSandboxShell` - the sandbox builder function
3. New `templates` output for `nix flake init -t` support

---

#### Step 2.2: Update `specialArgsFor` (Internal References)

The current `specialArgsFor` function imports `./lib` directly. This needs updating to use the new structure:

```nix
# In specialArgsFor, change:
inputs = inputs // {
  inherit self;
  lib = import ./lib {
    lib = pkgs.lib;
    inherit pkgs;
  };
};

# To:
inputs = inputs // {
  inherit self;
  lib = import ./lib {
    lib = pkgs.lib;
    inherit pkgs;
  } // {
    mkSandboxShell = import ./lib/sandbox.nix { inherit pkgs; system = systemArc; };
  };
};
```

---

### Phase 3: Template Creation

**Goal**: Create the first template (`sandbox-postgres-ruby`).

**Priority**: High  
**Estimated Effort**: 1 hour

#### Step 3.1: Create Template Directory

```bash
mkdir -p templates/sandbox-postgres-ruby
```

#### Step 3.2: Create `templates/sandbox-postgres-ruby/flake.nix`

```nix
{
  description = "Project with PostgreSQL and Ruby sandbox";

  inputs = {
    nix-config.url = "path:/home/josevictor/.config/nix";
  };

  outputs = { self, nix-config, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs
        (map (s: { name = s; value = f s; }) systems);
    in
    {
      devShells = forAllSystems (system: {
        default = nix-config.lib.${system}.mkSandboxShell {
          projectRoot = ./.;
          services.postgres = true;
          packages = with nix-config.lib.${system}.pkgs; [
            ruby_3_3
            bundler
          ];
          env = {
            RUBY_VERSION = "3.3";
          };
        };
      });
    };
}
```

**Template Characteristics**:
- Minimal (~25 lines)
- References central `nix-config` via path
- Cross-platform support built-in
- Includes Ruby 3.3 + bundler + PostgreSQL

#### Step 3.3: Create `templates/sandbox-postgres-ruby/.gitignore`

```gitignore
# Sandbox state (generated, contains database data)
.sandbox-state/

# Nix build artifacts
result
result-*

# Flake lock (optional - remove this line if you want to lock versions)
# flake.lock
```

---

### Phase 4: Testing

**Goal**: Validate the implementation on both platforms.

**Priority**: High  
**Estimated Effort**: 1-2 hours

#### Step 4.1: Validate Flake Structure

```bash
# Check flake is valid
make check

# Verify template is registered
nix flake show .
```

Expected output should include:
```
├───lib: unknown
├───templates
│   └───sandbox-postgres-ruby: template: Sandbox with PostgreSQL 16 and Ruby 3.3
```

#### Step 4.2: Test Template Initialization (Linux)

```bash
# Create test directory
mkdir -p /tmp/test-sandbox && cd /tmp/test-sandbox

# Initialize from template
nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby

# Verify files created
ls -la
# Expected: flake.nix, .gitignore

# Enter development shell
nix develop --impure

# Verify environment
echo $PGPORT        # Should show port 5432-6431
echo $DATABASE_URL  # Should show full connection string
ruby --version      # Should show Ruby 3.3.x
bundler --version   # Should show bundler version

# Test sandbox commands
sandbox-status      # Should show "Services not running"
sandbox-up -d       # Start services in background
sandbox-status      # Should show PostgreSQL running
psql $DATABASE_URL -c "SELECT 1"  # Should return 1
sandbox-down        # Stop services

# Cleanup
cd / && rm -rf /tmp/test-sandbox
```

#### Step 4.3: Test Parallel Sandboxes

```bash
# Create two sandboxes
mkdir -p /tmp/sandbox-a /tmp/sandbox-b

# Initialize both
(cd /tmp/sandbox-a && nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby)
(cd /tmp/sandbox-b && nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby)

# In terminal 1:
cd /tmp/sandbox-a && nix develop --impure -c sandbox-up

# In terminal 2:
cd /tmp/sandbox-b && nix develop --impure -c sandbox-up

# Verify different ports
# sandbox-a and sandbox-b should have different $PGPORT values
# Both should be accessible simultaneously
```

#### Step 4.4: Test on Darwin (macOS)

Same tests as Step 4.2 but on aarch64-darwin system:
- Verify PostgreSQL starts correctly
- Verify Ruby/bundler available
- Verify port isolation works

---

### Phase 5: Documentation

**Goal**: Update documentation with usage instructions.

**Priority**: Medium  
**Estimated Effort**: 30 minutes

#### Step 5.1: Update CLAUDE.md

Add section to CLAUDE.md under "Common Patterns":

```markdown
### Sandbox Development Environments

Create isolated development environments with PostgreSQL using templates:

```bash
# Initialize a new Ruby project with PostgreSQL
cd /path/to/new-project
nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby

# Enter the sandbox
nix develop --impure

# Start services
sandbox-up -d

# Work with the database
psql $DATABASE_URL

# Stop services when done
sandbox-down
```

**Available Templates**:
- `sandbox-postgres-ruby` - PostgreSQL 16 + Ruby 3.3

**Sandbox Commands**:
- `sandbox-up` - Initialize and start all services
- `sandbox-down` - Stop all services
- `sandbox-status` - Show service status and ports
```

---

## Implementation Checklist

### Phase 1: Core Library
- [ ] Create `lib/sandbox.nix` with `mkSandboxShell` function
- [ ] Implement port hashing algorithm (deterministic, conflict-free)
- [ ] Implement PostgreSQL initialization script
- [ ] Implement process-compose configuration generation
- [ ] Create `sandbox-up`, `sandbox-down`, `sandbox-status` commands
- [ ] Set up XDG environment passthrough
- [ ] Update `lib/default.nix` to export sandbox

### Phase 2: Flake Integration
- [ ] Update `flake.nix` `lib` output to per-system attrset
- [ ] Add `pkgs` export to each system's lib
- [ ] Add `mkSandboxShell` export to each system's lib
- [ ] Add `templates` output with `sandbox-postgres-ruby`
- [ ] Update `specialArgsFor` for internal module compatibility

### Phase 3: Template Creation
- [ ] Create `templates/` directory
- [ ] Create `templates/sandbox-postgres-ruby/flake.nix`
- [ ] Create `templates/sandbox-postgres-ruby/.gitignore`

### Phase 4: Testing
- [ ] Run `make check` - flake validation
- [ ] Run `make lint` - formatting check
- [ ] Run `nix flake show` - verify template visible
- [ ] Test template init on x86_64-linux
- [ ] Test `nix develop` enters shell correctly
- [ ] Test `sandbox-up` starts PostgreSQL
- [ ] Test `sandbox-status` shows correct port
- [ ] Test `sandbox-down` stops services
- [ ] Test parallel sandboxes have different ports
- [ ] Test on aarch64-darwin (if available)

### Phase 5: Documentation
- [ ] Update CLAUDE.md with sandbox usage
- [ ] Update AGENTS.md if needed

---

## Risk Mitigation

### Risk 1: Port Collision Despite Hashing

**Risk**: Two projects hash to same port offset.  
**Probability**: Low (1/1000 per pair)  
**Mitigation**: 
- Port range is 1000 values - sufficient for typical use
- If collision occurs, user can override via `env.PGPORT` in project flake
- Future: Add collision detection in `sandbox-up`

### Risk 2: Cross-Platform Differences

**Risk**: process-compose or PostgreSQL behave differently on Darwin.  
**Probability**: Low  
**Mitigation**:
- Both packages are well-tested on Darwin
- Test on both platforms before merging
- PostgreSQL initialization uses platform-agnostic flags

### Risk 3: Flake Lock Conflicts

**Risk**: Template `flake.lock` conflicts with central config updates.  
**Probability**: Medium  
**Mitigation**:
- Template `.gitignore` comments out `flake.lock` by default
- Users can choose to commit their lock file
- `nix flake update` resolves conflicts

---

## Future Enhancements (Out of Scope)

1. **direnv Integration**: Auto-activate environment on `cd`
2. **Additional Templates**: 
   - `sandbox-postgres-node`
   - `sandbox-postgres-python`
   - `sandbox-redis-*`
3. **Service Additions**: Redis, Elasticsearch, MinIO
4. **Registry Setup**: `nix registry add nix-config path:...`
5. **Template Generator**: TUI for custom template creation

---

## Dependencies

| Component | Version | Purpose |
|-----------|---------|---------|
| `postgresql_16` | 16.x | Database server |
| `ruby_3_3` | 3.3.x | Ruby runtime |
| `bundler` | Latest | Ruby dependencies |
| `process-compose` | Latest | Service orchestration |

All dependencies are available in nixpkgs-unstable for both x86_64-linux and aarch64-darwin.

---

## Success Criteria

1. ✅ `nix flake init -t path:~/.config/nix#sandbox-postgres-ruby` creates valid project
2. ✅ `nix develop --impure` enters shell with correct environment
3. ✅ `sandbox-up` starts PostgreSQL on unique port
4. ✅ Multiple sandboxes run simultaneously without port conflicts
5. ✅ Code agents (Cursor, opencode) can access `DATABASE_URL`
6. ✅ Works on both x86_64-linux and aarch64-darwin
7. ✅ Central library update benefits all projects after `nix flake update`

---

*Plan Version: 1.0*  
*Created: 2026-01-09*  
*Feature: 001-nix-sandbox-dev-environments*
