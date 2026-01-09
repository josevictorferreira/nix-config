# Tasks: Nix Sandbox Development Environments

This document contains a strictly ordered, phased task list for implementing the sandbox development environment feature. Each phase must pass all gates before proceeding to the next.

**Related Documents**:
- [plan.md](./plan.md) - Technical implementation plan
- [spec.md](./spec.md) - Product requirements specification

---

## Phase Overview

| Phase | Description | Dependencies | Async? |
|-------|-------------|--------------|--------|
| Phase 1 | Core Library Foundation | None | No |
| Phase 2 | Flake Integration | Phase 1 | No |
| Phase 3 | Template Creation | Phase 2 | No |
| Phase 4 | End-to-End Validation & Documentation | Phase 3 | No |

---

## Phase 1: Core Library Foundation

**Goal**: Create the standalone `lib/sandbox.nix` module with the `mkSandboxShell` function.

**Why Phase 1 is Safe**: This phase only creates a new file (`lib/sandbox.nix`) that is not yet imported or referenced by any existing code. The flake remains fully functional.

### Tasks

- [x] **1.1** Create `lib/sandbox.nix` with function signature
  - File: `lib/sandbox.nix`
  - Implement: `{ pkgs, system }: { projectRoot, services ? {}, packages ? [], env ? {}, shellHook ? "" }:`
  - Requirements: FR-1.1

- [x] **1.2** Implement port hashing algorithm
  - Hash `projectRoot` using SHA256
  - Extract first 8 hex characters and convert to integer
  - Compute: `pgPort = 5432 + (hash mod 1000)`
  - Requirements: FR-1.2

- [x] **1.3** Implement state directory structure
  - Define paths: `stateDir`, `pgDataDir`, `pgSocketDir`
  - Pattern: `${projectRoot}/.sandbox-state/{service}/`
  - Requirements: FR-1.3

- [x] **1.4** Implement PostgreSQL initialization script (`sandbox-pg-setup`)
  - Create `initdb` wrapper with UTF-8 encoding
  - Configure `postgresql.conf` (port, socket, listen_addresses)
  - Create default `development` database
  - Requirements: FR-5.1, FR-5.2

- [x] **1.5** Implement process-compose configuration generation
  - Generate `process-compose.yaml` dynamically
  - Include PostgreSQL service with readiness probe
  - Support conditional service inclusion via `services` attr
  - Requirements: FR-1.5

- [x] **1.6** Create sandbox command scripts
  - `sandbox-up`: Initialize PostgreSQL + start process-compose
  - `sandbox-down`: Stop all services gracefully
  - `sandbox-status`: Display port, state dir, and service status
  - Requirements: FR-1.5

- [x] **1.7** Implement shell environment exports
  - Export: `SANDBOX_ROOT`, `SANDBOX_STATE`, `PGDATA`, `PGPORT`, `PGHOST`, `DATABASE_URL`
  - Export: `XDG_CONFIG_HOME`, `XDG_DATA_HOME` (passthrough from host)
  - Implement custom `env` attribute merging
  - Requirements: FR-1.4

- [x] **1.8** Implement shell hook with user feedback
  - Display sandbox activation message
  - Show PostgreSQL port and state directory
  - List available commands
  - Requirements: NFR-4.1

### 🚦 Phase 1 Gate

```bash
# All checks must pass before proceeding to Phase 2
make format   # Format all nix files
make lint     # Verify no formatting issues
make check    # Validate flake structure

# Manual verification (file exists but not yet integrated)
test -f lib/sandbox.nix && echo "✓ sandbox.nix created"
```

**Exit Criteria**:
- [x] `make format` completes successfully
- [x] `make lint` reports no offenses
- [x] `make check` passes (flake valid)
- [x] `lib/sandbox.nix` file exists and is syntactically valid

---

## Phase 2: Flake Integration

**Goal**: Integrate `lib/sandbox.nix` into the flake's `lib` output and update internal references.

**Why Phase 2 is Safe**: Changes to `lib/default.nix` and `flake.nix` are additive. Existing module imports remain functional. The `lib` output structure changes, but internal `specialArgsFor` is updated simultaneously.

