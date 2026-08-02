# Aspect: programs-brave
# Installs Brave browser with Ozone/Wayland flags for better Hyprland integration.
# Fixes clipboard issues by forcing the Wayland backend.
#
# nixpkgs exposes brave as `(callPackage ./brave {}).brave`, so the derivation has
# no `override`. Extra flags go through wrapGAppsHook's `gappsWrapperArgs` instead.
# Upstream already adds --ozone-platform-hint=auto, WaylandWindowDecorations and
# --enable-wayland-ime when NIXOS_OZONE_WL + WAYLAND_DISPLAY are set (see
# jvf.system.environment.nixosOzoneWl), so only the hard platform force is left here.
_:
let
  braveModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.brave;
      # Force Wayland and Ozone flags for Brave on Linux
      braveWrapped =
        if pkgs.stdenv.isDarwin then
          pkgs.brave
        else
          pkgs.brave.overrideAttrs (old: {
            preFixup = old.preFixup + ''
              gappsWrapperArgs+=(--add-flags "--ozone-platform=wayland")
            '';
          });
    in
    {
      imports = [ ./options.nix ];

      config = {
        users.users."${cfg.username}".packages = [ braveWrapped ];
      };
    };
in
{
  flake.modules.nixos.programs-brave = braveModule;
  flake.modules.darwin.programs-brave = braveModule;
}
