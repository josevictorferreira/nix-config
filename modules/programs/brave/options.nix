{ lib, config, ... }:
{
  options.jvf.programs.brave = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install Brave";
    };
  };
}