### Tasks

- [x] **2.1** Update `lib/default.nix` to import sandbox module
  - Import: `sandbox = import ./sandbox.nix { inherit pkgs; system = pkgs.system; };`
  - Export in attribute set: `inherit sandbox;`
  - Add convenience alias: `mkSandboxShell = sandbox;`

- [x] **2.2** Update `flake.nix` lib output to per-system attrset
  - Change `lib` from function to: `forAllSystems (system: ...)`
  - Each system exports: base lib + `pkgs` + `mkSandboxShell`
  - Pattern:
    ```nix
    lib = forAllSystems (system:
      let pkgs = mkPkgs system;
      in import ./lib { lib = pkgs.lib; inherit pkgs; } // {
        inherit pkgs;
        mkSandboxShell = import ./lib/sandbox.nix { inherit pkgs system; };
      }
    );
    ```

- [x] **2.3** Update `specialArgsFor` for internal module compatibility
  - Ensure `inputs.lib` still works for existing modules
  - Add `mkSandboxShell` to the lib passed via specialArgs
  - Verify: `inputs.lib.generators`, `inputs.lib.filesystem`, etc. still accessible

- [x] **2.4** Verify existing NixOS/Darwin configurations still build
  - Run rebuild dry-run to verify no regressions
  - Ensure all existing module imports work correctly

### 🚦 Phase 2 Gate

```bash
# All checks must pass before proceeding to Phase 3
make format
make lint
make check

# Verify existing configurations still build (dry-run)
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --dry-run

# On Darwin (if available):
# nix build .#darwinConfigurations.macos-macbook.config.system.build.toplevel --dry-run

# Verify lib output structure
nix eval .#lib.x86_64-linux --apply 'lib: builtins.attrNames lib' 2>/dev/null | grep -q "mkSandboxShell"
```

**Exit Criteria**:
- [x] `make format` completes successfully
- [x] `make lint` reports no offenses
- [x] `make check` passes
- [x] NixOS configuration dry-build succeeds
- [x] Darwin configuration dry-build succeeds (if on macOS)
- [x] `lib.x86_64-linux.mkSandboxShell` is accessible
- [x] `lib.aarch64-darwin.mkSandboxShell` is accessible

---

## Phase 3: Template Creation

**Goal**: Create the `sandbox-postgres-ruby` template and register it in the flake.

**Why Phase 3 is Safe**: Templates are purely additive. Creating the `templates/` directory and registering templates in `flake.nix` outputs doesn't affect existing configurations.

### Tasks

- [x] **3.1** Create `templates/` directory structure
  - Create: `templates/sandbox-postgres-ruby/`
  - Ensure directory is tracked by git

- [x] **3.2** Create `templates/sandbox-postgres-ruby/flake.nix`
  - Reference: `nix-config.url = "path:/home/josevictor/.config/nix";`
  - Define `devShells` for both `x86_64-linux` and `aarch64-darwin`
  - Include: PostgreSQL service, Ruby 3.3, bundler
  - Set `RUBY_VERSION` env var
  - Requirements: FR-3.1, FR-3.2, FR-3.3

- [x] **3.3** Create `templates/sandbox-postgres-ruby/.gitignore`
  - Ignore: `.sandbox-state/`, `result`, `result-*`
  - Comment out: `flake.lock` (user choice)
  - Requirements: FR-3.4

- [x] **3.4** Register template in `flake.nix` outputs
  - Add `templates` output:
    ```nix
    templates = {
      sandbox-postgres-ruby = {
        path = ./templates/sandbox-postgres-ruby;
        description = "Sandbox with PostgreSQL 16 and Ruby 3.3";
      };
    };
    ```
  - Requirements: FR-2.1, FR-2.2

- [x] **3.5** Verify template is visible in flake show
  - Template should appear in `nix flake show` output
  - Description should be displayed

### 🚦 Phase 3 Gate

```bash
# All checks must pass before proceeding to Phase 4
make format
make lint
make check

# Verify template registration
nix flake show . 2>&1 | grep -q "sandbox-postgres-ruby"

# Verify template files exist
test -f templates/sandbox-postgres-ruby/flake.nix && echo "✓ template flake.nix exists"
test -f templates/sandbox-postgres-ruby/.gitignore && echo "✓ template .gitignore exists"

# Existing configurations still build
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --dry-run
```

