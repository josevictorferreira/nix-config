# Research: Nix Sandbox Development Environments

## Executive Summary

This document researches solutions for creating isolated, reproducible sandbox development environments in Nix that work across both NixOS (Linux) and Darwin (macOS). The primary requirements include:

- **Cross-platform compatibility** (NixOS + Darwin)
- **Isolated PostgreSQL instances** per sandbox (no port conflicts)
- **Independent git repositories** per sandbox
- **Code agent integration** (Cursor, opencode, Claude) using host system configs
- **Parallel execution** without conflicts
- **Minimal per-project configuration**
- **Easy triggering** (no manual commands)

---

## Requirements Analysis

### Core Requirements

| Requirement | Priority | Challenge Level |
|-------------|----------|-----------------|
| Cross-platform (NixOS/Darwin) | Critical | Medium |
| Isolated PostgreSQL per sandbox | Critical | High |
| Own git repository version | Critical | Low |
| Code agent config from host | High | Medium |
| Parallel execution without conflicts | Critical | High |
| Minimal project-specific config | High | Medium |
| Easy to trigger/build | High | Low |

### Key Technical Challenges

1. **Port Isolation**: PostgreSQL instances must not conflict when running in parallel
2. **Data Isolation**: Each sandbox needs its own data directory
3. **Process Management**: Services must start/stop cleanly with the environment
4. **Configuration Inheritance**: Code agents must access host configs while running in sandbox
5. **Cross-Platform Parity**: Solutions must work identically on Linux and macOS

---

## Primary Recommendation: devenv + process-compose

### Overview

**devenv** (https://devenv.sh) is the most elegant solution for this use case. It's a Nix-based developer environment tool built specifically for the challenges described. It provides:

- Native support for services (PostgreSQL, Redis, etc.) with automatic port allocation
- Process management via process-compose
- Cross-platform support (NixOS + Darwin)
- direnv integration for automatic environment loading
- Declarative configuration via `devenv.nix`

### Why This is the "Elegant" Solution

1. **Zero Configuration Services**: PostgreSQL just works with automatic port isolation
2. **Single File Setup**: One `devenv.nix` per project
3. **Automatic Environment Activation**: Combined with direnv, environments activate on `cd`
4. **Built-in Process Management**: Uses process-compose under the hood
5. **Maintained by Cachix Team**: Active development, good documentation

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Host System (NixOS/Darwin)                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Host Configs (~/.config/cursor, etc.)        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│       ┌──────────────────────┼──────────────────────┐          │
│       ▼                      ▼                      ▼          │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐   │
│  │ Sandbox A   │       │ Sandbox B   │       │ Sandbox N   │   │
│  │ ─────────── │       │ ─────────── │       │ ─────────── │   │
│  │ PostgreSQL  │       │ PostgreSQL  │       │ PostgreSQL  │   │
│  │ Port: Auto  │       │ Port: Auto  │       │ Port: Auto  │   │
│  │ Data: ./.   │       │ Data: ./.   │       │ Data: ./.   │   │
│  │ Git: Own    │       │ Git: Own    │       │ Git: Own    │   │
│  │ Agent: ✓    │       │ Agent: ✓    │       │ Agent: ✓    │   │
│  └─────────────┘       └─────────────┘       └─────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation

#### Base Configuration (`devenv.nix`)

```nix
{ pkgs, lib, config, ... }:

{
  # Core packages available in the sandbox
  packages = with pkgs; [
    git
    # Add project-specific tools here
  ];

  # PostgreSQL service with automatic isolation
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
    
    # Each devenv instance gets its own data directory
    # Default: .devenv/state/postgres
    
    # Automatic port allocation - no conflicts!
    listen_addresses = "127.0.0.1";
    
    # Initial setup
    initialDatabases = [
      { name = "development"; }
    ];
    
    initialScript = ''
      CREATE USER dev WITH SUPERUSER PASSWORD 'dev';
    '';
  };

  # Environment variables (auto-set when entering shell)
  env = {
    DATABASE_URL = "postgresql://dev:dev@127.0.0.1:${toString config.services.postgres.port}/development";
    # Inherit host configs for code agents
    XDG_CONFIG_HOME = builtins.getEnv "XDG_CONFIG_HOME";
  };

  # Process management
  processes = {
    # Add custom background processes here
  };

  # Scripts available in the environment
  scripts = {
    dev.exec = ''
      echo "Starting development environment..."
      echo "PostgreSQL running on port: ${toString config.services.postgres.port}"
    '';
    
    db-shell.exec = ''
      psql $DATABASE_URL
    '';
  };

  # Enter shell hook
  enterShell = ''
    echo "🚀 Sandbox environment activated"
    echo "📦 PostgreSQL: port ${toString config.services.postgres.port}"
    echo "📁 Data directory: .devenv/state/postgres"
  '';
}
```

#### Flake Integration (`flake.nix`)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" "aarch64-linux" "x86_64-darwin" ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit system;
      });
    in
    {
      devShells = forEachSystem ({ pkgs, system }: {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [ ./devenv.nix ];
        };
      });
    };
}
```

#### Automatic Environment Activation (`.envrc`)

```bash
# .envrc
if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" \
    "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
