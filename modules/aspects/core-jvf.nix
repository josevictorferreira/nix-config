# Aspect: core-jvf
# Imports jvf core identity options and unmigrated program modules
# as reusable NixOS/Darwin module sets.
# Hosts pull these via self.modules.{nixos,darwin}.core-jvf.
#
# NOTE: distro-grub-themes is NOT included here (see task 11).
{ ... }:
let
  # Unmigrated program modules still needed by dendritic role aspects.
  # These provide option definitions (jvf.programs.*, jvf.aiTools.*).
  # TODO: migrate each to dendritic aspect, then remove from here.
  unmigrated-programs = [
    # AI Tools migrated to dendritic aspects (Phase 9 complete)
    ../legacy/_/programs/opencode
    ../legacy/_/programs/claudecode.nix
    ../legacy/_/programs/cursor.nix
    ../legacy/_/programs/droid.nix
    ../legacy/_/programs/gemini.nix
    ../legacy/_/programs/weechat
  ];
in
{
  flake.modules.nixos.core-jvf = {
    imports = [
      ../core/options.nix
      # hardware migrated to dendritic aspects (Phase 6 complete)
      # system modules migrated to dendritic aspects (Phase 2 complete)
      # roles migrated to dendritic aspects (Phase 7 complete)
    ]
    ++ unmigrated-programs;
  };

  flake.modules.darwin.core-jvf = {
    imports = [
      ../core/options.nix
      # hardware excluded — NixOS-only (amd-gpu, bluetooth, logitech)
      # system modules migrated to dendritic aspects (Phase 2 complete)
      # roles migrated to dendritic aspects (Phase 7 complete)
    ]
    ++ unmigrated-programs;
  };
}