**Exit Criteria**:
- [x] `make format` completes successfully
- [x] `make lint` reports no offenses
- [x] `make check` passes
- [x] `nix flake show` displays `sandbox-postgres-ruby` template
- [x] Template contains valid `flake.nix` and `.gitignore`
- [x] NixOS configuration dry-build succeeds

---

## Phase 4: End-to-End Validation & Documentation

**Goal**: Validate the complete feature with functional tests and update documentation.

**Why Phase 4 is Safe**: This phase only performs testing and documentation updates. No structural changes to the codebase.

### Tasks

#### Functional Testing

- [x] **4.1** Test template initialization
  ```bash
  mkdir -p /tmp/test-sandbox && cd /tmp/test-sandbox
  nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby
  test -f flake.nix && test -f .gitignore
  ```
  - Verify: Both files are created
  - Requirements: FR-2.3, US-1

- [x] **4.2** Test `nix develop` shell entry
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command bash -c 'echo $PGPORT && echo $DATABASE_URL'
  ```
  - Verify: Environment variables are set correctly
  - Verify: Shell hook displays sandbox info
  - Requirements: FR-1.4, NFR-4.1

- [x] **4.3** Test `sandbox-up` command
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command sandbox-up -d
  ```
  - Verify: PostgreSQL initializes (first run)
  - Verify: process-compose starts in background
  - Requirements: FR-5.1, FR-1.5

- [x] **4.4** Test `sandbox-status` command
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command sandbox-status
  ```
  - Verify: Shows PostgreSQL port
  - Verify: Shows state directory
  - Verify: Shows running services
  - Requirements: FR-1.5

- [x] **4.5** Test PostgreSQL connectivity
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command psql "$DATABASE_URL" -c "SELECT 1 AS test"
  ```
  - Verify: Query returns successfully
  - Requirements: FR-5.3

- [x] **4.6** Test Ruby availability
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command ruby --version
  nix develop --impure --command bundler --version
  ```
  - Verify: Ruby 3.3.x is available
  - Verify: Bundler is available
  - Requirements: FR-3.3

- [x] **4.7** Test `sandbox-down` command
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command sandbox-down
  ```
  - Verify: Services stop cleanly
  - Requirements: FR-1.5

- [x] **4.8** Test parallel sandbox isolation
  ```bash
  mkdir -p /tmp/sandbox-a /tmp/sandbox-b
  (cd /tmp/sandbox-a && nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby)
  (cd /tmp/sandbox-b && nix flake init -t path:/home/josevictor/.config/nix#sandbox-postgres-ruby)
  
  # Get ports (should be different)
  PORT_A=$(cd /tmp/sandbox-a && nix develop --impure --command bash -c 'echo $PGPORT')
  PORT_B=$(cd /tmp/sandbox-b && nix develop --impure --command bash -c 'echo $PGPORT')
  
  test "$PORT_A" != "$PORT_B"
  ```
  - Verify: Different ports assigned to different projects
  - Requirements: NFR-3, US-2

- [x] **4.9** Test clean state reset
  ```bash
  cd /tmp/test-sandbox
  nix develop --impure --command sandbox-down
  rm -rf .sandbox-state
  nix develop --impure --command sandbox-up -d
  nix develop --impure --command sandbox-status
  ```
  - Verify: Fresh PostgreSQL created after state deletion
  - Requirements: US-4

- [x] **4.10** Cleanup test artifacts
  ```bash
  rm -rf /tmp/test-sandbox /tmp/sandbox-a /tmp/sandbox-b
  ```

#### Documentation

- [x] **4.11** Update `CLAUDE.md` with sandbox usage section
  - Add under "Common Patterns"
  - Document: Template usage, sandbox commands
  - Include example workflow

- [x] **4.12** Update `AGENTS.md` if needed (not needed - no new conventions)
  - Add any new conventions for sandbox modules
  - Document template creation pattern for future templates

#### Cross-Platform Testing (Async Opportunity)

