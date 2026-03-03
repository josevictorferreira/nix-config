# k9s options definitions
{ config
, lib
, pkgs
, ...
}:

{
  options.jvf.programs.k9s = {
    package = lib.mkPackageOption pkgs "k9s" { };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install the configuration";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = lib.mdDoc "Configuration for k9s, written to config.yaml.";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = lib.mdDoc "Short name aliases for Kubernetes resources.";
    };

    skins = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = lib.mdDoc "Theme/skin definitions for k9s.";
    };
  };
}
