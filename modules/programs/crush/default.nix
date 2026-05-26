# Aspect: programs-crush
# Defines jvf.programs.crush options for the Crush AI coding agent.
# Config materialization via jvf.home; wrappers provide the package.
# Crush reads config from ~/.config/crush/crush.json.
{
  ...
}:
let
  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.crush;
      json = pkgs.formats.json { };
    in
    {
      options.jvf.programs.crush = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing Crush configuration to.";
        };

        settings = lib.mkOption {
          inherit (json) type;
          default = { };
          description = "Crush config (crush.json) contents.";
        };
      };

      imports = [
        ./_/provider.nix
      ];

      config = {
        jvf.wrappers.users.${cfg.username}.programs.crush = {
          packages = [ pkgs.crush ];
        };

        jvf.home.users.${cfg.username}.items.".config/crush/crush.json" = {
          kind = "file";
          mode = "copy";
          json = cfg.settings;
        };
      };
    };
in
{
  flake.modules.nixos.programs-crush = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-crush = mkConfig { isDarwin = true; };
}