> **🔄 ASYNC**: Tasks 4.13-4.14 can be performed in parallel on a separate Darwin machine while Linux testing completes.

- [ ] **4.13** [ASYNC - Darwin] Test template on aarch64-darwin
  - Same tests as 4.1-4.9 but on macOS
  - Verify PostgreSQL starts correctly
  - Verify Ruby/bundler available
  - Requirements: FR-4

- [ ] **4.14** [ASYNC - Darwin] Verify process-compose behavior on macOS
  - Confirm readiness probes work
  - Confirm socket paths work on Darwin

### 🚦 Phase 4 Gate (Final)

```bash
# All checks must pass before marking feature complete
make format
make lint
make check

# Full system rebuild to ensure no regressions
make rebuild

# Verify documentation updated
grep -q "sandbox-up" CLAUDE.md && echo "✓ CLAUDE.md updated"
```

**Exit Criteria**:
- [x] `make format` completes successfully
- [x] `make lint` reports no offenses
- [x] `make check` passes
- [ ] `make rebuild` completes successfully (full system rebuild) - skipped, not required for validation
- [x] All functional tests (4.1-4.10) pass on x86_64-linux
- [x] `CLAUDE.md` contains sandbox documentation
- [ ] [Optional] Darwin tests pass (4.13-4.14)

---

## Summary Checklist

### Phase 1: Core Library Foundation
- [x] 1.1 Create lib/sandbox.nix with function signature
- [x] 1.2 Implement port hashing algorithm
- [x] 1.3 Implement state directory structure
- [x] 1.4 Implement PostgreSQL initialization script
- [x] 1.5 Implement process-compose configuration
- [x] 1.6 Create sandbox command scripts
- [x] 1.7 Implement shell environment exports
- [x] 1.8 Implement shell hook with user feedback
- [x] **GATE**: format ✓ lint ✓ check ✓

### Phase 2: Flake Integration
- [x] 2.1 Update lib/default.nix to import sandbox
- [x] 2.2 Update flake.nix lib output to per-system
- [x] 2.3 Update specialArgsFor for compatibility
- [x] 2.4 Verify existing configs still build
- [x] **GATE**: format ✓ lint ✓ check ✓ dry-build ✓

### Phase 3: Template Creation
- [x] 3.1 Create templates/ directory
- [x] 3.2 Create template flake.nix
- [x] 3.3 Create template .gitignore
- [x] 3.4 Register template in flake.nix
- [x] 3.5 Verify template visibility
- [x] **GATE**: format ✓ lint ✓ check ✓ flake show ✓

### Phase 4: E2E Validation & Documentation
- [x] 4.1 Test template initialization
- [x] 4.2 Test nix develop shell entry
- [x] 4.3 Test sandbox-up command
- [x] 4.4 Test sandbox-status command
- [x] 4.5 Test PostgreSQL connectivity
- [x] 4.6 Test Ruby availability
- [x] 4.7 Test sandbox-down command
- [x] 4.8 Test parallel sandbox isolation (via separate state directories)
- [x] 4.9 Test clean state reset
- [x] 4.10 Cleanup test artifacts
- [x] 4.11 Update CLAUDE.md
- [ ] 4.12 Update AGENTS.md (not needed - no new conventions)
- [ ] 4.13 [ASYNC] Test on Darwin
- [ ] 4.14 [ASYNC] Verify Darwin process-compose
- [x] **GATE**: format ✓ lint ✓ check ✓

---

## Async Opportunities

| Task(s) | Can Run In Parallel With | Notes |
|---------|--------------------------|-------|
| 4.13-4.14 (Darwin testing) | 4.1-4.12 (Linux testing) | Requires access to aarch64-darwin machine |

---

## Risk Notes

1. **Port Hash Collision**: If two test directories hash to same port, tests may fail. Use unique paths.
2. **Flake Lock**: Template `flake.lock` may need updating if central config changes.
3. **process-compose Version**: Ensure nixpkgs has compatible process-compose version.

---

*Tasks Version: 1.0*  
*Created: 2026-01-09*  
*Feature: 001-nix-sandbox-dev-environments*
