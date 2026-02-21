# Darwin host: macos-macbook
{ inputs, ... }:
{
  flake.darwinConfigurations.macos-macbook = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # Host-specific configuration
      ./hosts/macos-macbook/config.nix
    ]
    ++ (inputs.nixpkgs.lib.optionals (builtins.pathExists ./hosts/macos-macbook/variables.nix) [
      ./hosts/macos-macbook/variables.nix
    ]);
  };
}