fi

use flake . --impure
```

### Code Agent Integration

Code agents (Cursor, opencode, Claude Code) can be run inside the devenv sandbox while accessing host configurations:

```nix
{ pkgs, ... }:

{
  # Expose host config directories to the sandbox
  env = {
    # Cursor configuration
    CURSOR_CONFIG_DIR = "${builtins.getEnv "HOME"}/.config/cursor";
    
    # OpenCode configuration  
    OPENCODE_CONFIG = "${builtins.getEnv "HOME"}/.config/opencode";
    
    # Claude Code configuration
    CLAUDE_CONFIG = "${builtins.getEnv "HOME"}/.config/claude";
    
    # General XDG directories
    XDG_CONFIG_HOME = builtins.getEnv "XDG_CONFIG_HOME";
    XDG_DATA_HOME = builtins.getEnv "XDG_DATA_HOME";
  };

  # Make code agents available in sandbox
  packages = with pkgs; [
    # These will use the host configs via env vars
  ];

  scripts = {
    # Wrapper to run code agent with proper environment
    run-agent.exec = ''
      # Agent sandbox modes already handle isolation
      # They just need access to their configs
      exec "$@"
    '';
  };
}
```

### Port Isolation Mechanism

devenv uses a clever approach for port isolation:

1. **Hash-based Port Assignment**: Port numbers are derived from a hash of the project path
2. **Process Compose Integration**: Services are managed by process-compose with unique namespaces
3. **State Directory Isolation**: Each project gets `.devenv/state/` for service data

```nix
# Example of how devenv calculates ports (internal logic)
# Port = 5432 + (hash(project_path) % 1000)
# This ensures deterministic but unique ports per project
```

### Triggering the Sandbox

**Option 1: Automatic with direnv**
```bash
# Simply cd into the project directory
cd /path/to/project
# Environment activates automatically
# Services start with: devenv up
```

**Option 2: Manual activation**
```bash
# Enter the shell
nix develop --impure

