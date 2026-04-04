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

      # Build merged config directory via symlinkJoin
      configDir = pkgs.symlinkJoin {
        name = "k9s-config";
        paths = [
          (pkgs.writeTextDir "config.yaml" (
            (pkgs.formats.yaml { }).generate "config.yaml" { k9s = cfg.settings; }
          ))
          (pkgs.writeTextDir "aliases.yaml" (
            (pkgs.formats.yaml { }).generate "aliases.yaml" { aliases = cfg.aliases; }
          ))
          (pkgs.runCommand "k9s-skins" { } ''
            mkdir -p $out/skins
            cp ${
              pkgs.writeTextDir "tokyonight.yaml" (
                (pkgs.formats.yaml { }).generate "tokyonight.yaml" { k9s = cfg.skins.tokyonight; }
              )
            }/tokyonight.yaml $out/skins/tokyonight.yaml
          '')
          (pkgs.runCommand "k9s-clusters" { } ''
            mkdir -p $out/clusters/ze-homelab/ze-homelab
            mkdir -p $out/clusters/agrosmart-eks/agrosmart-eks
            cp ${
              pkgs.writeTextDir "homelab-config.yaml" (
                (pkgs.formats.yaml { }).generate "config.yaml" { k9s = clusters.homelab; }
              )
            }/homelab-config.yaml $out/clusters/ze-homelab/ze-homelab/config.yaml
            cp ${
              pkgs.writeTextDir "eks-config.yaml" (
                (pkgs.formats.yaml { }).generate "config.yaml" { k9s = clusters.agrosmartEks; }
              )
            }/eks-config.yaml $out/clusters/agrosmart-eks/agrosmart-eks/config.yaml
          '')
        ];
      };
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
