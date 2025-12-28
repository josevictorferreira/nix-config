{ config
, lib
, pkgs
, system
, username
, ...
}:

let
  cfg = config.jvf.hardware.amd-gpu;
  isDarwin = builtins.match ".*-darwin" system != null;
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

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {
        users.users.${username}.extraGroups = [ "corectrl" ];
        programs.corectrl.enable = true;
        environment.systemPackages = [
          pkgs.corectrl
        ]
        ++ lib.optionals cfg.enableRocm [
          pkgs.rocmPackages.clr.icd
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.rocminfo
          pkgs.rocmPackages.rocm-runtime
          pkgs.rocmPackages.rocm-smi
        ];

        boot.initrd.kernelModules = [ "amdgpu" ];
        boot.kernelParams = [
          "amdgpu.ppfeaturemask=0xffffffff"
          "amdgpu.lockup_timeout=10000"
          "amdgpu.gpu_recovery=1"
        ];

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
              rocmPackages.rocm-smi
            ]
            ++ cfg.extraPackages;
        };

        systemd.tmpfiles.rules = lib.optionals cfg.enableRocm [
          "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
        ];

        hardware.cpu.amd.updateMicrocode = true;
      }
    else
      { }
  );
}
