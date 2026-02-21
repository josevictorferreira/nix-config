# Aspect: boot-grub-theme (NixOS only)
# Imports distro-grub-themes for GRUB theming.
# Note: distro-grub-themes exposes per-system nixosModules; hardcoded to
# x86_64-linux since that is the only NixOS platform in this config.
{ inputs, ... }:
{
  flake.modules.nixos.boot-grub-theme = {
    imports = [ inputs.distro-grub-themes.nixosModules.x86_64-linux.default ];
  };
}
