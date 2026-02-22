# Aspect: core-jvf
# Imports jvf core identity options.
# Hosts pull these via self.modules.{nixos,darwin}.core-jvf.
{ ... }:
{
  flake.modules.nixos.core-jvf = {
    imports = [
      ./_/options.nix
      # All modules migrated to dendritic aspects
    ];
  };

  flake.modules.darwin.core-jvf = {
    imports = [
      ./_/options.nix
      # All modules migrated to dendritic aspects
    ];
  };
}
