# True Dendritic Module Migration - Tasks

## Overview
Transform 100+ legacy NixOS/Darwin modules into true dendritic flake-parts modules.

**Total Tasks**: 76
**Estimated Effort**: Very Large
**Parallelizable**: Limited (dependency order matters)

---

## Phase 1: Foundation (Tasks 1-3)
**Goal**: Refactor base options used by all other modules.
**Dependencies**: None (can start immediately)
**Parallel**: Tasks 1-2 can run in parallel

- [ ] **Task 1**: Refactor `users/default.nix` to dendritic aspect
  - **What**: Transform `modules/legacy/_/users/default.nix` into `modules/aspects/users.nix`
  - **Define**: `flake.modules.nixos.users` and `flake.modules.darwin.users`
  - **Preserve**: All `jvf.users.*` options exactly as-is
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.users.type.name` returns "attrsOf"
  - **Verify**: `nix eval .#darwinConfigurations.macos-macbook.options.jvf.users.type.name` returns "attrsOf"
  - **Blocked By**: None
  - **Blocks**: Task 13+ (all roles)

- [ ] **Task 2**: Refactor `users/wrappers.nix` to dendritic aspect
  - **What**: Transform `modules/legacy/_/users/wrappers.nix` into `modules/aspects/wrappers.nix`
  - **Define**: `flake.modules.nixos.wrappers` and `flake.modules.darwin.wrappers`
  - **Preserve**: `jvf.wrappers.users` option and all wrapper logic
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.wrappers.users.type.name` returns "attrsOf"
  - **Verify**: Wrapper scripts still generate correctly
  - **Blocked By**: None
  - **Blocks**: Task 9+ (all programs)

- [ ] **Task 3**: Refactor `users/repositories.nix` to dendritic aspect
  - **What**: Transform `modules/legacy/_/users/repositories.nix` into `modules/aspects/repositories.nix`
  - **Define**: `flake.modules.nixos.repositories` and `flake.modules.darwin.repositories`
  - **Verify**: `nix flake check` passes
  - **Blocked By**: None
  - **Blocks**: None (leaf module)

### Phase 1 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.users.josevictor.enable` → Must return true
- [ ] Run: `nix eval .#darwinConfigurations.macos-macbook.config.jvf.users.josevictorferreira.enable` → Must return true

---

## Phase 2: System Core (Tasks 4-20)
**Goal**: Refactor independent system modules.
**Dependencies**: Phase 1 complete
**Parallel**: Tasks 4-19 can run in parallel (independent modules)

- [ ] **Task 4**: Refactor `system/locale.nix` to dendritic aspect
  - **What**: Transform `modules/legacy/_/system/locale.nix` to `modules/aspects/system-locale.nix`
  - **Define**: Both nixos and darwin classes
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.i18n.defaultLocale` returns "en_US.UTF-8"
  - **Blocked By**: None

- [ ] **Task 5**: Refactor `system/nixpkgs.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-nixpkgs.nix`
  - **Define**: Both classes
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.nixpkgs.config.allowUnfree` → true
  - **Blocked By**: None

- [ ] **Task 6**: Refactor `system/nix-daemon.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-nix-daemon.nix`
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.nix.settings.experimental-features` contains "nix-command"
  - **Blocked By**: None

- [ ] **Task 7**: Refactor `system/networking.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-networking.nix`
  - **Define**: Both classes (different implementations)
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.networking.hostName` → "nixos-desktop"
  - **Blocked By**: None

- [ ] **Task 8**: Refactor `system/security.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-security.nix`
  - **Define**: Both classes
  - **Verify**: `nix flake check` passes
  - **Blocked By**: None

- [ ] **Task 9**: Refactor `system/xdg.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-xdg.nix`
  - **Define**: Both classes
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.xdg.portal.enable` → true
  - **Blocked By**: None

- [ ] **Task 10**: Refactor `system/audio.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-audio.nix`
  - **Define**: NixOS only (darwin uses different audio system)
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.services.pipewire.enable` → true
  - **Blocked By**: None

- [ ] **Task 11**: Refactor `system/base-programs.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-base-programs.nix`
  - **Define**: Both classes
  - **Verify**: System packages are installed
  - **Blocked By**: None

- [ ] **Task 12**: Refactor `system/base-services.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-base-services.nix`
  - **Define**: Both classes
  - **Verify**: Services are enabled
  - **Blocked By**: None

- [ ] **Task 13**: Refactor `system/environment.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-environment.nix`
  - **Define**: Both classes
  - **Verify**: Environment variables set
  - **Blocked By**: None