# Start services
devenv up
```

**Option 3: One-liner**
```bash
# Start everything
devenv up
```

### References & Sources

- **devenv Documentation**: https://devenv.sh/
- **devenv GitHub**: https://github.com/cachix/devenv
- **devenv Services**: https://devenv.sh/services/
- **process-compose**: https://github.com/F1bonacc1/process-compose
- **Nix Flakes RFC**: https://github.com/NixOS/rfcs/pull/49

---

## Alternative 1: Flakes + process-compose (Manual Approach)

### Overview

For those who prefer more control or can't use devenv, a custom solution using Nix Flakes with process-compose provides similar functionality with more explicit configuration.

### Why Choose This Alternative

- **More Control**: Fine-grained control over every aspect
- **No Additional Dependencies**: Uses only Nix + process-compose
- **Educational**: Better understanding of underlying mechanisms
- **Customizable**: Can implement unique isolation strategies

---

### Global Configuration vs Per-Project: The Architecture

**Key Question**: Does every project need its own full flake configuration?

**Answer**: No! There are three strategies to avoid duplication:

#### Strategy 1: Central Flake as Library (Recommended)

Your central nix-config exports a `mkSandboxShell` function that projects consume:

```
┌─────────────────────────────────────────────────────────────────┐
│           ~/.config/nix/flake.nix (Central Config)              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  outputs.lib.mkSandboxShell = { ... }: mkShell { ... };   │  │
│  │  outputs.lib.sandboxServices = { postgres, redis, ... };  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ Project A     │     │ Project B     │     │ Project C     │
│ flake.nix     │     │ flake.nix     │     │ flake.nix     │
│ (5-10 lines)  │     │ (5-10 lines)  │     │ (5-10 lines)  │
└───────────────┘     └───────────────┘     └───────────────┘
```

**Central config exports the library, projects have minimal flakes.**

#### Strategy 2: Flake Templates

Use `nix flake init -t` to scaffold projects from templates defined in central config.

#### Strategy 3: Flake Registry

Register central flake globally so projects reference it by name without paths.

---

### How the Flake System Works

#### What IS a Flake?

A flake is a self-contained Nix project with:
1. **Inputs**: Dependencies (other flakes, nixpkgs, etc.)
2. **Outputs**: What the flake provides (packages, shells, lib functions, etc.)

```nix
{
  inputs = { ... };   # What this flake depends on
  outputs = { ... };  # What this flake provides
}
```

#### The Central Flake (Your nix-config)

Your existing `~/.config/nix/flake.nix` already exports `lib`. We extend it to export sandbox utilities:

```nix
# In your existing flake.nix, add to outputs:
{
  # ... existing outputs ...

  # Export sandbox library for all systems
  lib = forAllSystems (system:
    let
      pkgs = mkPkgs system;
    in
    (import ./lib { lib = pkgs.lib; inherit pkgs; }) // {
      # NEW: Sandbox shell builder
      mkSandboxShell = import ./lib/sandbox.nix { inherit pkgs system; };
    }
  );

  # NEW: Flake templates for quick project setup
  templates = {
    sandbox = {
      path = ./templates/sandbox;
      description = "Isolated sandbox development environment";
    };
    sandbox-postgres = {
      path = ./templates/sandbox-postgres;
      description = "Sandbox with PostgreSQL";
    };
  };
}
```

#### The Library Function (`lib/sandbox.nix`)

This is where ALL the complexity lives - once, in one place:

```nix
# lib/sandbox.nix
{ pkgs, system }:

{ 
  # Required: Project root path (for unique port generation)
  projectRoot,
  
  # Optional: Services to enable
  services ? { postgres = true; },
  
  # Optional: Extra packages
  packages ? [],
  
  # Optional: Environment variables
  env ? {},
  
  # Optional: Shell hooks
  shellHook ? "",
}:

let
  # Generate unique port based on project path hash
  projectHash = builtins.hashString "sha256" (toString projectRoot);
  pgPort = 5432 + (pkgs.lib.mod (builtins.fromTOML "{x=${builtins.substring 0 8 projectHash}}").x 1000);
  
  # State directories (project-local)
  stateDir = "${toString projectRoot}/.sandbox-state";
  pgDataDir = "${stateDir}/postgres";
  pgSocketDir = "${stateDir}/postgres-socket";
  
  # PostgreSQL setup script
  pgSetup = pkgs.writeShellScriptBin "sandbox-pg-setup" ''
    set -e
    mkdir -p ${pgDataDir} ${pgSocketDir}
    if [ ! -f ${pgDataDir}/PG_VERSION ]; then
      echo "Initializing PostgreSQL..."
      ${pkgs.postgresql_16}/bin/initdb -D ${pgDataDir} --no-locale --encoding=UTF8
      
      cat >> ${pgDataDir}/postgresql.conf << EOF
    port = ${toString pgPort}
    unix_socket_directories = '${pgSocketDir}'
    listen_addresses = '127.0.0.1'
    EOF
      
      ${pkgs.postgresql_16}/bin/pg_ctl -D ${pgDataDir} -l ${stateDir}/postgres.log start -w
      ${pkgs.postgresql_16}/bin/createdb -p ${toString pgPort} -h ${pgSocketDir} development || true
      ${pkgs.postgresql_16}/bin/pg_ctl -D ${pgDataDir} stop
      echo "PostgreSQL initialized on port ${toString pgPort}"
    fi
  '';
  
  # Process-compose configuration
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
  
  # Wrapper scripts
  sandboxUp = pkgs.writeShellScriptBin "sandbox-up" ''
    ${pgSetup}/bin/sandbox-pg-setup
    exec ${pkgs.process-compose}/bin/process-compose up -f ${processComposeYaml} "$@"
  '';
  
  sandboxDown = pkgs.writeShellScriptBin "sandbox-down" ''
    ${pkgs.process-compose}/bin/process-compose down -f ${processComposeYaml}
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

