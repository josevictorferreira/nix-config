# Aspect: core-jvf
# Imports jvf aggregator modules (users, hardware, system, roles) and core
# identity options as reusable NixOS/Darwin module sets.
# Hosts pull these via self.modules.{nixos,darwin}.core-jvf.
#
# NOTE: hardware/default.nix is NixOS-only (amd-gpu, bluetooth, logitech).
# NOTE: distro-grub-themes is NOT included here (see task 11).
{ ... }:
{
  flake.modules.nixos.core-jvf = {
    imports = [
      ../core/options.nix
      ../legacy/_/users/repositories.nix
      # users/default.nix migrated to modules/aspects/users.nix
      # wrappers.nix migrated to modules/aspects/wrappers.nix
      ../legacy/_/hardware/default.nix
      ../legacy/_/system/default.nix
      ../legacy/_/roles/default.nix
    ];
  };

  flake.modules.darwin.core-jvf = {
    imports = [
      ../core/options.nix
      ../legacy/_/users/repositories.nix
      # users/default.nix migrated to modules/aspects/users.nix
      # wrappers.nix migrated to modules/aspects/wrappers.nix
      # hardware excluded — NixOS-only (amd-gpu, bluetooth, logitech)
      ../legacy/_/system/default.nix
      ../legacy/_/roles/default.nix
    ];
  };
}
