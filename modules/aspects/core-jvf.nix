# Aspect: core-jvf
# Imports jvf aggregator modules (users, hardware, system, roles) as
# reusable NixOS/Darwin module sets.  Hosts pull these via
# self.modules.{nixos,darwin}.core-jvf.
#
# NOTE: hardware/default.nix is NixOS-only (amd-gpu, bluetooth, logitech).
# NOTE: distro-grub-themes is NOT included here (see task 11).
{ ... }:
{
  flake.modules.nixos.core-jvf = {
    imports = [
      ../legacy/_/users/repositories.nix
      ../legacy/_/users/wrappers.nix
      ../legacy/_/users/default.nix
      ../legacy/_/hardware/default.nix
      ../legacy/_/system/default.nix
      ../legacy/_/roles/default.nix
    ];
  };

  flake.modules.darwin.core-jvf = {
    imports = [
      ../legacy/_/users/repositories.nix
      ../legacy/_/users/wrappers.nix
      ../legacy/_/users/default.nix
      # hardware excluded — NixOS-only (amd-gpu, bluetooth, logitech)
      ../legacy/_/system/default.nix
      ../legacy/_/roles/default.nix
    ];
  };
}