---

### Project-Side Configuration (Minimal!)

Each project only needs a tiny `flake.nix`:

#### Option A: Direct Reference (Recommended)

```nix
# /path/to/my-project/flake.nix
{
  description = "My Project";

  inputs = {
    # Reference your central nix-config
    nix-config.url = "path:/home/josevictor/.config/nix";
    # Or via git:
    # nix-config.url = "github:yourusername/nix-config";
  };

  outputs = { self, nix-config }:
    let
      # Get the sandbox builder for your system
      mkSandbox = nix-config.lib.x86_64-linux.mkSandboxShell;
      # For macOS: nix-config.lib.aarch64-darwin.mkSandboxShell
    in
    {
      devShells.x86_64-linux.default = mkSandbox {
        projectRoot = ./.;
        
        # That's it! PostgreSQL is enabled by default
        # Optional customization:
        # services.postgres = true;
        # packages = [ pkgs.nodejs ];
        # env.MY_VAR = "value";
      };
      
      # For macOS support too:
      devShells.aarch64-darwin.default = 
        nix-config.lib.aarch64-darwin.mkSandboxShell {
          projectRoot = ./.;
        };
    };
}
```

**That's only ~20 lines per project!**

#### Option B: Using Flake Registry (Even Shorter)

First, register your config globally:

```bash
# One-time setup
nix registry add nix-config path:/home/josevictor/.config/nix
```

Then projects can use:

```nix
# /path/to/my-project/flake.nix
{
  inputs.nix-config.url = "flake:nix-config";  # Uses registry!
  
  outputs = { nix-config, ... }: {
    devShells.x86_64-linux.default = 
      nix-config.lib.x86_64-linux.mkSandboxShell { projectRoot = ./.; };
  };
}
```

#### Option C: Using Templates (Zero Manual Flake Writing)

With templates defined in central config:

```bash
# In a new project directory
cd /path/to/new-project
nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres

# Or with registry:
nix flake init -t nix-config#sandbox-postgres
```

This copies a pre-made `flake.nix` template to the project.

---

### Complete Central Config Integration

Here's how to integrate with your existing flake structure:

```nix
# ~/.config/nix/flake.nix (additions to existing file)
{
  # ... existing inputs ...

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      # ... existing let bindings ...
      
      # Sandbox library for each system
      mkSandboxLib = system:
        let pkgs = mkPkgs system;
        in import ./lib/sandbox.nix { inherit pkgs system; };
        
    in
    {
      # ... existing outputs (nixosConfigurations, darwinConfigurations, etc.) ...

      # NEW: Export sandbox library
      lib = forAllSystems (system:
        let
          pkgs = mkPkgs system;
          baseLib = import ./lib { lib = pkgs.lib; inherit pkgs; };
        in
        baseLib // {
          mkSandboxShell = mkSandboxLib system;
        }
      );

      # NEW: Project templates
      templates = {
        sandbox = {
          path = ./templates/sandbox;
          description = "Basic sandbox environment";
        };
        sandbox-postgres = {
          path = ./templates/sandbox-postgres;
          description = "Sandbox with PostgreSQL";
        };
        sandbox-full = {
          path = ./templates/sandbox-full;
          description = "Full sandbox with PostgreSQL, Redis, and more";
        };
      };
    };
}
```

---

### Template Example

```nix
# ~/.config/nix/templates/sandbox-postgres/flake.nix
{
  description = "Project with PostgreSQL sandbox";

  inputs.nix-config.url = "path:/home/josevictor/.config/nix";

  outputs = { nix-config, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (s: { name = s; value = f s; }) systems);
    in
    {
      devShells = forAllSystems (system: {
        default = nix-config.lib.${system}.mkSandboxShell {
          projectRoot = ./.;
          services.postgres = true;
          # Add project-specific customization below:
          # packages = with nix-config.lib.${system}.pkgs; [ nodejs ];
          # env.NODE_ENV = "development";
        };
      });
    };
}
```

