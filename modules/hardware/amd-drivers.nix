{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.drivers.amdgpu;
in
{
  options.drivers.amdgpu = {
    enable = mkEnableOption "Enable AMD Drivers";
  };

  config = mkIf cfg.enable {
    # systemd.tmpfiles.rules = [ "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" ];
    #
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "amdgpu" ];
    hardware.cpu.amd.updateMicrocode = true;

    environment.variables = {
      ROC_ENABLE_PRE_VEGA = "1";
    };

    hardware.opengl = {
     enable = true;
     driSupport32Bit = true;
     extraPackages = with pkgs; [
        rocmPackages.clr.icd
        rocmPackages.clr
        rocmPackages.rocminfo
        rocmPackages.rocm-runtime
     ];
    };
    #
    # hardware.graphics = {
    #   enable = true;
    #   extraPackages = with pkgs; [
    #     amdvlk
    #     libva
    #     libva-utils
    #   ];
    #   enable32Bit = true;
    #   extraPackages32 = with pkgs; [
    #     driversi686Linux.amdvlk
    #   ];
    # };
  };
}
