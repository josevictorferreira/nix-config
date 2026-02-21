{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.system.display;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.display = {
    enable = lib.mkEnableOption "display variables configuration" // {
      description = ''
        Whether to enable display variables configuration.
      '';
    };

    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Keyboard layout for the system.";
    };
  };

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
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
      { }
  );
}