---

### Summary: Global vs Per-Project

| Aspect | Central Config | Per-Project |
|--------|----------------|-------------|
| **Complexity** | All logic here | Minimal (5-20 lines) |
| **Maintenance** | Update once, all projects benefit | Just reference central |
| **Port allocation** | Automatic via hash | Just provide `projectRoot` |
| **Service configs** | Pre-defined, toggle on/off | Optional overrides |
| **Code agent configs** | Auto-inherited from host | No action needed |

---

### How Flakes Enable This Architecture

#### The "Why" Behind Flakes for Sandboxes

Flakes solve key problems for sandbox environments:

1. **Hermetic Evaluation**: All inputs are locked (`flake.lock`), so environments are reproducible
2. **Composability**: Flakes can import other flakes as inputs
3. **Output Schema**: Standardized outputs (`devShells`, `lib`, `templates`) that tools understand
4. **Cross-Project Sharing**: One flake's outputs can be consumed by another

#### Flake Anatomy for Sandbox Use

```nix
{
  # INPUTS: Dependencies this flake needs
  inputs = {
    nixpkgs.url = "...";           # Base packages
    nix-config.url = "...";        # Your central config (for library functions)
  };

  # OUTPUTS: What this flake provides
  outputs = { self, nixpkgs, nix-config, ... }: {
    
    # devShells.<system>.default - activated by `nix develop`
    devShells.x86_64-linux.default = <derivation>;
    
    # lib.<system> - library functions other flakes can import
    lib.x86_64-linux = { mkSandboxShell = ...; };
    
    # templates.<name> - scaffolding for `nix flake init -t`
    templates.sandbox = { path = ./templates/sandbox; };
  };
}
```

#### The Flow When You Run `nix develop`

```
1. User runs: cd /path/to/project && nix develop

2. Nix reads: /path/to/project/flake.nix
   → Sees input: nix-config.url = "path:/home/josevictor/.config/nix"

3. Nix fetches: /home/josevictor/.config/nix/flake.nix
   → Evaluates its outputs.lib.x86_64-linux.mkSandboxShell

4. Project flake calls: mkSandboxShell { projectRoot = ./.; }
   → Returns a derivation (shell environment)

5. Nix builds the shell:
   → Installs packages
   → Sets environment variables
   → Runs shellHook

6. User is dropped into isolated sandbox shell
   → PostgreSQL configured for unique port
   → sandbox-up/down commands available
```

#### Why This is Powerful

- **Central config changes propagate**: Update `lib/sandbox.nix` once, run `nix flake update` in projects
- **Lock file guarantees reproducibility**: Each project's `flake.lock` pins exact versions
- **No copying**: Projects don't copy logic, they call library functions
- **Type-safe composition**: Nix evaluates the entire dependency graph before building

---

### Implementation (Standalone Example - Without Central Library)

