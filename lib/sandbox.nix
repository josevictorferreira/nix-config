{ pkgs, system }:

{ projectRoot
, services ? { postgres = true; }
, packages ? [ ]
, env ? { }
, shellHook ? ""
,
}:

let
  inherit (pkgs) lib;

  # Port isolation via path hashing (FR-1.2)
  # Hash the projectRoot path, extract first 8 hex chars, convert to integer mod 1000
  # Note: projectRoot is the flake source path, providing deterministic port assignment
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
  portOffset = lib.mod (lib.foldl' (acc: c: acc * 16 + hexToInt c) 0 hexChars) 1000;
  pgPort = 5432 + portOffset;

  # State directories are resolved at runtime using PWD (FR-1.3)
  # This allows the sandbox state to be created in the actual project directory
  # rather than the nix store
  stateDirVar = "$SANDBOX_STATE";
  pgDataDirVar = "${stateDirVar}/postgres";
  pgSocketDirVar = "${stateDirVar}/postgres-socket";

  # PostgreSQL initialization script (FR-5.1, FR-5.2)
  # Uses runtime-resolved paths from environment variables
  pgSetup = pkgs.writeShellScriptBin "sandbox-pg-setup" ''
    set -e
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    PG_DATA="${pgDataDirVar}"
    PG_SOCKET="${pgSocketDirVar}"
    mkdir -p "$PG_DATA" "$PG_SOCKET"
    if [ ! -f "$PG_DATA/PG_VERSION" ]; then
      echo "Initializing PostgreSQL..."
      ${pkgs.postgresql_16}/bin/initdb -D "$PG_DATA" --no-locale --encoding=UTF8

      cat >> "$PG_DATA/postgresql.conf" << EOF
    port = ${toString pgPort}
    unix_socket_directories = '$PG_SOCKET'
    listen_addresses = '127.0.0.1'
    EOF

      ${pkgs.postgresql_16}/bin/pg_ctl -D "$PG_DATA" -l "${stateDirVar}/postgres.log" start -w
      ${pkgs.postgresql_16}/bin/createdb -p ${toString pgPort} -h "$PG_SOCKET" development || true
      ${pkgs.postgresql_16}/bin/pg_ctl -D "$PG_DATA" stop -m fast
      echo "PostgreSQL initialized on port ${toString pgPort}"
    fi
  '';

  # process-compose configuration (FR-1.5)
  # Build YAML config at build time using pkgs.formats.yaml, then substitute paths at runtime
  processComposeYamlTemplate = (pkgs.formats.yaml { }).generate "process-compose.yaml" {
    version = "0.5";
    log_location = "@@SANDBOX_STATE@@/process-compose.log";
    processes = lib.optionalAttrs (services.postgres or false) {
      postgres = {
        command = "${pkgs.postgresql_16}/bin/postgres -D @@SANDBOX_STATE@@/postgres";
        readiness_probe = {
          exec.command = "${pkgs.postgresql_16}/bin/pg_isready -p ${toString pgPort} -h @@SANDBOX_STATE@@/postgres-socket";
          initial_delay_seconds = 1;
          period_seconds = 2;
        };
        availability.restart = "on_failure";
      };
    };
  };

  # Command scripts (FR-1.5)
  # Use Unix domain sockets for process-compose to avoid port conflicts
  # Socket path is unique per sandbox based on SANDBOX_STATE
  sandboxUp = pkgs.writeShellScriptBin "sandbox-up" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    mkdir -p "$SANDBOX_STATE"
    PC_CONFIG="$SANDBOX_STATE/process-compose.yaml"
    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    sed "s|@@SANDBOX_STATE@@|$SANDBOX_STATE|g" ${processComposeYamlTemplate} > "$PC_CONFIG"
    ${pgSetup}/bin/sandbox-pg-setup
    exec ${pkgs.process-compose}/bin/process-compose up -f "$PC_CONFIG" -U -u "$PC_SOCKET" "$@"
  '';

  sandboxDown = pkgs.writeShellScriptBin "sandbox-down" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    if [ -S "$PC_SOCKET" ]; then
      ${pkgs.process-compose}/bin/process-compose down -U -u "$PC_SOCKET" || true
    fi
    echo "Services stopped."
  '';

  sandboxStatus = pkgs.writeShellScriptBin "sandbox-status" ''
    if [ -z "$SANDBOX_STATE" ]; then
      echo "Error: SANDBOX_STATE not set. Run this inside nix develop shell."
      exit 1
    fi
    PC_SOCKET="$SANDBOX_STATE/process-compose.sock"
    echo "=== Sandbox Status ==="
    echo "PostgreSQL port: ${toString pgPort}"
    echo "State directory: $SANDBOX_STATE"
    echo ""
    if [ -S "$PC_SOCKET" ]; then
      ${pkgs.process-compose}/bin/process-compose ps -U -u "$PC_SOCKET" 2>/dev/null || echo "Services not running"
    else
      echo "Services not running (no socket found)"
    fi
  '';

  # Environment variable exports (FR-1.4)
  envExports = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env);

in
pkgs.mkShell {
  packages = [
    pkgs.process-compose
    pkgs.postgresql_16
    sandboxUp
    sandboxDown
    sandboxStatus
    pgSetup
  ] ++ packages;

  # Shell hook with environment setup and user feedback (FR-1.7, FR-1.8, NFR-4.1)
  # Uses PWD at runtime for state directory paths
  shellHook = ''
    export SANDBOX_ROOT="$PWD"
    export SANDBOX_STATE="$PWD/.sandbox-state"
    export PGDATA="$SANDBOX_STATE/postgres"
    export PGPORT="${toString pgPort}"
    export PGHOST="$SANDBOX_STATE/postgres-socket"
    export DATABASE_URL="postgresql://localhost:${toString pgPort}/development?host=$SANDBOX_STATE/postgres-socket"

    # Inherit host configs for code agents (XDG passthrough)
    export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"

    ${envExports}

    echo ""
    echo "Sandbox environment ready"
    echo "----------------------------"
    echo "PostgreSQL port: ${toString pgPort}"
    echo "State: $SANDBOX_STATE"
    echo ""
    echo "Commands:"
    echo "  sandbox-up      Start all services"
    echo "  sandbox-down    Stop all services"
    echo "  sandbox-status  Show service status"
    echo ""

    ${shellHook}
  '';
}
