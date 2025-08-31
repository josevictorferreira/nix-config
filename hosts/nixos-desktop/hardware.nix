{ pkgs, lib, modulesPath, configRoot, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      "${configRoot}/modules/hardware/amd-drivers.nix"
    ];

  drivers.amdgpu.enable = true;

  boot = {
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "btrfs" ];
    # kernelPackages = pkgs.linuxPackages_latest; # Kernel
    kernelPackages = pkgs.linuxPackages_6_12;

    kernelParams = [
      "systemd.mask=systemd-vconsole-setup.service"
      "systemd.mask=dev-tpmrm0.device" #this is to mask that stupid 1.5 mins systemd bug
      "nowatchdog"
      "modprobe.blacklist=sp5100_tco" #watchdog for AMD
      "modprobe.blacklist=iTCO_wdt" #watchdog for Intel
    ];

    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "btrfs" ];
      kernelModules = [ "amdgpu" ];
    };

    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };

    loader = {
      systemd-boot.enable = false;

      efi.canTouchEfiVariables = true;

      timeout = 1;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        gfxmodeBios = "auto";
        memtest86.enable = true;
        configurationLimit = 10;
        useOSProber = true;
      };
    };

    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
    };

    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };

    plymouth.enable = true;
  };

  services.btrfs.autoScrub = { enable = true; interval = "monthly"; fileSystems = [ "/" ]; };

  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
      neededForBoot = true;
    };

  fileSystems."/" =
    {
      device = "/dev/disk/by-partlabel/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@root" "compress=zstd:3" "noatime" ];
      neededForBoot = true;
    };

  fileSystems."/nix"  =
    {
      device = "/dev/disk/by-partlabel/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd:3" "noatime" ];
      depends = [ "/" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-partlabel/nixos-root";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd:5" "noatime" "autodefrag" ];
      depends = [ "/" ];
      neededForBoot = false;
    };

  fileSystems."/mnt/external_storage" = {
    device = "/dev/disk/by-partlabel/file-storage";
    fsType = "btrfs";
    options = [ "defaults" "noatime" "compress=zstd" "noatime" "autodefrag" ];
    depends = [ "/" ];
    neededForBoot = false;
  };

  swapDevices =
    [{ device = "/dev/disk/by-partlabel/swap"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.i2c.enable = true;
}
