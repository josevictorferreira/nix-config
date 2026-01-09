# Product Specification: Nix Sandbox Development Environments

## Overview

This specification defines the implementation of **Flake Templates** for creating isolated, reproducible sandbox development environments. The chosen approach (Strategy 2 from research) enables users to scaffold new projects with a single command while keeping all logic centralized in the nix-config repository.

**Related Document**: [research.md](./research.md)

---

## Scope

### In Scope
- Central library function (`lib.mkSandboxShell`) for sandbox creation
- Flake template system with multiple template support
- First template: `sandbox-postgres-ruby` (PostgreSQL + Ruby 3)
- Cross-platform support (x86_64-linux + aarch64-darwin)
- Isolated PostgreSQL instances (unique ports per project)
- Code agent compatibility via XDG environment passthrough
- Process management via process-compose

### Out of Scope (Future)
- direnv/`.envrc` integration
- Additional templates (Redis, Node.js, Python, etc.)
- Agent-specific configuration paths
- GUI/TUI for template selection

---

## Functional Requirements

### FR-1: Central Library Function

**ID**: FR-1  
**Priority**: Critical  
**Description**: The nix-config flake must export a `mkSandboxShell` function that creates isolated development shells.

#### FR-1.1: Function Signature
```nix
mkSandboxShell {
  projectRoot,           # Required: Path - project directory for port hashing
  services ? {},         # Optional: Attrset - services to enable
  packages ? [],         # Optional: List - additional packages
  env ? {},              # Optional: Attrset - environment variables
  shellHook ? "",        # Optional: String - additional shell hook commands
}
```

#### FR-1.2: Port Isolation
- PostgreSQL port MUST be derived from hash of `projectRoot`
- Port range: 5432-6431 (base 5432 + hash mod 1000)
- Same project path MUST always produce same port (deterministic)

#### FR-1.3: State Directory
- All service data MUST be stored in `${projectRoot}/.sandbox-state/`
- PostgreSQL data: `.sandbox-state/postgres/`
- PostgreSQL socket: `.sandbox-state/postgres-socket/`
- Logs: `.sandbox-state/*.log`

#### FR-1.4: Environment Variables
The shell MUST export:
| Variable | Value | Purpose |
|----------|-------|---------|
| `SANDBOX_ROOT` | Project path | Reference to project root |
| `SANDBOX_STATE` | State directory path | Service data location |
| `PGDATA` | PostgreSQL data dir | PostgreSQL requirement |
| `PGPORT` | Computed port | PostgreSQL port |
| `PGHOST` | Socket directory | PostgreSQL connection |
| `DATABASE_URL` | Full connection string | Application config |
| `XDG_CONFIG_HOME` | Host's XDG config | Code agent configs |
| `XDG_DATA_HOME` | Host's XDG data | Code agent data |

#### FR-1.5: Commands
The shell MUST provide these commands:
| Command | Description |
|---------|-------------|
| `sandbox-up` | Initialize and start all services |
| `sandbox-down` | Stop all services |
| `sandbox-status` | Show service status and ports |

---

### FR-2: Flake Template System

**ID**: FR-2  
**Priority**: Critical  
**Description**: The nix-config flake must export templates that can be used with `nix flake init -t`.

#### FR-2.1: Template Location
- Templates MUST be located at `templates/` in flake root
- Each template MUST be a directory containing at minimum a `flake.nix`

#### FR-2.2: Template Registration
Templates MUST be registered in `flake.nix` outputs:
```nix
templates = {
  sandbox-postgres-ruby = {
    path = ./templates/sandbox-postgres-ruby;
    description = "Sandbox with PostgreSQL and Ruby 3";
  };
  # Future templates follow same pattern
};
```

#### FR-2.3: Template Invocation
Users MUST be able to scaffold projects via:
```bash
# Using path reference
nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby

# Using registry (after registration)
nix flake init -t nix-config#sandbox-postgres-ruby
```

---

### FR-3: First Template - `sandbox-postgres-ruby`

**ID**: FR-3  
**Priority**: High  
**Description**: Implementation of the first concrete template with PostgreSQL and Ruby 3.

#### FR-3.1: Template Contents
The template directory MUST contain:
```
templates/sandbox-postgres-ruby/
├── flake.nix          # Minimal flake referencing central library
└── .gitignore         # Ignore .sandbox-state/
```

#### FR-3.2: Generated `flake.nix` Structure
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

#### FR-3.3: Included Packages
| Package | Version | Purpose |
|---------|---------|---------|
| `postgresql_16` | 16.x | Database server |
| `ruby_3_3` | 3.3.x | Ruby runtime |
| `bundler` | Latest | Ruby dependency management |
| `process-compose` | Latest | Service orchestration |

#### FR-3.4: `.gitignore` Contents
```gitignore
# Sandbox state (generated, contains data)
.sandbox-state/

# Nix build artifacts
result
result-*

# Flake lock (optional - remove if you want to lock)
# flake.lock
```

---

### FR-4: Cross-Platform Support

**ID**: FR-4  
**Priority**: High  
**Description**: All components must work on both NixOS (Linux) and Darwin (macOS).

#### FR-4.1: Platform Detection
The library MUST use platform-agnostic code or detect platform:
```nix
let
  isDarwin = builtins.match ".*-darwin" system != null;
in
# Use platform-specific logic only when necessary
```

#### FR-4.2: Package Compatibility
All packages included in templates MUST be available on both platforms:
- `postgresql_16` ✓
- `ruby_3_3` ✓
- `bundler` ✓
- `process-compose` ✓

#### FR-4.3: Shell Compatibility
Shell scripts MUST use POSIX-compatible syntax or explicitly use bash.

---

### FR-5: PostgreSQL Service

