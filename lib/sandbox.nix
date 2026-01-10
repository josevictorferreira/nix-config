{ pkgs, system }:

{ projectRoot
, services ? { postgres = true; }
, packages ? [ ]
, env ? { }
, shellHook ? ""
, postgresVersion ? pkgs.postgresql_16
,
}:

let
  inherit (pkgs) lib;

  # Base port for this project (deterministic from path)
  # Each instance adds its own offset at runtime
  projectHash = builtins.hashString "sha256" (toString projectRoot);
  hexChars = lib.stringToCharacters (builtins.substring 0 8 projectHash);
  hexToInt = c:
    if c >= "0" && c <= "9" then lib.toInt c
    else if c == "a" then 10
    else if c == "b" then 11
    else if c == "c" then 12
    else if c == "d" then 13
    else if c == "e" then 14
    else 15;
  basePortOffset = lib.mod (lib.foldl' (acc: c: acc * 16 + hexToInt c) 0 hexChars) 500;
  basePort = 5432 + basePortOffset;

  # Environment variable exports
  envExports = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env);

  # PostgreSQL initialization script - uses runtime PGPORT
  pgSetup = pkgs.writeShellScriptBin "sandbox-pg-setup" ''
    set -e
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    if [ -z "$PGPORT" ]; then
      echo "Error: PGPORT not set. Run this inside nix develop shell."
      exit 1
    fi

    PG_DATA="$SANDBOX_STATE/postgres"
    PG_SOCKET="$SANDBOX_STATE/postgres-socket"
    mkdir -p "$PG_DATA" "$PG_SOCKET"

    if [ ! -f "$PG_DATA/PG_VERSION" ]; then
      echo "Initializing PostgreSQL on port $PGPORT..."
      ${postgresVersion}/bin/initdb -D "$PG_DATA" --no-locale --encoding=UTF8 --auth=trust --username=postgres

      cat >> "$PG_DATA/postgresql.conf" << EOF
    port = $PGPORT
    unix_socket_directories = '$PG_SOCKET'
    listen_addresses = '127.0.0.1'
    EOF

      ${postgresVersion}/bin/pg_ctl -D "$PG_DATA" -l "$SANDBOX_STATE/postgres.log" start -w
      ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres postgres || true
      ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres development || true
      ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres test || true
      ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PG_SOCKET" -U postgres -d postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';" || true
      ${postgresVersion}/bin/pg_ctl -D "$PG_DATA" stop -m fast
      echo "PostgreSQL initialized on port $PGPORT"
    fi
  '';

  # Generate process-compose config at runtime (needs PGPORT substitution)
  processComposeTemplate = pkgs.writeShellScriptBin "sandbox-gen-pc-config" ''
    if [ -z "$SANDBOX_STATE" ] || [ -z "$PGPORT" ]; then
      echo "Error: SANDBOX_STATE and PGPORT must be set"
      exit 1
    fi
    cat > "$SANDBOX_STATE/process-compose.yaml" << EOF
    version: "0.5"
    log_location: $SANDBOX_STATE/process-compose.log
    processes:
      postgres:
        command: ${postgresVersion}/bin/postgres -D $SANDBOX_STATE/postgres
        readiness_probe:
          exec:
            command: ${postgresVersion}/bin/pg_isready -p $PGPORT -h $SANDBOX_STATE/postgres-socket
          initial_delay_seconds: 1
          period_seconds: 2
        availability:
          restart: on_failure
    EOF
  '';

  sandboxUp = pkgs.writeShellScriptBin "sandbox-up" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    mkdir -p "$SANDBOX_STATE"
    ${pgSetup}/bin/sandbox-pg-setup
    ${processComposeTemplate}/bin/sandbox-gen-pc-config
    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    exec ${pkgs.process-compose}/bin/process-compose up -f "$SANDBOX_STATE/process-compose.yaml" -U -u "$PC_SOCKET" "$@"
  '';

  sandboxDown = pkgs.writeShellScriptBin "sandbox-down" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi

    # Exit silently if sandbox was never initialized
    if [ ! -d "$SANDBOX_STATE" ]; then
      exit 0
    fi

    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    if [ -S "$PC_SOCKET" ]; then
      ${pkgs.process-compose}/bin/process-compose down -U -u "$PC_SOCKET" || true
    fi
    # Also stop postgres if running directly
    if [ -f "$SANDBOX_STATE/postgres/postmaster.pid" ]; then
      ${postgresVersion}/bin/pg_ctl -D "$SANDBOX_STATE/postgres" stop -m fast 2>/dev/null || true
    fi
    echo "Services stopped."
  '';

  sandboxStatus = pkgs.writeShellScriptBin "sandbox-status" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi

    echo "=== Sandbox Status ==="
    echo "Instance ID: $SANDBOX_ID"
    echo "PostgreSQL port: $PGPORT"
    echo "State directory: $SANDBOX_STATE"
    echo ""

    if [ ! -d "$SANDBOX_STATE" ]; then
      echo "Status: not initialized (run db_start or sandbox-up)"
      exit 0
    fi

    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    if [ -S "$PC_SOCKET" ]; then
      ${pkgs.process-compose}/bin/process-compose ps -U -u "$PC_SOCKET" 2>/dev/null || echo "Services not running (process-compose)"
    elif ${postgresVersion}/bin/pg_isready -h "$PGHOST" -p "$PGPORT" > /dev/null 2>&1; then
      echo "PostgreSQL: running (standalone mode)"
    else
      echo "Services not running"
    fi
  '';

  # Cleanup stale sandbox instances
  sandboxCleanup = pkgs.writeShellScriptBin "sandbox-cleanup" ''
    SANDBOXES_DIR="$PWD/.sandboxes"
    if [ ! -d "$SANDBOXES_DIR" ]; then
      echo "No sandboxes directory found"
      exit 0
    fi

    echo "=== Cleaning up stale sandbox instances ==="
    for dir in "$SANDBOXES_DIR"/*; do
      [ -d "$dir" ] || continue
      instance_id=$(basename "$dir")

      # Check if postgres is still running for this instance
      if [ -f "$dir/postgres/postmaster.pid" ]; then
        pid=$(head -1 "$dir/postgres/postmaster.pid" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          echo "Skipping $instance_id (postgres still running, PID $pid)"
          continue
        fi
      fi

      # Check if process-compose socket is active
      if [ -S "$dir/process-compose.sock" ]; then
        echo "Skipping $instance_id (process-compose socket exists)"
        continue
      fi

      echo "Removing stale instance: $instance_id"
      rm -rf "$dir"
    done
    echo "Cleanup complete"
  '';

  # List all sandbox instances
  sandboxList = pkgs.writeShellScriptBin "sandbox-list" ''
    SANDBOXES_DIR="$PWD/.sandboxes"
    if [ ! -d "$SANDBOXES_DIR" ]; then
      echo "No sandboxes directory found"
      exit 0
    fi

    echo "=== Sandbox Instances ==="
    printf "%-12s %-8s %-10s %s\n" "INSTANCE" "PORT" "STATUS" "PID"
    echo "----------------------------------------"

    for dir in "$SANDBOXES_DIR"/*; do
      [ -d "$dir" ] || continue
      instance_id=$(basename "$dir")
      port=""
      status="stopped"
      pid="-"

      # Try to get port from postgresql.conf
      if [ -f "$dir/postgres/postgresql.conf" ]; then
        port=$(grep "^port" "$dir/postgres/postgresql.conf" 2>/dev/null | awk '{print $3}' || echo "?")
      fi

      # Check if running
      if [ -f "$dir/postgres/postmaster.pid" ]; then
        pid=$(head -1 "$dir/postgres/postmaster.pid" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          status="running"
        else
          pid="-"
        fi
      fi

      printf "%-12s %-8s %-10s %s\n" "$instance_id" "$port" "$status" "$pid"
    done
  '';

  # Simple db_start for standalone postgres (no process-compose)
  dbStart = pkgs.writeShellScriptBin "db_start" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set."
      exit 1
    fi

    if ${postgresVersion}/bin/pg_isready -h "$PGHOST" -p "$PGPORT" > /dev/null 2>&1; then
      echo "PostgreSQL is already running on port $PGPORT"
      exit 0
    fi

    ${pgSetup}/bin/sandbox-pg-setup

    if [ -f "$PGDATA/postmaster.pid" ]; then
      rm -f "$PGDATA/postmaster.pid"
    fi

    chmod 700 "$PGDATA"
    echo "Starting PostgreSQL on port $PGPORT..."
    ${postgresVersion}/bin/pg_ctl -D "$PGDATA" -l "$SANDBOX_STATE/postgres.log" start -w -t 60
    echo "PostgreSQL started successfully."
  '';

  dbStop = pkgs.writeShellScriptBin "db_stop" ''
    ${postgresVersion}/bin/pg_ctl -D "$PGDATA" stop -m fast 2>/dev/null || echo "PostgreSQL not running"
  '';

  # Create a git worktree and start a fully initialized sandbox
  sandboxWorktree = pkgs.writeShellScriptBin "sandbox-worktree" ''
    set -e

    usage() {
      echo "Usage: sandbox-worktree <branch-name> [worktree-path]"
      echo ""
      echo "Create a git worktree with a fully initialized sandbox."
      echo "This command creates the worktree, enters nix develop, and starts PostgreSQL."
      echo ""
      echo "Arguments:"
      echo "  branch-name    Branch to checkout (created if doesn't exist)"
      echo "  worktree-path  Optional path for worktree (default: ../<project>-<branch>)"
      echo ""
      echo "Examples:"
      echo "  sandbox-worktree feature-auth"
      echo "  sandbox-worktree bugfix-123 ~/projects/myapp-bugfix"
      exit 1
    }

    if [ -z "$1" ]; then
      usage
    fi

    BRANCH="$1"
    PROJECT_NAME=$(basename "$PWD")
    WORKTREE_PATH="''${2:-$PWD/../$PROJECT_NAME-$BRANCH}"

    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo "Error: Not in a git repository"
      exit 1
    fi

    # Check if worktree path already exists
    if [ -d "$WORKTREE_PATH" ]; then
      echo "Error: Path already exists: $WORKTREE_PATH"
      echo "Either remove it or specify a different path."
      exit 1
    fi

    # Check if branch exists locally or remotely
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
      echo "Using existing branch: $BRANCH"
      git worktree add "$WORKTREE_PATH" "$BRANCH"
    elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
      echo "Creating local branch from origin/$BRANCH"
      git worktree add "$WORKTREE_PATH" -b "$BRANCH" "origin/$BRANCH"
    else
      echo "Creating new branch: $BRANCH"
      git worktree add "$WORKTREE_PATH" -b "$BRANCH"
    fi

    # Resolve to absolute path
    WORKTREE_ABS=$(cd "$WORKTREE_PATH" && pwd)

    echo ""
    echo "=== Worktree Created ==="
    echo "Branch: $BRANCH"
    echo "Path: $WORKTREE_ABS"
    echo ""
    echo "Entering sandbox with PostgreSQL..."
    echo ""

    # Enter the worktree and start nix develop with db_start
    cd "$WORKTREE_ABS"
    exec nix develop --impure --command bash -c "db_start && exec $SHELL"
  '';

  # List all worktrees with their sandbox status
  sandboxWorktreeList = pkgs.writeShellScriptBin "sandbox-worktree-list" ''
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo "Error: Not in a git repository"
      exit 1
    fi

    echo "=== Git Worktrees ==="
    git worktree list
  '';

in
pkgs.mkShell {
  packages = [
    pkgs.process-compose
    postgresVersion
    pgSetup
    processComposeTemplate
    sandboxUp
    sandboxDown
    sandboxStatus
    sandboxCleanup
    sandboxList
    sandboxWorktree
    sandboxWorktreeList
    dbStart
    dbStop
  ] ++ packages;

  shellHook = ''
    # Generate unique instance ID from shell PID
    export SANDBOX_ID="$$"

    # Calculate unique port: base_port + (PID % 500)
    # This gives range of 500 ports per project, reducing collision chance
    export PGPORT=$((${toString basePort} + ($SANDBOX_ID % 500)))

    # Instance-specific state directory (lazy - created only when sandbox-up/db_start runs)
    export SANDBOX_ROOT="$PWD"
    export SANDBOX_STATE="$PWD/.sandboxes/$SANDBOX_ID"
    export PGDATA="$SANDBOX_STATE/postgres"
    export PGHOST="$SANDBOX_STATE/postgres-socket"
    export DATABASE_URL="postgresql://postgres:postgres@localhost:$PGPORT/development?host=$SANDBOX_STATE/postgres-socket"

    # Inherit host configs for code agents (XDG passthrough)
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"

    ${envExports}

    # Cleanup on shell exit (only if sandbox was initialized)
    trap 'sandbox-down 2>/dev/null' EXIT

    echo ""
    echo "=== Sandbox Shell Ready ==="
    echo "Instance ID: $SANDBOX_ID"
    echo "PostgreSQL port: $PGPORT (when started)"
    echo ""
    echo "Commands:"
    echo "  db_start              Start PostgreSQL and initialize sandbox"
    echo "  db_stop               Stop PostgreSQL"
    echo "  sandbox-up            Start services (process-compose TUI)"
    echo "  sandbox-down          Stop all services"
    echo "  sandbox-status        Show instance status"
    echo "  sandbox-worktree      Create worktree + start sandbox"
    echo "  sandbox-worktree-list List all worktrees"
    echo "  sandbox-list          List all sandbox instances"
    echo "  sandbox-cleanup       Remove stale instances"
    echo ""

    ${shellHook}
  '';
}
