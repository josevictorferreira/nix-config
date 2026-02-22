# Aspect: secrets-sops
# Imports sops-nix modules for both NixOS and Darwin hosts.
{ inputs, ... }:
{
  flake.modules.nixos.secrets-sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };
  flake.modules.darwin.secrets-sops = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
  };
}
