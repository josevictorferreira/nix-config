# Aspect: programs-k9s
# Defines jvf.programs.k9s options and platform-specific k9s terminal UI for Kubernetes.
# NixOS/Darwin: k9s package + config via wrappers + tokyonight skin + homelab config.
let
  # Import default configs as pure data
  defaultSettings = import ./_/settings.nix { };
  clusters = import ./_/clusters.nix { };

  k9sModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.programs.k9s;
      themeSkin = import ./_/skin.nix config.jvf.theme.colors;

      # Build merged config directory via linkFarm
      yamlFmt = pkgs.formats.yaml { };
      configDir = pkgs.linkFarm "k9s-config" [
        {
          name = "config.yaml";
          path = yamlFmt.generate "config.yaml" { k9s = cfg.settings; };
        }
        {
          name = "aliases.yaml";
          path = yamlFmt.generate "aliases.yaml" { aliases = cfg.aliases; };
        }
        {
          name = "skins/tokyonight.yaml";
          path = yamlFmt.generate "tokyonight.yaml" { k9s = cfg.skins.tokyonight; };
        }
        {
          name = "clusters/ze-homelab/ze-homelab/config.yaml";
          path = yamlFmt.generate "homelab-config.yaml" { k9s = clusters.homelab; };
        }
        {
          name = "clusters/agrosmart-eks/agrosmart-eks/config.yaml";
          path = yamlFmt.generate "eks-config.yaml" { k9s = clusters.agrosmartEks; };
        }
      ];
    in
    {
      imports = [ ./options.nix ];

      jvf = {
        programs.k9s = {
          settings = lib.mkDefault defaultSettings.settings;
          aliases = lib.mkDefault defaultSettings.aliases;
          skins = lib.mkDefault {
            tokyonight = themeSkin;
          };
        };
        wrappers.users.${cfg.username}.programs.k9s = {
          packages = [
            cfg.package
          ];
        };
        home.users.${cfg.username}.items = {
          ".config/k9s" = {
            kind = "dir";
            mode = "copy";
            source = configDir;
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-k9s = k9sModule;
  flake.modules.darwin.programs-k9s = k9sModule;
}
