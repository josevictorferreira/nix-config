{
  description = "Project with PostgreSQL and Ruby sandbox";

  inputs = {
    nix-config.url = "path:/home/josevictor/.config/nix";
  };

  outputs = { self, nix-config, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs
        (map (s: { name = s; value = f s; }) systems);
    in
    {
      devShells = forAllSystems (system: {
        default = nix-config.lib.${system}.mkSandboxShell {
          projectRoot = ./.;
          services.postgres = true;
          packages = with nix-config.lib.${system}.pkgs; [
            ruby_3_3
            bundler
          ];
          env = {
            RUBY_VERSION = "3.3";
          };
        };
      });
    };
}
