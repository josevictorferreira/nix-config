# Nix Sandbox Development Rules

## Nix String Indentation

- **Rule:** When generating config files (YAML, JSON) in Nix, use `pkgs.formats.*` instead of multi-line strings with `''`. Nix's `''` strings strip minimum indentation, breaking YAML structure.
- **Why:** Wasted 30+ minutes debugging YAML parsing errors caused by Nix string indentation stripping.
- **Check:** If generating structured config, verify output with `cat` after first test run.

## Runtime Path Resolution

- **Rule:** For flake templates needing runtime paths (like `$PWD`), use placeholder substitution (`@@PLACEHOLDER@@` + `sed`) at runtime rather than relying on `projectRoot` which resolves to Nix store paths.
- **Why:** `projectRoot = ./.` in flakes resolves to store path at eval time, not the actual working directory.
- **Check:** Test with `nix develop --impure --command bash -c 'echo $SANDBOX_STATE'` and verify paths point to working directory.

## Process-Compose Commands

- **Rule:** `process-compose up` uses `-f` for config file; `process-compose down/ps` use `-U -u <socket>` for Unix socket connection. Use `-D` (not `-d`) for detached mode.
- **Why:** Wrong flags cause "unknown shorthand flag" errors or connection failures.
- **Check:** Run `process-compose <cmd> --help` to verify correct flags before implementing.

## Nix Flake with Sockets

- **Rule:** When running `nix develop` multiple times in a directory with Unix sockets (`.sock` files) or special files, Nix will fail with "unsupported type". Clean state directory before re-evaluating flake.
- **Why:** Nix cannot handle socket files in flake source tree during evaluation.
- **Check:** If seeing "unsupported type" errors, run `rm -rf .sandbox-state` before `nix develop`.
