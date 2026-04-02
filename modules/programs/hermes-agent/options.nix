# Options for jvf.programs.hermes-agent
# Note: No enable option - module is active by inclusion (import = active)
{ lib, ... }:
{
  options.jvf.programs.hermes-agent = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Username for hermes-agent configuration";
    };
  };
}
