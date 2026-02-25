# Aspect: hardware-btrfs
# Btrfs filesystem support: autoScrub, btrfs-progs.
# NixOS-only (no Darwin equivalent).
_:
let
  mkBtrfsOptions =
    { lib, ... }:
    {
      options.jvf.hardware.btrfs = {
        autoScrub = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable automatic btrfs scrub.";
          };
          interval = lib.mkOption {
            type = lib.types.str;
            default = "monthly";
            description = "How often to run btrfs scrub.";
          };
          fileSystems = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "/" ];
            description = "Which filesystems to scrub.";
          };
        };
      };
    };

  mkConfig =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.hardware.btrfs;
    in
    {
      imports = [ mkBtrfsOptions ];

      config = {
        boot.supportedFilesystems = [ "btrfs" ];

        environment.systemPackages = [
          pkgs.btrfs-progs
        ];

        services.btrfs.autoScrub = lib.mkIf cfg.autoScrub.enable {
          enable = true;
          inherit (cfg.autoScrub) interval;
          inherit (cfg.autoScrub) fileSystems;
        };
      };
    };
in
{
  flake.modules.nixos.hardware-btrfs = mkConfig;
}
