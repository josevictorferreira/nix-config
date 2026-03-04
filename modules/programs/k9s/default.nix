# Aspect: programs-k9s
# Defines jvf.programs.k9s options and platform-specific k9s terminal UI for Kubernetes.
# NixOS/Darwin: k9s package + config via wrappers + tokyonight skin + homelab config.
_:
let
  # Import default configs as pure data
  defaultSettings = import ./_/settings.nix { };
  clusters = import ./_/clusters.nix { };

  k9sModule =
    { config
    , lib
    , ...
    }:
    let
      cfg = config.jvf.programs.k9s;
      themeSkin = import ./_/skin.nix config.jvf.theme.colors;
    in
    {
      imports = [ ./options.nix ];

      config = {
        # Set defaults from imported configs
        jvf.programs.k9s = {
          settings = lib.mkDefault defaultSettings.settings;
          aliases = lib.mkDefault defaultSettings.aliases;
          skins = lib.mkDefault {
            tokyonight = themeSkin;
          };
        };

        environment = {
          variables = {
            K9S_CONFIG_DIR = "$HOME/.config/k9s";
          };
        };

        jvf.wrappers.users.${cfg.username}.programs.k9s = {
          packages = [
            cfg.package
          ];
          configs = {
            "config.yaml" = {
              k9s = cfg.settings;
            };
            "aliases.yaml" = {
              inherit (cfg) aliases;
            };
            "skins/tokyonight.yaml" = {
              k9s = cfg.skins.tokyonight;
            };
            "clusters/ze-homelab/ze-homelab/config.yaml" = {
              k9s = clusters.homelab;
            };
            "clusters/agrosmart-eks/agrosmart-eks/config.yaml" = {
              k9s = clusters.agrosmartEks;
            };
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-k9s = k9sModule;
  flake.modules.darwin.programs-k9s = k9sModule;
}