- [ ] **Task 14**: Refactor `system/firewall.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-firewall.nix`
  - **Define**: NixOS only
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.networking.firewall.enable` → true
  - **Blocked By**: None

- [ ] **Task 15**: Refactor `system/display.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-display.nix`
  - **Define**: NixOS only (graphics/display settings)
  - **Verify**: Display configuration present
  - **Blocked By**: None

- [ ] **Task 16**: Refactor `system/flatpak.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-flatpak.nix`
  - **Define**: NixOS only
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.services.flatpak.enable` → true
  - **Blocked By**: None

- [ ] **Task 17**: Refactor `system/logind.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-logind.nix`
  - **Define**: NixOS only
  - **Verify**: Logind settings present
  - **Blocked By**: None

- [ ] **Task 18**: Refactor `system/power-management.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-power-management.nix`
  - **Define**: NixOS only
  - **Verify**: Power settings present
  - **Blocked By**: None

- [ ] **Task 19**: Refactor `system/virtualization.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/system-virtualization.nix`
  - **Define**: NixOS only (docker, podman, qemu)
  - **Verify**: Virtualization services enabled
  - **Blocked By**: None

- [ ] **Task 20**: Remove system/default.nix aggregator
  - **What**: Once all system modules are dendritic, remove the aggregator
  - **Update**: Host files to import individual system aspects instead of system.default
  - **Verify**: `nix flake check` passes
  - **Blocked By**: Tasks 4-19
  - **Blocks**: None (cleanup)

### Phase 2 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath` → Must return store path
- [ ] Run: All system-specific evaluations must work

---

## Phase 3: Programs - Core Dev Tools (Tasks 21-35)
**Goal**: Refactor most-used development programs.
**Dependencies**: Phase 1 (wrappers), Phase 2
**Parallel**: Tasks 21-34 can run in parallel

- [ ] **Task 21**: Refactor `programs/zsh` to dendritic aspect
  - **What**: Transform `programs/zsh/default.nix` and plugins/ to `modules/aspects/programs-zsh.nix`
  - **Define**: Both classes
  - **Depends On**: wrappers (for shell wrapper support)
  - **Verify**: `nix eval .#nixosConfigurations.nixos-desktop.config.programs.zsh.enable` → true
  - **Blocked By**: Task 2

- [ ] **Task 22**: Refactor `programs/starship.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-starship.nix`
  - **Define**: Both classes
  - **Verify**: Starship config present
  - **Blocked By**: None

- [ ] **Task 23**: Refactor `programs/git.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-git.nix`
  - **Define**: Both classes
  - **Verify**: Git config present
  - **Blocked By**: None

- [ ] **Task 24**: Refactor `programs/neovim.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-neovim.nix`
  - **Define**: Both classes
  - **Verify**: Neovim package installed
  - **Blocked By**: None

- [ ] **Task 25**: Refactor `programs/tmux.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-tmux.nix`
  - **Define**: Both classes
  - **Verify**: Tmux config present
  - **Blocked By**: None

- [ ] **Task 26**: Refactor `programs/ghostty.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-ghostty.nix`
  - **Define**: Both classes
  - **Verify**: Ghostty config present
  - **Blocked By**: None

- [ ] **Task 27**: Refactor `programs/kitty.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-kitty.nix`
  - **Define**: Both classes
  - **Verify**: Kitty config present
  - **Blocked By**: None

- [ ] **Task 28**: Refactor `programs/alacritty.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-alacritty.nix`
  - **Define**: Both classes
  - **Verify**: Alacritty config present
  - **Blocked By**: None

- [ ] **Task 29**: Refactor `programs/fzf.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-fzf.nix`
  - **Define**: Both classes
  - **Verify**: Fzf shell integration enabled
  - **Blocked By**: None

- [ ] **Task 30**: Refactor `programs/bat.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-bat.nix`
  - **Define**: Both classes
  - **Verify**: Bat config present
  - **Blocked By**: None

- [ ] **Task 31**: Refactor `programs/eza.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-eza.nix`
  - **Define**: Both classes
  - **Verify**: Eza shell aliases present
  - **Blocked By**: None

- [ ] **Task 32**: Refactor `programs/zoxide.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-zoxide.nix`
  - **Define**: Both classes
  - **Verify**: Zoxide shell integration enabled
  - **Blocked By**: None

- [ ] **Task 33**: Refactor `programs/lazygit.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-lazygit.nix`
  - **Define**: Both classes
  - **Verify**: Lazygit config present
  - **Blocked By**: None

- [ ] **Task 34**: Refactor `programs/btop.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/programs-btop.nix`
  - **Define**: Both classes
  - **Verify**: Btop config present
  - **Blocked By**: None