**ID**: FR-5  
**Priority**: Critical  
**Description**: PostgreSQL must be fully isolated per sandbox.

#### FR-5.1: Initialization
On first `sandbox-up`:
1. Create data directory if not exists
2. Run `initdb` with UTF-8 encoding
3. Configure `postgresql.conf` with unique port and socket path
4. Start server, create default database, stop server

#### FR-5.2: Default Database
- Database name: `development`
- No password required for local socket connections
- Trust authentication for simplicity in development

#### FR-5.3: Connection Methods
| Method | Connection String |
|--------|-------------------|
| Socket | `postgresql:///development?host=${PGHOST}` |
| TCP | `postgresql://localhost:${PGPORT}/development` |

---

## Non-Functional Requirements

### NFR-1: Performance

**ID**: NFR-1  
**Priority**: Medium

| Metric | Target |
|--------|--------|
| `nix flake init` time | < 2 seconds |
| First `nix develop` (cold) | < 60 seconds |
| Subsequent `nix develop` (cached) | < 5 seconds |
| `sandbox-up` (initialized) | < 3 seconds |

---

### NFR-2: Maintainability

**ID**: NFR-2  
**Priority**: High

#### NFR-2.1: Single Source of Truth
- All sandbox logic MUST reside in `lib/sandbox.nix`
- Templates MUST NOT duplicate logic, only reference library

#### NFR-2.2: Template Updates
- Updating central library MUST benefit all projects after `nix flake update`
- Templates SHOULD be minimal (< 50 lines of Nix code)

---

### NFR-3: Isolation

**ID**: NFR-3  
**Priority**: Critical

| Aspect | Requirement |
|--------|-------------|
| Port conflicts | Zero conflicts when running multiple sandboxes |
| Data isolation | Each sandbox has independent PostgreSQL data |
| Environment | Sandbox env vars don't leak to host |

---

### NFR-4: User Experience

**ID**: NFR-4  
**Priority**: High

#### NFR-4.1: Clear Feedback
Shell entry MUST display:
- Active sandbox indicator
- PostgreSQL port number
- State directory location
- Available commands

#### NFR-4.2: Error Messages
All errors MUST be actionable with clear remediation steps.

---

## User Stories

### US-1: New Project Setup

**As a** developer  
**I want to** scaffold a new Ruby project with PostgreSQL  
**So that** I can start coding immediately without manual database setup

**Acceptance Criteria**:
1. Run `nix flake init -t nix-config#sandbox-postgres-ruby`
2. Run `nix develop`
3. Run `sandbox-up`
4. PostgreSQL is running and accessible
5. Ruby 3.3 and bundler are available

---

### US-2: Parallel Projects

**As a** developer  
**I want to** work on multiple projects simultaneously  
**So that** I can switch contexts without stopping services

**Acceptance Criteria**:
1. Project A running with `sandbox-up` (port 5532)
2. Project B running with `sandbox-up` (port 5678)
3. Both PostgreSQL instances are accessible
4. No port conflicts or data mixing

---

### US-3: Code Agent Usage

**As a** developer  
**I want to** run Cursor/opencode/Claude in my sandbox  
**So that** the AI can help me code with full database access

**Acceptance Criteria**:
1. Enter sandbox with `nix develop`
2. Start services with `sandbox-up`
3. Launch code agent (e.g., `cursor .`)
4. Agent can access `DATABASE_URL`
5. Agent uses host's configuration files

---

### US-4: Clean Environment

**As a** developer  
**I want to** completely reset my sandbox state  
**So that** I can start fresh when needed

**Acceptance Criteria**:
1. Run `sandbox-down`
2. Delete `.sandbox-state/` directory
3. Run `sandbox-up`
4. Fresh PostgreSQL database is created

---

## File Structure

### Central Config Additions

```
~/.config/nix/
├── flake.nix                    # Add templates output
├── lib/
│   ├── default.nix              # Export sandbox.nix
│   └── sandbox.nix              # NEW: mkSandboxShell implementation
└── templates/
    └── sandbox-postgres-ruby/
        ├── flake.nix            # Template flake
        └── .gitignore           # Ignore state directory
```

### Project Structure (After Scaffold)

```
my-project/
├── flake.nix                    # Generated from template
├── flake.lock                   # Generated on first use
├── .gitignore                   # From template
└── .sandbox-state/              # Generated on sandbox-up
    ├── postgres/                # PostgreSQL data
    ├── postgres-socket/         # Unix socket
    ├── postgres.log             # PostgreSQL logs
    └── process-compose.log      # Process logs
```

---

## Implementation Checklist

- [ ] Create `lib/sandbox.nix` with `mkSandboxShell` function
- [ ] Update `lib/default.nix` to export sandbox functions
- [ ] Update `flake.nix` to:
  - [ ] Export `lib.${system}.mkSandboxShell`
  - [ ] Export `lib.${system}.pkgs` for template access
  - [ ] Register templates in `outputs.templates`
- [ ] Create `templates/` directory
- [ ] Create `templates/sandbox-postgres-ruby/flake.nix`
- [ ] Create `templates/sandbox-postgres-ruby/.gitignore`
- [ ] Test on x86_64-linux
- [ ] Test on aarch64-darwin
- [ ] Document usage in README or CLAUDE.md

---

## Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Multiple templates vs single? | Multiple templates ✓ |
| First template services? | PostgreSQL + Ruby 3 ✓ |
| Include direnv? | No, future scope ✓ |
| Code agent config approach? | Generic XDG passthrough ✓ |
| Template location? | `templates/` at flake root ✓ |
| Cross-platform? | Both platforms supported ✓ |

---

*Specification Version: 1.0*  
*Created: 2026-01-09*  
*Feature: 001-nix-sandbox-dev-environments*