This is the full standalone version if you want everything in one project flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Generate unique port based on project path hash
        projectHash = builtins.hashString "sha256" (toString ./.);
        basePort = 5432 + (builtins.fromJSON 
          (builtins.substring 0 4 projectHash) % 1000);
        
        # Sandbox-specific paths
        stateDir = "./.sandbox-state";
        pgDataDir = "${stateDir}/postgres";
        pgSocketDir = "${stateDir}/postgres-socket";
        
        # PostgreSQL wrapper with isolated data directory
        pgSetup = pkgs.writeShellScriptBin "pg-setup" ''
          mkdir -p ${pgDataDir} ${pgSocketDir}
          if [ ! -f ${pgDataDir}/PG_VERSION ]; then
            ${pkgs.postgresql_16}/bin/initdb -D ${pgDataDir}
            
            # Configure for isolation
            cat >> ${pgDataDir}/postgresql.conf << EOF
          port = ${toString basePort}
          unix_socket_directories = '${pgSocketDir}'
          listen_addresses = '127.0.0.1'
          EOF
            
            # Create initial database
            ${pkgs.postgresql_16}/bin/pg_ctl -D ${pgDataDir} start -w
            ${pkgs.postgresql_16}/bin/createdb -p ${toString basePort} development
            ${pkgs.postgresql_16}/bin/pg_ctl -D ${pgDataDir} stop
          fi
        '';
        
        # process-compose configuration
        processComposeConfig = pkgs.writeText "process-compose.yaml" ''
          version: "0.5"
          
          processes:
            postgres:
              command: ${pkgs.postgresql_16}/bin/postgres -D ${pgDataDir}
              readiness_probe:
                exec:
                  command: ${pkgs.postgresql_16}/bin/pg_isready -p ${toString basePort}
                initial_delay_seconds: 2
                period_seconds: 2
              availability:
                restart: on_failure
        '';
        
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            postgresql_16
            process-compose
            git
          ];
          
          shellHook = ''
            export SANDBOX_ROOT="$(pwd)"
            export PGDATA="${pgDataDir}"
            export PGPORT="${toString basePort}"
            export PGHOST="${pgSocketDir}"
            export DATABASE_URL="postgresql://localhost:${toString basePort}/development"
            
            # Initialize PostgreSQL if needed
            ${pgSetup}/bin/pg-setup
            
            echo "🚀 Sandbox environment ready"
            echo "📦 PostgreSQL port: ${toString basePort}"
            echo "📁 State directory: ${stateDir}"
            echo ""
            echo "Run 'process-compose up -f ${processComposeConfig}' to start services"
            
            # Alias for convenience
            alias sandbox-up="process-compose up -f ${processComposeConfig}"
            alias sandbox-down="process-compose down"
          '';
        };
      }
    );
}
```

### Advantages

- Complete transparency in how isolation works
- Can customize port allocation strategy
- Easier to debug issues
- No dependency on devenv infrastructure

### Disadvantages

- More boilerplate code
- Manual management of many features devenv handles
- Need to maintain process-compose configs manually
- Less polished developer experience

### References

- **Nix Flakes Manual**: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html
- **process-compose**: https://github.com/F1bonacc1/process-compose
- **Nix Dev Shells**: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell

---

## Alternative 2: arion (Docker Compose via Nix)

### Overview

**arion** (https://docs.hercules-ci.com/arion/) provides Docker Compose-like functionality defined purely in Nix. This offers stronger isolation through containerization while maintaining the declarative Nix approach.

### Why Choose This Alternative

- **Strongest Isolation**: Full container isolation
- **Docker Ecosystem**: Compatible with Docker images
- **Network Isolation**: Built-in network namespacing
- **Production Parity**: Similar to production container setups

### Implementation

#### Flake Configuration (`flake.nix`)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    arion.url = "github:hercules-ci/arion";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, arion, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Arion project definition
        arionProjects.default = {
          imports = [ ./arion-compose.nix ];
          pkgs = pkgs;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            arion.packages.${system}.arion
            pkgs.docker
          ];

          shellHook = ''
            echo "🐳 Arion sandbox environment"
            echo "Run 'arion up -d' to start containers"
            echo "Run 'arion down' to stop containers"
          '';
        };
      }
    );
}
```

#### Arion Compose (`arion-compose.nix`)

```nix
{ pkgs, ... }:

{
  # Each project gets a unique network
  project.name = "sandbox-${builtins.hashString "sha256" (toString ./.) |> builtins.substring 0 8}";

  services = {
    postgres = {
      service = {
        image = "postgres:16-alpine";
        
        # Port mapping - host port is dynamic based on project
        ports = [
          # Leave host port empty for automatic assignment
          "5432"
        ];
        
        environment = {
          POSTGRES_USER = "dev";
          POSTGRES_PASSWORD = "dev";
          POSTGRES_DB = "development";
        };
        
        volumes = [
          # Project-local data persistence
          "./.sandbox-state/postgres:/var/lib/postgresql/data"
        ];
        
        # Health check
        healthcheck = {
          test = [ "CMD-SHELL" "pg_isready -U dev" ];
          interval = "5s";
          timeout = "5s";
          retries = 5;
        };
      };
    };

    # Development container with code agent access
    dev = {
      service = {
        # Use Nix-built image
        useHostStore = true;
        
        # Mount host configs for code agents
        volumes = [
          "~/.config/cursor:~/.config/cursor:ro"
          "~/.config/opencode:~/.config/opencode:ro"
          ".:/workspace"
        ];
        
        working_dir = "/workspace";
        
        # Keep container running for exec
        command = [ "sleep" "infinity" ];
        
        depends_on = {
          postgres = {
            condition = "service_healthy";
          };
        };
        
        environment = {
          DATABASE_URL = "postgresql://dev:dev@postgres:5432/development";
        };
      };
    };
  };
}
```

