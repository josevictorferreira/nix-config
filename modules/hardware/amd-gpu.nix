{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jvf.hardware.amd-gpu;
in
{
  options.jvf.hardware.amd-gpu = {
    enable = lib.mkEnableOption "AMD GPU support" // {
      description = ''
        Whether to enable AMD GPU hardware support.
        Configures kernel modules, video drivers, hardware acceleration,
        and ROCm runtime for AMD GPUs.
      '';
    };

    enable32Bit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable 32-bit graphics support.
        Required for gaming and some legacy applications.
      '';
    };

    enableRocm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable ROCm (Radeon Open Compute) runtime.
        Required for GPU compute workloads and AI applications.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional packages to install for GPU support.
      '';
      example = lib.literalExpression "[ pkgs.amdvlk ]";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];

    services.xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = cfg.enable32Bit;
      extraPackages =
        with pkgs;
        [
          libva
          libva-utils
        ]
        ++ lib.optionals cfg.enableRocm [
          rocmPackages.clr.icd
          rocmPackages.clr
          rocmPackages.rocminfo
          rocmPackages.rocm-runtime
        ]
        ++ cfg.extraPackages;
    };

    systemd.tmpfiles.rules = lib.optionals cfg.enableRocm [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    hardware.cpu.amd.updateMicrocode = true;
  };
}
