# Aspect: system-display
# Defines jvf.system.display options and platform-specific display config.
# NixOS: XServer keyboard layout + console config.
# Darwin: empty config (display managed by macOS).
_:
let
  mkDisplayOptions =
    { lib, ... }:
    {
      options.jvf.system.display = {
        keyboardLayout = lib.mkOption {
          type = lib.types.str;
          default = "us";
          description = "Keyboard layout for the system.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, ... }:
    let
      cfg = config.jvf.system.display;
    in
    {
      imports = [ mkDisplayOptions ];

      config = if (!isDarwin) then
          {
            services.xserver = {
              enable = true;
              xkb.options = "repeat:delay=250,rate=40";
              xkb = {
                layout = cfg.keyboardLayout;
                variant = "";
              };
            };

            console.useXkbConfig = true;
          }
        else
          { };
    };
in
{
  flake.modules.nixos.system-display = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-display = mkConfig { isDarwin = true; };
}
