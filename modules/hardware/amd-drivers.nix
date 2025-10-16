{ lib
, pkgs
, config
, ...
}:
with lib;
let
  cfg = config.drivers.amdgpu;
in
{
  options.drivers.amdgpu = {
    enable = mkEnableOption "Enable AMD Drivers";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" ];

    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];
    hardware.cpu.amd.updateMicrocode = true;

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libva
        libva-utils
        rocmPackages.clr.icd
        rocmPackages.clr
        rocmPackages.rocminfo
        rocmPackages.rocm-runtime
      ];
      enable32Bit = true;
    };
  };
}
