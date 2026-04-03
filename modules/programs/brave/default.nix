# Aspect: programs-brave
# Installs Brave browser with Ozone/Wayland flags for better Hyprland integration.
# Fixes clipboard issues by forcing the Wayland backend.
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.brave;
      # Force Wayland and Ozone flags for Brave on Linux
      braveWrapped =
        if isDarwin then
          pkgs.brave
        else
          pkgs.brave.override {
            commandLineArgs = [
              "--ozone-platform-hint=auto"
              "--ozone-platform=wayland"
              "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
            ];
          };
    in
    {
      imports = [ ./options.nix ];

      config = {
        users.users."${cfg.username}".packages = [ braveWrapped ];
      };
    };
in
{
  flake.modules.nixos.programs-brave = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-brave = mkConfig { isDarwin = true; };
}
