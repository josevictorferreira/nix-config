# Aspect: checks-theme-switcher-vm
# NixOS VM integration test for the dual-theme runtime model.
# Verifies: profile artifacts, switcher commands, systemd units, rebuild idempotency.
{ inputs, self, ... }:
{
  perSystem =
    { system
    , pkgs
    , lib
    , ...
    }:
    let
      # ── Module stack ────────────────────────────────────────────────────
      # core-jvf: options + identity
      # core-theme: theme options + profile artifact materialization via jvf.home
      # home: jvf.home activation scripts
      # wrappers: installs switcher script to user packages
      # desktop-hyprland-theme-switcher: switcher CLI + systemd services/timers
      themeModules = [
        self.modules.nixos.core-jvf
        self.modules.nixos.core-theme
        self.modules.nixos.home
        self.modules.nixos.wrappers
        self.modules.nixos.desktop-hyprland-theme-switcher
      ];
    in
    { }
    // lib.optionalAttrs (lib.hasSuffix "-linux" system) {
      # VM tests require a Linux builder; skip on Darwin.
      checks.theme-switcher-vm = pkgs.testers.nixosTest {
        name = "theme-switcher-vm";

        nodes.machine =
          { lib, ... }:
          {
            imports = themeModules ++ [
              (
                { lib, ... }:
                {
                  nixpkgs.hostPlatform = system;
                  system.stateVersion = "26.05";
                  jvf.core = {
                    username = "alice";
                    host = "test-host";
                    os = "nixos";
                  };
                  users.users.alice = {
                    isNormalUser = lib.mkForce true;
                    home = "/home/alice";
                    group = lib.mkForce "users";
                    initialPassword = "alice";
                    createHome = true;
                  };
                  users.groups.users = { };
                }
              )
            ];
          };

        testScript = ''

          machine.start()
          machine.wait_for_unit("multi-user.target")

          # Locate switcher binary (installed via users.users.alice.packages)
          switcher = machine.succeed(
            "find /nix -name 'jvf-theme-switch' -type f 2>/dev/null | head -1"
          ).strip()
          assert switcher != "", "jvf-theme-switch binary not found in /nix"

          # Systemd executes the script directly, so the shebang must be the
          # first bytes of the file; an interactive shell may hide this by
          # falling back to interpreting scripts with a bad shebang.
          machine.succeed(f"test \"$(head -c 2 '{switcher}')\" = '#!'")
          machine.succeed(f"bash -n '{switcher}'")

          # Debug: filesystem state
          machine.succeed("ls -la /home/alice/.local/share/jvf-theme/ 2>&1 || true")
          # ── 1. Profile artifacts exist ──────────────────────────────────
          machine.succeed("test -d /home/alice/.local/share/jvf-theme/profiles/dark")
          machine.succeed("test -d /home/alice/.local/share/jvf-theme/profiles/light")

          # Pre-create runtime state dir with correct ownership
          machine.succeed("mkdir -p /home/alice/.local/state/jvf-theme && chown -R alice:users /home/alice/.local/state")

          # Start a fake Waybar-like process whose command line contains
          # "waybar". This catches regressions where the switcher cannot signal
          # Waybar from click-handler environments with a restricted PATH.
          machine.succeed(
            "sudo -u alice sh -c '"
            + "${pkgs.python3}/bin/python3 -c \"import os, pathlib, signal, time; signal.signal(signal.SIGUSR2, lambda *_: (pathlib.Path(\\\"/home/alice/waybar-reloaded\\\").touch(), os._exit(0))); pathlib.Path(\\\"/home/alice/waybar-ready\\\").touch(); time.sleep(600)\" waybar "
            + ">/tmp/fake-waybar.log 2>&1 & echo $! > /home/alice/fake-waybar.pid'"
          )
          machine.wait_until_succeeds("test -f /home/alice/waybar-ready")

          # ── 2. jvf-theme-switch light ───────────────────────────────────
          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + f"{switcher} light"
          )
          machine.succeed("test -f /home/alice/.local/state/jvf-theme/mode")
          mode = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          assert mode == "light", f"expected mode=light, got {mode}"

          machine.succeed("test -L /home/alice/.local/state/jvf-theme/current")
          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/light"), f"expected current→light, got {target}"

          machine.succeed("test -f /home/alice/.local/state/jvf-theme/last-switch")
          machine.wait_until_succeeds("test -f /home/alice/waybar-reloaded")
          hooks_log = machine.succeed("cat /home/alice/.local/state/jvf-theme/hooks.log")
          assert "waybar reload: ok" in hooks_log, "switcher should signal running Waybar"

          # ── 3. jvf-theme-switch dark ────────────────────────────────────
          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + f"{switcher} dark"
          )
          mode = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          assert mode == "dark", f"expected mode=dark, got {mode}"

          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/dark"), f"expected current→dark, got {target}"

          # ── 4. jvf-theme-switch toggle ─────────────────────────────────
          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + f"{switcher} toggle"
          )
          mode = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          assert mode == "light", f"toggle from dark should set mode=light, got {mode}"

          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/light"), f"toggle from dark should select light, got {target}"

          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + f"{switcher} toggle"
          )
          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/dark"), f"toggle from light should select dark, got {target}"

          # ── 5. auto with FAKE_HOUR=7 → light ───────────────────────────
          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + "JFV_THEME_FAKE_HOUR=7 "
            + f"{switcher} auto"
          )
          mode = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          assert mode == "auto", f"expected mode=auto, got {mode}"

          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/light"), f"hour=7 should select light, got {target}"

          # ── 6. auto with FAKE_HOUR=14 → dark ───────────────────────────
          machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + "JFV_THEME_FAKE_HOUR=14 "
            + f"{switcher} auto"
          )
          target = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target.endswith("/dark"), f"hour=14 should select dark, got {target}"

          # ── 7. status --verbose ─────────────────────────────────────────
          status_out = machine.succeed(
            "sudo -u alice "
            + "JFV_THEME_STATE_DIR=/home/alice/.local/state/jvf-theme "
            + "JFV_THEME_PROFILES_DIR=/home/alice/.local/share/jvf-theme/profiles "
            + f"{switcher} status --verbose"
          )
          assert "Mode: auto" in status_out, "status should show Mode: auto"
          assert "Profile: dark" in status_out, "status should show Profile: dark"
          assert "Current target:" in status_out, "status --verbose should show Current target"
          assert "Schedule:" in status_out, "status --verbose should show Schedule"
          assert "Last switch:" in status_out, "status --verbose should show Last switch"
          assert "Reload warnings:" in status_out, "status --verbose should show Reload warnings"

          # ── 8. Systemd timer defined ────────────────────────────────────
          # Verify the timer unit file exists in the user's systemd directory
          timer_unit = machine.succeed(
            "find /etc/systemd/user/ -name 'jvf-theme-switcher.timer' -not -path '*/wants/*' 2>/dev/null | head -1 || true"
          ).strip()
          assert timer_unit != "", "jvf-theme-switcher.timer unit file should exist"

          # Verify timer content
          timer_content = machine.succeed(f"cat '{timer_unit}'")
          assert "OnCalendar" in timer_content, "timer should have OnCalendar"
          assert "Persistent=true" in timer_content, "timer should have Persistent=true"

          # ── 9. Systemd services defined ─────────────────────────────────
          svc_unit = machine.succeed(
            "find /etc/systemd/user/ -name 'jvf-theme-switcher.service' -not -path '*/wants/*' 2>/dev/null | head -1 || true"
          ).strip()
          assert svc_unit != "", "jvf-theme-switcher.service unit file should exist"

          svc_content = machine.succeed(f"cat '{svc_unit}'")
          assert "ExecStart" in svc_content, "service should have ExecStart"
          assert "jvf-theme-switch auto" in svc_content, "service should run jvf-theme-switch auto"

          resume_unit = machine.succeed(
            "find /etc/systemd/user/ -name 'jvf-theme-switcher-resume.service' -not -path '*/wants/*' 2>/dev/null | head -1 || true"
          ).strip()
          assert resume_unit != "", "jvf-theme-switcher-resume.service unit file should exist"

          resume_content = machine.succeed(f"cat '{resume_unit}'")
          assert "ExecStop" in resume_content, "resume service should have ExecStop"
          assert "RemainAfterExit" in resume_content, "resume service should have RemainAfterExit"
          assert "jvf-theme-switch auto" in resume_content, "resume service should run jvf-theme-switch auto in ExecStop"

          # ── 10. Rebuild idempotency ─────────────────────────────────────
          # Record runtime state before simulated rebuild
          mode_before = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          target_before = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          switch_before = machine.succeed("cat /home/alice/.local/state/jvf-theme/last-switch").strip()

          # Find and re-run activation (simulates rebuild)
          activate = machine.succeed(
            "ls /run/current-system/activate 2>/dev/null || find /run/current-system -name 'activate' -type f 2>/dev/null | head -1 || true"
          ).strip()
          if activate:
              machine.succeed(activate)
          else:
              # Fallback: re-run the jvf-home activation for alice
              machine.succeed(
                  "find /run/current-system -name 'jvf-home-*' -type f 2>/dev/null | head -1 | xargs -I{} bash {}"
              )

          # Runtime state must survive rebuild — switcher owns ~/.local/state/jvf-theme/
          mode_after = machine.succeed("cat /home/alice/.local/state/jvf-theme/mode").strip()
          assert mode_after == mode_before, \
            f"rebuild should NOT overwrite mode: {mode_before} → {mode_after}"

          # The current symlink may change type (relative vs absolute) but must
          # still point to the same profile
          target_after = machine.succeed("readlink /home/alice/.local/state/jvf-theme/current").strip()
          assert target_after.endswith("/dark") or target_after.endswith("/light"), \
            f"current should still point to a profile after rebuild, got {target_after}"
          assert target_after == target_before, \
            f"rebuild should NOT change current symlink: {target_before} → {target_after}"

          switch_after = machine.succeed("cat /home/alice/.local/state/jvf-theme/last-switch").strip()
          assert switch_after == switch_before, \
            f"rebuild should NOT overwrite last-switch: {switch_before} → {switch_after}"
        '';
      };
    };
}
