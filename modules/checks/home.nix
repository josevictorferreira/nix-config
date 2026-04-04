# Aspect: checks-home
# perSystem checks for the jvf.home materialization module.
#   jvf-home-eval  — pure Nix eval guard (no VM needed)
#   jvf-home-vm    — NixOS VM integration test
{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      # ── Minimal module stack shared by both checks ─────────────────────────
      # Provides: jvf.core.*, jvf.home.*
      coreModules = [
        self.modules.nixos.core-jvf
        self.modules.nixos.home
      ];

      # A minimal NixOS stub that satisfies jvf.home's dependencies.
      minimalStub =
        { lib, ... }:
        {
          system.stateVersion = "26.05";
          nixpkgs.hostPlatform = system;
          jvf.core = {
            username = "alice";
            host = "test-host";
            os = "nixos";
          };
          users.users.alice = {
            isNormalUser = lib.mkForce true;
            home = "/home/alice";
            group = lib.mkForce "users";
          };
          users.groups.users = { };
        };

      # ── Eval check ─────────────────────────────────────────────────────────
      # Evaluate the home module stack and assert _compiled output at eval time.
      homeEval = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = coreModules ++ [
          minimalStub
          (
            { ... }:
            {
              jvf.home.files.".config/test.conf" = {
                kind = "file";
                text = "hello";
              };
              jvf.home.files.".config/another.conf" = {
                kind = "file";
                text = "world";
              };
            }
          )
        ];
      };

      compiledUsers = homeEval.config.jvf.home._compiled.users;
      aliceItems = compiledUsers.alice.items or [ ];

      evalAssertions = [
        {
          name = "alice-items-is-list";
          check = builtins.isList aliceItems;
          message = "_compiled.users.alice.items must be a list";
        }
        {
          name = "alice-has-two-items";
          check = builtins.length aliceItems == 2;
          message = "alice must have exactly 2 compiled items, got ${toString (builtins.length aliceItems)}";
        }
        {
          name = "test-conf-appears";
          check = builtins.any (i: i.targetRel == ".config/test.conf") aliceItems;
          message = ".config/test.conf must appear in alice's compiled items";
        }
      ];

      failedAssertions = builtins.filter (a: !a.check) evalAssertions;

      evalCheckScript =
        if failedAssertions != [ ] then
          throw "jvf-home-eval: ${(builtins.head failedAssertions).message}"
        else
          "echo 'jvf-home-eval: all assertions passed'";

      # ── VM test helpers ─────────────────────────────────────────────────────
      waybarSrc = pkgs.runCommand "test-waybar-dir" { } ''
        mkdir -p $out
        echo "/* waybar config */" > $out/config.jsonc
      '';

      mkClaudeDir =
        settings:
        pkgs.runCommand "test-claude-dir" { } ''
          mkdir -p $out
          cp ${(pkgs.formats.json { }).generate "settings.json" settings} $out/settings.json
        '';

      claudeSettingsA = {
        version = "A";
        mcpServers = { };
      };

      claudeSettingsB = {
        version = "B";
        mcpServers = { };
      };

      mkClaudePostInstall = userName: ''
        CLAUDE_JSON="/home/${userName}/.claude.json"
        SETTINGS_JSON="/home/${userName}/.claude/settings.json"
        if [ -f "$SETTINGS_JSON" ]; then
          if [ ! -f "$CLAUDE_JSON" ]; then
            echo "{}" > "$CLAUDE_JSON"
          fi
          ${pkgs.lib.getExe pkgs.jq} \
            --argjson newContent "$(cat "$SETTINGS_JSON")" \
            '. = $newContent' \
            "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp"
          mv -f "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
          chown "${userName}:users" "$CLAUDE_JSON"
        fi
      '';

      # Home config module for a given settings attrset + user name
      # priority: lib.mkDefault for base, lib.mkForce for specialisation override
      mkHomeConfigModule =
        settings: userName: priority:
        { lib, ... }:
        {
          jvf.home.files = {
            ".config/kitty/kitty.conf" = {
              kind = "file";
              text = "font_size 13\nfont_family JetBrains Mono";
            };
            ".config/waybar" = {
              kind = "dir";
              source = waybarSrc;
            };
            ".claude" = {
              kind = "dir";
              source = priority (mkClaudeDir settings);
              preserve = [
                "transcripts"
                "history.jsonl"
              ];
              postInstall = mkClaudePostInstall userName;
            };
          };
        };

    in
    {
      # ── Pure eval check ─────────────────────────────────────────────────────
      checks.jvf-home-eval = pkgs.stdenv.mkDerivation {
        name = "jvf-home-eval";
        src = pkgs.writeText "dummy" "eval";
        dontUnpack = true;
        buildPhase = ''
          ${evalCheckScript}
        '';
        installPhase = ''
          mkdir -p $out
          echo "jvf-home-eval passed" > $out/result
        '';
      };

      # ── VM integration test ─────────────────────────────────────────────────
      # Uses specialisation to switch from config-A to config-B inside the VM,
      # then asserts preserved files survive and settings.json reflects version B.
      checks.jvf-home-vm = pkgs.testers.nixosTest {
        name = "jvf-home-vm";

        nodes.machine =
          { lib, ... }:
          {
            imports = coreModules ++ [
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
              (mkHomeConfigModule claudeSettingsA "alice" lib.mkDefault)
            ];

            # Specialisation B: same structure but version = "B"
            specialisation.config-b.configuration = mkHomeConfigModule claudeSettingsB "alice" lib.mkForce;
          };

        testScript = ''
          machine.start()
          machine.wait_for_unit("multi-user.target")

          # Debug: capture activation and filesystem state
          status, output = machine.execute("cat /var/log/nixos-activation.log 2>/dev/null || journalctl -b -u nixos-activation || systemd-analyze blame | head -20 || true")
          print("ACTIVATION LOG:", output)
          status, output = machine.execute("ls -la /home/ && ls -la /home/alice/ 2>&1 || echo 'NO HOME DIR'")
          print("HOME DIRS:", output)
          status, output = machine.execute("systemctl status systemd-tmpfiles-setup.service 2>&1 | head -20")
          print("TMPFILES:", output)

          # 1. kitty.conf exists and contains sentinel
          machine.succeed("test -f /home/alice/.config/kitty/kitty.conf")
          machine.succeed("grep -q 'font_size 13' /home/alice/.config/kitty/kitty.conf")

          # 2. waybar dir exists
          machine.succeed("test -d /home/alice/.config/waybar")

          # 3. Create preserved files under .claude before switching
          machine.succeed("mkdir -p /home/alice/.claude/transcripts")
          machine.succeed("echo 'keep' > /home/alice/.claude/transcripts/keep.txt")
          machine.succeed("echo '[]' > /home/alice/.claude/history.jsonl")

          # 4. Switch to specialisation B (config-b)
          spec_b = machine.succeed("readlink /run/current-system/specialisation/config-b").strip()
          machine.succeed(f"{spec_b}/bin/switch-to-configuration test")

          # 5. Preserved files survive the switch
          machine.succeed("test -f /home/alice/.claude/transcripts/keep.txt")
          machine.succeed("test -f /home/alice/.claude/history.jsonl")

          # 6. settings.json now contains version B
          machine.succeed("grep -q '\"B\"' /home/alice/.claude/settings.json")

          # 7. .claude.json was updated by postInstall
          machine.succeed("test -f /home/alice/.claude.json")
          machine.succeed("grep -q '\"B\"' /home/alice/.claude.json")
        '';
      };
    };
}
