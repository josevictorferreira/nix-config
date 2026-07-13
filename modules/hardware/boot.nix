# Aspect: hardware-boot
# Boot configuration: kernel, grub, plymouth, binfmt, sysctl, firmware.
# NixOS-only (no Darwin equivalent).
_:
let
  mkBootOptions =
    { lib, ... }:
    {
      options.jvf.hardware.boot = {
        kernel = lib.mkOption {
          type = lib.types.enum [
            "zen"
            "latest"
            "lts"
          ];
          default = "zen";
          description = "Kernel variant to use.";
        };

        kernelModules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "kvm-amd" ];
          description = "Additional kernel modules to load.";
        };

        grub = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable GRUB bootloader.";
          };
          configurationLimit = lib.mkOption {
            type = lib.types.int;
            default = 10;
            description = "Number of boot entries to keep.";
          };
          useOSProber = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable os-prober for detecting other OSes.";
          };
        };

        plymouth = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Plymouth boot splash.";
          };
          theme = lib.mkOption {
            type = lib.types.str;
            default = "bgrt";
            description = "Plymouth theme to use.";
          };
        };

        binfmt = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable binfmt for appimage support.";
          };
          emulatedSystems = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "aarch64-linux" ];
            description = "Systems to emulate via binfmt (QEMU), enabling cross-building images (e.g. arm64).";
          };
        };

        firmware = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable redistributable firmware and linux-firmware package.";
          };
        };

        i2c = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable I2C hardware support.";
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
      cfg = config.jvf.hardware.boot;
      kernelPackages =
        if cfg.kernel == "zen" then
          pkgs.linuxPackages_zen
        else if cfg.kernel == "latest" then
          pkgs.linuxPackages_latest
        else
          pkgs.linuxPackages;
    in
    {
      imports = [ mkBootOptions ];

      config = {
        boot = {
          inherit (cfg) kernelModules;
          extraModulePackages = [ ];
          inherit kernelPackages;

          kernelParams = [
            "quiet"
            "loglevel=3"
            "systemd.show_status=auto"
            "udev.log_level=3"
            "rd.udev.log_level=3"
            "vt.global_cursor_default=0"
            "boot.shell_on_fail"
            "plymouth.use-simpledrm"
          ];

          initrd.verbose = false;

          kernel.sysctl = {
            "vm.max_map_count" = 2147483642;
          };

          loader = {
            systemd-boot.enable = false;
            efi.canTouchEfiVariables = true;
            timeout = 1;

            grub = lib.mkIf cfg.grub.enable {
              enable = true;
              device = "nodev";
              efiSupport = true;
              gfxmodeBios = lib.mkDefault "auto";
              memtest86.enable = true;
              inherit (cfg.grub) configurationLimit;
              inherit (cfg.grub) useOSProber;
            };
          };

          tmp = {
            useTmpfs = false;
            tmpfsSize = "30%";
          };

          binfmt.emulatedSystems = cfg.binfmt.emulatedSystems;

          binfmt.registrations = lib.mkIf cfg.binfmt.enable {
            appimage = {
              wrapInterpreterInShell = false;
              interpreter = "${pkgs.appimage-run}/bin/appimage-run";
              recognitionType = "magic";
              offset = 0;
              mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
              magicOrExtension = ''\x7fELF....AI\x02'';
            };
          };

          consoleLogLevel = 0;

          plymouth = lib.mkIf cfg.plymouth.enable {
            enable = true;
            inherit (cfg.plymouth) theme;
          };
        };

        console.earlySetup = false;

        hardware = {
          enableRedistributableFirmware = cfg.firmware.enable;
          firmware = lib.mkIf cfg.firmware.enable [ pkgs.linux-firmware ];
          i2c.enable = cfg.i2c.enable;
        };
      };
    };
in
{
  flake.modules.nixos.hardware-boot = mkConfig;
}