### Phase 3 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: Verify all program configs evaluate correctly
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.zsh.enable` → true

---

## Phase 4: Programs - Additional Tools (Tasks 35-50)
**Goal**: Refactor remaining program modules.
**Dependencies**: Phase 1, Phase 3 core
**Parallel**: Tasks 35-49 can run in parallel

- [ ] **Task 35**: Refactor `programs/direnv.nix` to dendritic aspect
- [ ] **Task 36**: Refactor `programs/yazi.nix` to dendritic aspect
- [ ] **Task 37**: Refactor `programs/walker.nix` to dendritic aspect
- [ ] **Task 38**: Refactor `programs/wallust.nix` to dendritic aspect
- [ ] **Task 39**: Refactor `programs/jq.nix` to dendritic aspect
- [ ] **Task 40**: Refactor `programs/ripgrep.nix` to dendritic aspect
- [ ] **Task 41**: Refactor `programs/mycli.nix` to dendritic aspect
- [ ] **Task 42**: Refactor `programs/pgcli.nix` to dendritic aspect
- [ ] **Task 43**: Refactor `programs/pgformatter.nix` to dendritic aspect
- [ ] **Task 44**: Refactor `programs/mongosh.nix` to dendritic aspect
- [ ] **Task 45**: Refactor `programs/redis.nix` to dendritic aspect
- [ ] **Task 46**: Refactor `programs/ranger.nix` to dendritic aspect
- [ ] **Task 47**: Refactor `programs/zellij.nix` to dendritic aspect
- [ ] **Task 48**: Refactor `programs/wezterm.nix` to dendritic aspect

### Phase 4 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: Spot-check 5 random program configs

---

## Phase 5: Services (Tasks 49-51)
**Goal**: Refactor service modules.
**Dependencies**: Phase 1, Phase 2
**Parallel**: All service tasks can run in parallel

- [ ] **Task 49**: Refactor `services/smb.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/services-smb.nix`
  - **Define**: NixOS only
  - **Verify**: SMB config present

- [ ] **Task 50**: Refactor `services/cephfs.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/services-cephfs.nix`
  - **Define**: NixOS only
  - **Verify**: CephFS config present

- [ ] **Task 51**: Refactor `services/llm-proxy.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/services-llm-proxy.nix`
  - **Define**: NixOS only
  - **Verify**: LLM proxy config present

### Phase 5 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS

---

## Phase 6: Hardware (Tasks 52-56)
**Goal**: Refactor hardware modules (NixOS only).
**Dependencies**: None (independent)
**Parallel**: Tasks 52-55 can run in parallel

- [ ] **Task 52**: Refactor `hardware/amd-gpu.nix` to dendritic aspect
- [ ] **Task 53**: Refactor `hardware/bluetooth.nix` to dendritic aspect
- [ ] **Task 54**: Refactor `hardware/logitech.nix` to dendritic aspect
- [ ] **Task 55**: Refactor `hardware/openrgb.nix` to dendritic aspect
- [ ] **Task 56**: Remove hardware/default.nix aggregator
  - **Update**: Hosts to import individual hardware aspects

### Phase 6 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS

---

## Phase 7: Roles (Tasks 57-69)
**Goal**: Refactor role modules to use dendritic programs.
**Dependencies**: Phase 3, Phase 4 (programs), Phase 5 (services)
**Parallel**: Tasks 57-68 can run in parallel

**Important**: Roles import programs. Update to import dendritic program aspects.

- [ ] **Task 57**: Refactor `roles/development.nix` to dendritic aspect
  - **What**: Transform to `modules/aspects/roles-development.nix`
  - **Update**: Import dendritic program aspects instead of legacy
  - **Imports**: programs-zsh, programs-starship, programs-git, programs-neovim, programs-tmux

- [ ] **Task 58**: Refactor `roles/webDevelopment.nix` to dendritic aspect
- [ ] **Task 59**: Refactor `roles/opsDevelopment.nix` to dendritic aspect
- [ ] **Task 60**: Refactor `roles/monitoring.nix` to dendritic aspect
- [ ] **Task 61**: Refactor `roles/communication.nix` to dendritic aspect
- [ ] **Task 62**: Refactor `roles/aiDevelopment.nix` to dendritic aspect
- [ ] **Task 63**: Refactor `roles/localAi.nix` to dendritic aspect
- [ ] **Task 64**: Refactor `roles/designing.nix` to dendritic aspect
- [ ] **Task 65**: Refactor `roles/media.nix` to dendritic aspect
- [ ] **Task 66**: Refactor `roles/gaming.nix` to dendritic aspect
- [ ] **Task 67**: Refactor `roles/networkStorage.nix` to dendritic aspect
  - **Imports**: services-smb, services-cephfs

- [ ] **Task 68**: Refactor `roles/privacy.nix` to dendritic aspect
- [ ] **Task 69**: Refactor `roles/documenting.nix` to dendritic aspect
- [ ] **Task 70**: Remove roles/default.nix aggregator
  - **Update**: Hosts to import individual role aspects

### Phase 7 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: Verify role imports work: `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.roles.development.enable` → true

---

## Phase 8: Desktop Environment (Tasks 71-91)
**Goal**: Refactor Hyprland ecosystem.
**Dependencies**: Phase 3 (programs)
**Parallel**: Tasks 71-90 can run in parallel (after core hyprland)

- [ ] **Task 71**: Refactor `desktop/hyprland/default.nix` (main module)
- [ ] **Task 72**: Refactor `desktop/hyprland/monitors.nix`
- [ ] **Task 73**: Refactor `desktop/hyprland/workspaces.nix`
- [ ] **Task 74**: Refactor `desktop/hyprland/input.nix`
- [ ] **Task 75**: Refactor `desktop/hyprland/binds.nix`
- [ ] **Task 76**: Refactor `desktop/hyprland/windowrule.nix`
- [ ] **Task 77**: Refactor `desktop/hyprland/general.nix`
- [ ] **Task 78**: Refactor `desktop/hyprland/decoration.nix`
- [ ] **Task 79**: Refactor `desktop/hyprland/animations.nix`
- [ ] **Task 80**: Refactor `desktop/hyprland/layout.nix`
- [ ] **Task 81**: Refactor `desktop/hyprland/misc.nix`
- [ ] **Task 82**: Refactor `desktop/hyprland/waybar/` directory
- [ ] **Task 83**: Refactor `desktop/hyprland/rofi/` directory
- [ ] **Task 84**: Refactor `desktop/hyprland/ags/` directory
- [ ] **Task 85**: Refactor `desktop/hyprland/swaync/` directory
- [ ] **Task 86**: Refactor `desktop/hyprland/wlogout/` directory
- [ ] **Task 87**: Refactor `desktop/hyprland/wlsunset/` directory
- [ ] **Task 88**: Refactor `desktop/hyprland/swww/` directory
- [ ] **Task 89**: Refactor `desktop/hyprland/hyprlock/` directory
- [ ] **Task 90**: Refactor `desktop/hyprland/hypridle/` directory
- [ ] **Task 91**: Refactor `desktop/hyprland/plugins/` directory

### Phase 8 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.desktop.hyprland.enable` → true
- [ ] Run: Verify Hyprland config evaluates