### macOS Considerations

On Darwin, Docker Desktop or colima is required:

```nix
# Darwin-specific setup
{ pkgs, lib, ... }:

{
  packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.colima  # Lightweight Docker alternative for macOS
    pkgs.docker-client
  ];
}
```

### Advantages

- Complete process and network isolation
- Familiar Docker Compose mental model
- Can mix Nix-built and Docker Hub images
- Built-in networking between containers

### Disadvantages

- Requires Docker runtime
- Higher resource overhead
- Slower startup compared to native solutions
- macOS requires Docker Desktop or colima

### References

- **Arion Documentation**: https://docs.hercules-ci.com/arion/
- **Arion GitHub**: https://github.com/hercules-ci/arion
- **Colima (macOS Docker)**: https://github.com/abiosoft/colima

---

## Alternative 3: NixOS Containers (Linux) + nix-darwin Services (macOS)

### Overview

This platform-specific approach uses native NixOS containers on Linux and nix-darwin launchd services on macOS, providing OS-level isolation.

### Why Choose This Alternative

- **Native OS Integration**: Uses OS-native isolation mechanisms
- **No Additional Runtime**: No Docker requirement
- **System-Level Isolation**: Stronger than process-level

### Implementation (NixOS)

```nix
# modules/sandbox/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.jvf.sandbox;
  
  mkSandboxContainer = name: projectConfig: {
    autoStart = false;  # Triggered on demand
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.${toString (projectConfig.id + 10)}";
    
    bindMounts = {
      # Project directory
      "/workspace" = {
        hostPath = projectConfig.path;
        isReadOnly = false;
      };
      # Host configs for code agents (read-only)
      "/host-config" = {
        hostPath = "/home/${config.jvf.users.defaultUser}/.config";
        isReadOnly = true;
      };
    };
    
    config = { config, pkgs, ... }: {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_16;
        # Port is irrelevant - container has own network
        settings.port = 5432;
        initialScript = pkgs.writeText "init.sql" ''
          CREATE USER dev WITH SUPERUSER PASSWORD 'dev';
          CREATE DATABASE development OWNER dev;
        '';
      };
      
      environment.systemPackages = with pkgs; [
        git
        # Add tools here
      ];
      
      # Symlink host configs for code agents
      environment.etc."code-agent-config".source = "/host-config";
    };
  };
  
in
{
  options.jvf.sandbox = {
    enable = lib.mkEnableOption "sandbox development environments";
    
    projects = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          id = lib.mkOption { type = lib.types.int; };
          path = lib.mkOption { type = lib.types.path; };
        };
      });
      default = {};
    };
  };
  
  config = lib.mkIf cfg.enable {
    containers = lib.mapAttrs mkSandboxContainer cfg.projects;
  };
}
```

### Implementation (Darwin via launchd)

```nix
# For Darwin, use launchd services with per-project configs
{ config, lib, pkgs, ... }:

let
  cfg = config.jvf.sandbox;
  
  mkPostgresService = name: projectConfig: {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.postgresql_16}/bin/postgres"
        "-D" "${projectConfig.path}/.sandbox-state/postgres"
        "-p" (toString (5432 + projectConfig.id))
      ];
      RunAtLoad = false;  # Triggered on demand
      KeepAlive = true;
      WorkingDirectory = projectConfig.path;
    };
  };
  
in
{
  launchd.user.agents = lib.mapAttrs' 
    (name: cfg: lib.nameValuePair "sandbox-postgres-${name}" (mkPostgresService name cfg))
    cfg.projects;
}
```

### Advantages

