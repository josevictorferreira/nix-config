# Aspect: apps
# perSystem apps — every former Makefile recipe as `nix run .#<name>`, keeping
# the same target names (lint, format, up_keys, secrets, check, update, boot,
# rebuild, rollback, rebuildd, clean, help). Scripts run in the caller's cwd,
# exactly like `make` did.
{ ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;

      isDarwin = builtins.match ".*-darwin" system != null;

      # Ambient host tools (sudo, hyprctl, notify-send, darwin-rebuild,
      # nixos-rebuild) live outside the Nix store and may not be in the
      # restricted PATH of writeShellApplication — keep them reachable.
      hostPath = "/run/current-system/sw/bin:/run/wrappers/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

      lintScript = ''
        echo "Running nix formatter check..."
        nix fmt -- --check . || { echo "❌ Some files need formatting. Run 'nix run .#format' to fix."; exit 1; }
        echo "✅ All files are properly formatted."
      '';

      # List order defines the `nix run .#help` output.
      commands = [
        {
          name = "lint";
          description = "Lint the nix files.";
          runtimeInputs = [ pkgs.nix pkgs.git ];
          text = lintScript;
        }
        {
          name = "format";
          description = "Format the nix files.";
          runtimeInputs = [ pkgs.nix pkgs.git ];
          text = ''
            echo "Formatting nix files..."
            nix fmt .
            echo "✅ Formatting complete."
          '';
        }
        {
          name = "up_keys";
          description = "Update keys for secrets files";
          runtimeInputs = [ pkgs.sops ];
          text = ''
            sops updatekeys secrets/secrets.enc.yaml
          '';
        }
        {
          name = "secrets";
          description = "Edit the secrets file";
          runtimeInputs = [ pkgs.sops ];
          text = ''
            sops secrets/secrets.enc.yaml
          '';
        }
        {
          name = "check";
          description = "Lint, then check if the flake is valid.";
          runtimeInputs = [ pkgs.nix pkgs.git ];
          text = ''
            ${lintScript}
            nix flake check --show-trace
          '';
        }
        {
          name = "update";
          description = "Update flake";
          runtimeInputs = [ pkgs.nix pkgs.git ];
          text = ''
            nix flake update
          '';
        }
        {
          name = "boot";
          description = "Rebuild boot NixOS configuration.";
          runtimeInputs = [ pkgs.nix ] ++ lib.optionals (!isDarwin) [ pkgs.nixos-rebuild ];
          text = ''
            sudo nixos-rebuild boot --upgrade --flake .#zeh-pc
          '';
        }
        {
          name = "rebuild";
          description = "Rebuild NixOS/Darwin configuration.";
          runtimeInputs = [ pkgs.nix ] ++ lib.optionals (!isDarwin) [ pkgs.nixos-rebuild ];
          text = ''
            if [ "$(uname)" = "Darwin" ]; then
              sudo -H darwin-rebuild switch --flake .#zeh-mac --show-trace
            else
              sudo -H nixos-rebuild switch --flake .#zeh-pc --show-trace \
                && (
                  if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
                    hyprctl reload >/dev/null 2>&1 || echo "ℹ️  Skipping hyprctl reload (Hyprland not reachable from this shell)"
                  else
                    echo "ℹ️  Skipping hyprctl reload (Hyprland not reachable from this shell)"
                  fi
                ) \
                && (
                  notify-send "󱄅 NixOS Rebuild" "Rebuild finished with success!" 2>/dev/null \
                    || echo "✅ Rebuild completed"
                )
            fi
          '';
        }
        {
          name = "rollback";
          description = "Rollback NixOS configuration.";
          runtimeInputs = [ pkgs.nix ] ++ lib.optionals (!isDarwin) [ pkgs.nixos-rebuild ];
          text = ''
            sudo nixos-rebuild switch --rollback --flake .#zeh-pc
          '';
        }
        {
          name = "rebuildd";
          description = "Rebuild only Nix Darwin config";
          runtimeInputs = [ pkgs.nix pkgs.git ];
          text = ''
            nix build .#darwinConfigurations.zeh-mac.system
          '';
        }
        {
          name = "clean";
          description = "Clean up the Nix store.";
          runtimeInputs = [ pkgs.nix ];
          text = ''
            nix-collect-garbage -d
          '';
        }
        {
          name = "help";
          description = "Show this help.";
          runtimeInputs = [ ];
          text = ''
            printf 'Usage: nix run .#[command]\n\nCOMMANDS:\n'
            ${helpRows}
            printf '\n'
          '';
        }
      ];

      helpRows = lib.concatStrings (map (c: "printf '  %-10s %s\\n' ${c.name} '${c.description}'\n") commands);

      mkApp =
        c:
        let
          script = pkgs.writeShellApplication {
            name = c.name;
            runtimeInputs = c.runtimeInputs;
            text = ''
              export PATH="${hostPath}:$PATH"
              ${c.text}
            '';
          };
        in
        {
          type = "app";
          program = lib.getExe script;
        };
    in
    let
      appMap = builtins.listToAttrs (map (c: { name = c.name; value = mkApp c; }) commands);
    in
    {
      # `nix run` with no argument shows help, mirroring `make`'s default goal.
      apps = appMap // { default = appMap.help; };
    };
}