---

## Phase 9: AI Tools (Tasks 92-95)
**Goal**: Refactor complex AI tools module.
**Dependencies**: Phase 3, Phase 7
**Note**: This is the most complex module. Do last.

- [ ] **Task 92**: Refactor `common/ai-tools/default.nix`
- [ ] **Task 93**: Refactor `common/ai-tools/skills.nix`
- [ ] **Task 94**: Refactor `common/ai-tools/mcp-servers.nix`
- [ ] **Task 95**: Refactor `common/ai-tools/rules/` directory

### Phase 9 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: Verify AI tools config evaluates

---

## Phase 10: Final Cleanup (Task 96)
**Goal**: Remove legacy directory and finalize.
**Dependencies**: All previous phases

- [ ] **Task 96**: Remove `modules/legacy/_/` directory entirely
  - **Verify**: All imports updated to dendritic aspects
  - **Verify**: No references to legacy path remain
  - **Verify**: `nix flake check` passes
  - **Verify**: Both hosts build successfully
  - **Verify**: `make rebuild` works on both hosts

### Phase 10 Testing Gate
- [ ] Run: `nix flake check --show-trace` → Must PASS
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath` → Returns store path
- [ ] Run: `nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath` → Returns store path
- [ ] Run: `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.wrappers.users.type.name` → Returns "attrsOf"
- [ ] Run: `make check` → Must PASS

---

## Success Criteria

- [ ] All 100+ modules refactored to dendritic aspects
- [ ] `modules/legacy/_/` directory removed
- [ ] `nix flake check` passes with no warnings
- [ ] Both hosts (nixos-desktop, macos-macbook) build successfully
- [ ] All `jvf.*` options preserved and functional
- [ ] `make rebuild` works on both hosts
- [ ] No behavioral changes (pure refactoring)

---

## Notes for Implementation

1. **Incremental commits**: Commit after each task
2. **Green builds**: Ensure `make check` passes after each task
3. **Parallel execution**: Tasks within same phase can run in parallel
4. **Dependency tracking**: Respect "Blocked By" / "Blocks" relationships
5. **Option preservation**: Keep exact same `jvf.*` option paths
6. **Platform support**: NixOS-only modules don't need darwin class
7. **Testing**: Each task has specific verification command
8. **Documentation**: Update notepad with learnings after each wave
