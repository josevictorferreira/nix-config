{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.hardware.logitech;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.hardware.logitech = {
    enable = lib.mkEnableOption "Logitech hardware support" // {
      description = ''
        Whether to enable Logitech wireless hardware support.
        Configures Logitech daemon for peripherals (mice, keyboards, etc).
      '';
    };

    enableGraphical = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable Logitech graphical tools.
        Set to true if you want to use Logitech's GUI configuration tools.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {

        hardware.logitech.wireless = {
          enable = true;
          enableGraphical = lib.mkDefault cfg.enableGraphical;
        };
      }
    else
      { }
  );
}
