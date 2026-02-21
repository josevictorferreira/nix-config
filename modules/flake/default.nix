# Declares flake.modules as a mergeable option so multiple aspects
# can each contribute NixOS / Darwin module sets.
#
# Usage in aspect files:
#   flake.modules.nixos.<name> = { imports = [ ... ]; };
#   flake.modules.darwin.<name> = { imports = [ ... ]; };
#
# Consumed in host files:
#   self.modules.nixos.<name>   (or config.flake.modules.nixos.<name>)
{ lib, ... }:
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
    default = { };
    description = ''
      Reusable NixOS/Darwin module sets keyed by platform and aspect name.
      e.g. flake.modules.nixos.core-jvf = { imports = [ ... ]; };
    '';
  };
}
