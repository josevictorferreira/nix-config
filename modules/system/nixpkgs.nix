{
  config,
  lib,
  system,
  ...
}:

let
  cfg = config.jvf.system.nixpkgs;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs unfree configuration" // {
      description = ''
        Whether to enable nixpkgs configuration for unfree packages.
        Allows installation of proprietary software like Steam.
      '';
    };

    allowUnfree = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow installation of unfree packages.";
    };

    allowedUnfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
      description = "List of unfree packages to allow by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs = {
      config = {
        allowUnfree = cfg.allowUnfree;
        allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedUnfreePackages;
      };
    };
  };
}