- Native OS isolation mechanisms
- No Docker overhead
- System-managed process lifecycle
- Strong security boundaries (NixOS containers)

### Disadvantages

- Platform-specific implementations
- More complex to maintain
- NixOS containers require root privileges
- Less portable between Linux distributions

### References

- **NixOS Containers**: https://nixos.org/manual/nixos/stable/index.html#ch-containers
- **nix-darwin Launchd**: https://daiderd.com/nix-darwin/manual/index.html

---

## Comparison Matrix

| Feature | devenv | Flakes + process-compose | arion | NixOS Containers |
|---------|--------|--------------------------|-------|------------------|
| **Cross-platform** | ✅ Full | ✅ Full | ⚠️ Needs Docker | ❌ Linux only |
| **Setup Complexity** | Low | Medium | Medium | High |
| **Isolation Level** | Process | Process | Container | Container/OS |
| **Port Handling** | Automatic | Manual | Automatic | N/A (Network) |
| **Startup Speed** | Fast | Fast | Medium | Medium |
| **Resource Overhead** | Low | Low | Medium | Medium |
| **direnv Integration** | ✅ Native | ⚠️ Manual | ❌ | ❌ |
| **Maintenance Burden** | Low | Medium | Low | High |
| **Code Agent Compat** | ✅ Easy | ✅ Easy | ⚠️ Volume mounts | ⚠️ Bind mounts |

---

## Recommended Implementation Strategy

### Phase 1: Core Infrastructure

1. **Create a reusable devenv module** in `modules/common/sandbox/`
2. **Define base configurations** for common services (PostgreSQL, Redis, etc.)
3. **Implement port allocation** strategy using project path hashing

### Phase 2: Project Templates

1. **Create template files** that can be copied to new projects
2. **Include `.envrc`** for automatic activation
3. **Document code agent configuration**

### Phase 3: Integration with Existing Modules

```nix
# modules/common/sandbox/default.nix
{ lib, config, pkgs, ... }:

let
  cfg = config.jvf.common.sandbox;
in
{
  options.jvf.common.sandbox = {
    enable = lib.mkEnableOption "sandbox development environments";
    
    defaultServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "postgres" ];
      description = "Default services to include in sandboxes";
    };
    
    # Template generation
    templates = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          services = lib.mkOption { type = lib.types.listOf lib.types.str; };
          packages = lib.mkOption { type = lib.types.listOf lib.types.package; };
        };
      });
      default = {};
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Generate template files that can be deployed to projects
    # This integrates with the jvf.* module namespace
  };
}
```

---

## Conclusion

**Primary Recommendation: devenv** is the most elegant solution for this use case. It provides:

1. ✅ Cross-platform support (NixOS + Darwin)
2. ✅ Automatic PostgreSQL isolation with zero configuration
3. ✅ direnv integration for automatic environment activation
4. ✅ Simple per-project configuration
5. ✅ Active maintenance and good documentation

For projects requiring stronger isolation or specific platform features, consider **arion** (container isolation) or the **manual Flakes + process-compose** approach (maximum control).

---

## Citations & References

1. **devenv**: Cachix Team (2023). "devenv - Fast, Declarative, Reproducible, and Composable Developer Environments using Nix." https://devenv.sh/
2. **Nix Flakes**: NixOS Foundation. "Nix Flakes." https://nixos.wiki/wiki/Flakes
3. **process-compose**: F1bonacc1 (2023). "Process Compose - A simple and flexible orchestrator for local development." https://github.com/F1bonacc1/process-compose
4. **arion**: Hercules CI (2023). "Arion - Run docker-compose with Nix." https://docs.hercules-ci.com/arion/
5. **NixOS Containers**: NixOS Manual. "Chapter 67. Container Management." https://nixos.org/manual/nixos/stable/index.html#ch-containers
6. **nix-direnv**: Nix Community (2023). "nix-direnv - A fast, persistent use_nix/use_flake implementation for direnv." https://github.com/nix-community/nix-direnv
7. **PostgreSQL Isolation Patterns**: PostgreSQL Documentation. "Managing Kernel Resources." https://www.postgresql.org/docs/current/kernel-resources.html

---

*Document generated: 2026-01-09*
*Feature: 001-nix-sandbox-dev-environments*
