{
  description = "Django with PostgreSQL sandbox template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        projectPath = toString ./.;
        appName = pkgs.lib.strings.sanitizeDerivationName (builtins.baseNameOf projectPath);
        dbNameBase = pkgs.lib.replaceStrings [ "-" ] [ "_" ] appName;

        # Base port derived from project path hash
        # Each instance adds PID-based offset at runtime
        projectHash = builtins.hashString "sha256" projectPath;
        hexChars = pkgs.lib.stringToCharacters (builtins.substring 0 8 projectHash);
        hexToInt = c:
          if c >= "0" && c <= "9" then pkgs.lib.toInt c
          else if c == "a" then 10
          else if c == "b" then 11
          else if c == "c" then 12
          else if c == "d" then 13
          else if c == "e" then 14
          else 15;
        basePortOffset = pkgs.lib.mod (pkgs.lib.foldl' (acc: c: acc * 16 + hexToInt c) 0 hexChars) 500;
        basePort = toString (5432 + basePortOffset);

        postgresVersion = pkgs.postgresql_18.withPackages (ps: [
          ps.postgis
          ps.timescaledb
        ]);

        # PostgreSQL initialization script - uses runtime PGPORT
        pgSetup = pkgs.writeShellScriptBin "sandbox-pg-setup" ''
          set -e
          if [ -z "$SANDBOX_STATE" ] || [ -z "$PGPORT" ]; then
            echo "Error: SANDBOX_STATE and PGPORT must be set."
            exit 1
          fi

          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"
          DB_DEV="''${DB_BASE}_development"
          DB_TEST="''${DB_BASE}_test"

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
          shared_preload_libraries = 'timescaledb'
          EOF

            ${postgresVersion}/bin/pg_ctl -D "$PG_DATA" -l "$SANDBOX_STATE/postgres.log" start -w
            ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres postgres || true
            ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres "$DB_DEV" || true
            ${postgresVersion}/bin/createdb -p "$PGPORT" -h "$PG_SOCKET" -U postgres "$DB_TEST" || true
            for db in "$DB_DEV" "$DB_TEST"; do
              ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PG_SOCKET" -U postgres -d "$db" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
              ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PG_SOCKET" -U postgres -d "$db" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;" || true
            done
            ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PG_SOCKET" -U postgres -d postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';" || true
            ${postgresVersion}/bin/pg_ctl -D "$PG_DATA" stop -m fast
            echo "PostgreSQL initialized on port $PGPORT"
          fi
        '';

        # Generate process-compose config at runtime
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
            echo "Error: SANDBOX_STATE not set."
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
            echo "Error: SANDBOX_STATE not set."
            exit 1
          fi
          PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
          if [ -S "$PC_SOCKET" ]; then
            ${pkgs.process-compose}/bin/process-compose down -U -u "$PC_SOCKET" || true
          fi
          if [ -f "$SANDBOX_STATE/postgres/postmaster.pid" ]; then
            ${postgresVersion}/bin/pg_ctl -D "$SANDBOX_STATE/postgres" stop -m fast 2>/dev/null || true
          fi
          echo "Services stopped."
        '';

        sandboxStatus = pkgs.writeShellScriptBin "sandbox-status" ''
          if [ -z "$SANDBOX_STATE" ]; then
            echo "Error: SANDBOX_STATE not set."
            exit 1
          fi
          PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
          echo "=== Sandbox Status ==="
          echo "Instance ID: $SANDBOX_ID"
          echo "App name: $APP_NAME"
          echo "PostgreSQL port: $PGPORT"
          echo "State directory: $SANDBOX_STATE"
          echo ""
          if [ -S "$PC_SOCKET" ]; then
            ${pkgs.process-compose}/bin/process-compose ps -U -u "$PC_SOCKET" 2>/dev/null || echo "Services not running (process-compose)"
          elif ${postgresVersion}/bin/pg_isready -h "$PGHOST" -p "$PGPORT" > /dev/null 2>&1; then
            echo "PostgreSQL: running (standalone mode)"
          else
            echo "Services not running"
          fi
        '';

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

            if [ -f "$dir/postgres/postmaster.pid" ]; then
              pid=$(head -1 "$dir/postgres/postmaster.pid" 2>/dev/null || echo "")
              if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                echo "Skipping $instance_id (postgres still running, PID $pid)"
                continue
              fi
            fi

            if [ -S "$dir/process-compose.sock" ]; then
              echo "Skipping $instance_id (process-compose socket exists)"
              continue
            fi

            echo "Removing stale instance: $instance_id"
            rm -rf "$dir"
          done
          echo "Cleanup complete"
        '';

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

            if [ -f "$dir/postgres/postgresql.conf" ]; then
              port=$(grep "^port" "$dir/postgres/postgresql.conf" 2>/dev/null | awk '{print $3}' || echo "?")
            fi

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

        db_start = pkgs.writeShellScriptBin "db_start" ''
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

        db_stop = pkgs.writeShellScriptBin "db_stop" ''
          ${postgresVersion}/bin/pg_ctl -D "$PGDATA" stop -m fast 2>/dev/null || echo "PostgreSQL not running"
        '';

        db_reset = pkgs.writeShellScriptBin "db_reset" ''
          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"
          DB_DEV="''${DB_BASE}_development"
          dropdb -h "$PGHOST" -p "$PGPORT" -U postgres "$DB_DEV" 2>/dev/null || true
          createdb -h "$PGHOST" -p "$PGPORT" -U postgres "$DB_DEV"
          ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PGHOST" -U postgres -d "$DB_DEV" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
          ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PGHOST" -U postgres -d "$DB_DEV" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;" || true
          if [ -f manage.py ]; then
            echo "Running Django migrations..."
            python manage.py migrate || true
          fi
        '';

        db_parallel_create = pkgs.writeShellScriptBin "db_parallel_create" ''
          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"
          echo "Creating parallel test databases on port $PGPORT..."
          for i in $(seq 2 $(($(nproc) + 1))); do
            DB_NAME="''${DB_BASE}_test$i"
            createdb -h "$PGHOST" -p "$PGPORT" -U postgres "$DB_NAME" 2>/dev/null || true
            ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PGHOST" -U postgres -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
            ${postgresVersion}/bin/psql -p "$PGPORT" -h "$PGHOST" -U postgres -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;" || true
          done
          echo "Parallel test databases ready"
        '';

        db_parallel_drop = pkgs.writeShellScriptBin "db_parallel_drop" ''
          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"
          echo "Dropping parallel test databases on port $PGPORT..."
          for i in $(seq 2 $(($(nproc) + 1))); do
            dropdb -h "$PGHOST" -p "$PGPORT" -U postgres "''${DB_BASE}_test$i" 2>/dev/null || true
          done
          echo "Parallel test databases dropped"
        '';

        db_use_remote = pkgs.writeShellScriptBin "db_use_remote" ''
          set -e
          DB_PASSWORD_FILE="''${DB_PASSWORD_FILE:-}"
          SECRET_KEY_FILE="''${SECRET_KEY_FILE:-}"
          DB_HOST="''${DB_HOST:-}"
          DB_PORT="''${DB_PORT:-5432}"
          DB_USERNAME="''${DB_USERNAME:-postgres}"
          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"

          if [ -z "$DB_HOST" ]; then
            echo "Error: DB_HOST must be set" >&2
            exit 1
          fi

          if [ -n "$DB_PASSWORD_FILE" ] && [ -f "$DB_PASSWORD_FILE" ]; then
            DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
          elif [ -n "$DB_PASSWORD" ]; then
            DB_PASSWORD="$DB_PASSWORD"
          else
            echo "Error: set DB_PASSWORD or DB_PASSWORD_FILE" >&2
            exit 1
          fi

          if [ -n "$SECRET_KEY_FILE" ] && [ -f "$SECRET_KEY_FILE" ]; then
            DJANGO_SECRET_KEY=$(cat "$SECRET_KEY_FILE")
          elif [ -n "$DJANGO_SECRET_KEY" ]; then
            DJANGO_SECRET_KEY="$DJANGO_SECRET_KEY"
          else
            echo "Warning: DJANGO_SECRET_KEY not provided" >&2
          fi

          echo "unset DATABASE_URL"
          echo "export DJANGO_ENV=production"
          echo "export REMOTE_DATABASE_HOST=\"$DB_HOST\""
          echo "export REMOTE_DATABASE_PORT=\"$DB_PORT\""
          echo "export REMOTE_DATABASE_USERNAME=\"$DB_USERNAME\""
          echo "export REMOTE_DATABASE_PASSWORD=\"$DB_PASSWORD\""
          echo "export REMOTE_DATABASE_NAME=\"''${DB_BASE}_production\""
          if [ -n "$DJANGO_SECRET_KEY" ]; then
            echo "export DJANGO_SECRET_KEY=\"$DJANGO_SECRET_KEY\""
          fi
        '';

        db_use_local = pkgs.writeShellScriptBin "db_use_local" ''
          DB_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"
          echo "export DATABASE_URL=\"postgresql://postgres:postgres@localhost:$PGPORT/''${DB_BASE}_development?host=$PGHOST\""
          echo "export APP_DATABASE_HOST=\"$PGHOST\""
          echo "export APP_DATABASE_PORT=\"$PGPORT\""
          echo "export APP_DATABASE_USERNAME=\"postgres\""
          echo "export APP_DATABASE_PASSWORD=\"postgres\""
          echo "export DJANGO_ENV=development"
        '';

        # Create a git worktree and start a fully initialized sandbox
        sandboxWorktree = pkgs.writeShellScriptBin "sandbox-worktree" ''
          set -e

          usage() {
            echo "Usage: sandbox-worktree <branch-name> [worktree-path] [subpath]"
            echo ""
            echo "Create a git worktree with a fully initialized sandbox."
            echo "This command creates the worktree, enters nix develop, and starts PostgreSQL."
            echo ""
            echo "Arguments:"
            echo "  branch-name    Branch to checkout (created if doesn't exist)"
            echo "  worktree-path  Optional path for worktree (default: ../<project>-<branch>)"
            echo "  subpath        Optional subdirectory to cd into after entering the worktree"
            echo ""
            echo "Examples:"
            echo "  sandbox-worktree feature-auth"
            echo "  sandbox-worktree bugfix-123 ~/projects/myapp-bugfix"
            echo "  sandbox-worktree feature-auth \"\" services/api"
            exit 1
          }

          if [ -z "$1" ]; then
            usage
          fi

          BRANCH="$1"
          PROJECT_NAME=$(basename "$PWD")
          WORKTREE_PATH="''${2:-$PWD/../$PROJECT_NAME-$BRANCH}"
          SUBPATH="$3"

          # Check if we're in a git repo
          if ! git rev-parse --git-dir > /dev/null 2>/dev/null; then
            echo "Error: Not in a git repository"
            exit 1
          fi

          # Prune stale worktree registrations (directories that were deleted)
          git worktree prune

          # Check if worktree path already exists
          if [ -d "$WORKTREE_PATH" ]; then
            WORKTREE_ABS=$(cd "$WORKTREE_PATH" && pwd)
            echo ""
            echo "=== Entering Existing Worktree ==="
            echo "Path: $WORKTREE_ABS"
            echo ""
            echo "Entering sandbox with PostgreSQL..."
            echo ""
            cd "$WORKTREE_ABS"
            if [ -n "$SUBPATH" ]; then
              exec nix develop --impure --command zsh -ic "db_start; cd \"$SUBPATH\" && exec zsh"
            else
              exec nix develop --impure --command zsh -ic "db_start; exec zsh"
            fi
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
          if [ -n "$SUBPATH" ]; then
            exec nix develop --impure --command zsh -ic "db_start; cd \"$SUBPATH\" && exec zsh"
          else
            exec nix develop --impure --command zsh -ic "db_start; exec zsh"
          fi
        '';

        # List all worktrees with their sandbox status
        sandboxWorktreeList = pkgs.writeShellScriptBin "sandbox-worktree-list" ''
          if ! git rev-parse --git-dir > /dev/null 2>/dev/null; then
            echo "Error: Not in a git repository"
            exit 1
          fi

          echo "=== Git Worktrees ==="
          git worktree list
        '';

        # Finish sandbox: exit worktree, return to main, and merge
        sandboxFinish = pkgs.writeShellScriptBin "sandbox-finish" ''
          set -e

          usage() {
            echo "Usage: sandbox-finish [options]"
            echo ""
            echo "Exit the current worktree sandbox, return to main, and merge changes."
            echo ""
            echo "Options:"
            echo "  --no-merge    Exit without merging"
            echo "  --keep        Keep the worktree after merge (default: delete)"
            echo "  --no-squash   Regular merge instead of squash (default: squash)"
            echo "  -h, --help    Show this help message"
            exit 0
          }

          NO_MERGE=false
          DELETE_WORKTREE=true
          SQUASH=true

          while [[ $# -gt 0 ]]; do
            case $1 in
              --no-merge)
                NO_MERGE=true
                shift
                ;;
              --keep)
                DELETE_WORKTREE=false
                shift
                ;;
              --no-squash)
                SQUASH=false
                shift
                ;;
              -h|--help)
                usage
                ;;
              *)
                echo "Unknown option: $1"
                usage
                ;;
            esac
          done

          # Check if we're in a git repo
          if ! git rev-parse --git-dir > /dev/null 2>/dev/null; then
            echo "Error: Not in a git repository"
            exit 1
          fi

          # Get current branch name
          CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

          # Find the main worktree path
          MAIN_WORKTREE=$(git worktree list --porcelain | grep -A2 "^worktree " | head -1 | sed 's/worktree //')

          # Get current worktree path
          CURRENT_WORKTREE=$(git rev-parse --show-toplevel)

          # Check if we're in the main worktree
          if [ "$CURRENT_WORKTREE" = "$MAIN_WORKTREE" ]; then
            echo "Error: Already in the main worktree. Nothing to finish."
            exit 1
          fi

          echo ""
          echo "=== Sandbox Finish ==="
          echo "Current branch: $CURRENT_BRANCH"
          echo "Current worktree: $CURRENT_WORKTREE"
          echo "Main worktree: $MAIN_WORKTREE"
          echo ""

          # Stop services before exiting
          echo "Stopping sandbox services..."
          sandbox-down 2>/dev/null || true

          # Change to main worktree
          cd "$MAIN_WORKTREE"
          echo "Changed to main worktree: $MAIN_WORKTREE"

          if [ "$NO_MERGE" = false ]; then
            DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
            
            echo "Checking out $DEFAULT_BRANCH..."
            git checkout "$DEFAULT_BRANCH"
            
            echo ""
            if [ "$SQUASH" = true ]; then
              echo "Squash merging $CURRENT_BRANCH into $DEFAULT_BRANCH..."
              git merge --squash "$CURRENT_BRANCH"
              echo ""
              echo "Changes staged. Please commit with: git commit"
            else
              echo "Merging $CURRENT_BRANCH into $DEFAULT_BRANCH..."
              git merge "$CURRENT_BRANCH" --no-edit
            fi
            
            echo ""
            echo "Merge completed!"
          else
            echo "Skipping merge (--no-merge specified)"
          fi

          if [ "$DELETE_WORKTREE" = true ]; then
            echo ""
            echo "Removing worktree: $CURRENT_WORKTREE"
            git worktree remove "$CURRENT_WORKTREE" --force
            
            read -p "Delete branch '$CURRENT_BRANCH'? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              git branch -d "$CURRENT_BRANCH" 2>/dev/null || git branch -D "$CURRENT_BRANCH"
              echo "Branch $CURRENT_BRANCH deleted"
            fi
          fi

          echo ""
          echo "=== Sandbox Finished ==="
          echo "You are now in: $MAIN_WORKTREE"
          echo ""

          exec zsh
        '';

        # Browser packages - only available on Linux (for Playwright-like needs)
        browserPackages =
          if pkgs.stdenv.isLinux then [
            pkgs.chromium
            pkgs.chromedriver
          ] else [ ];

        browserEnvVars =
          if pkgs.stdenv.isLinux then ''
            export CHROME_BIN=${pkgs.chromium}/bin/chromium
            export CHROMEDRIVER_BIN=${pkgs.chromedriver}/bin/chromedriver
          '' else ''
            export CHROME_BIN="''${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
            export CHROMEDRIVER_BIN="''${CHROMEDRIVER_BIN:-$(which chromedriver 2>/dev/null || echo chromedriver)}"
          '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python312
            uv
            postgresVersion
            gdal
            geos
            proj
            ruff
            gnumake
            gcc
            pkg-config
            openssl
            libffi
            process-compose
            # Sandbox commands
            pgSetup
            processComposeTemplate
            sandboxUp
            sandboxDown
            sandboxStatus
            sandboxCleanup
            sandboxList
            # Database helper scripts
            db_start
            db_stop
            db_reset
            db_parallel_create
            db_parallel_drop
            db_use_remote
            db_use_local
            # Worktree commands
            sandboxWorktree
            sandboxWorktreeList
            sandboxFinish
          ] ++ browserPackages;

          shell = pkgs.zsh;

          shellHook = ''
            export APP_NAME="${appName}"
            export APP_DB_NAME_BASE="''${APP_DB_NAME_BASE:-${dbNameBase}}"

            # Generate unique instance ID from shell PID
            export SANDBOX_ID="$$"

            # Calculate unique port: base_port + (PID % 500)
            export PGPORT=$((${basePort} + ($SANDBOX_ID % 500)))

            # Instance-specific state directory
            export SANDBOX_ROOT="$PWD"
            export SANDBOX_STATE="$PWD/.sandboxes/$SANDBOX_ID"
            export PGDATA="$SANDBOX_STATE/postgres"
            export PGHOST="$SANDBOX_STATE/postgres-socket"

            # XDG passthrough for code agents
            export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
            export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"

            # Python configuration
            export PATH=$PWD/.venv/bin:$PATH
            export UV_LINK_MODE=copy
            export PYTHONWARNINGS="ignore"
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [ gdal geos proj postgresVersion openssl ])}
            export GDAL_LIBRARY_PATH=${pkgs.gdal}/lib/libgdal.so
            export GEOS_LIBRARY_PATH=${pkgs.geos}/lib/libgeos_c.so
            export TMPDIR=/tmp

            # Default database configuration (only if not already set)
            export APP_DATABASE_HOST="''${APP_DATABASE_HOST:-$PGHOST}"
            export APP_DATABASE_PORT="''${APP_DATABASE_PORT:-$PGPORT}"
            export APP_DATABASE_USERNAME="''${APP_DATABASE_USERNAME:-postgres}"
            export APP_DATABASE_PASSWORD="''${APP_DATABASE_PASSWORD:-postgres}"

            # Browser automation (platform-specific)
            ${browserEnvVars}

            # Cleanup on shell exit (only if sandbox was initialized)
            trap 'sandbox-down 2>/dev/null' EXIT

            echo ""
            echo "=== Sandbox Shell Ready ==="
            echo "Project: ${appName}"
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
            echo "  sandbox-finish        Exit worktree, merge, and return to main"
            echo "  sandbox-list          List all sandbox instances"
            echo "  sandbox-cleanup       Remove stale instances"
            echo ""
            echo "Database Commands:"
            echo "  db_reset / db_parallel_create / db_parallel_drop"
            echo "  db_use_remote / db_use_local"
            echo ""
            echo "Python: $(python --version)"
            echo "PostgreSQL: $(psql --version | head -1)"
          '';
        };
      }
    );
}
