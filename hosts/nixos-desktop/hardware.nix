{ pkgs
, username
, lib
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  console = {
    earlySetup = false;
  };

  environment.systemPackages = [
    pkgs.btrfs-progs
  ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_zen;

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

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      verbose = false;
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

    consoleLogLevel = 0;

    plymouth = {
      enable = true;
      theme = "bgrt";
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
    neededForBoot = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixos-root";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd:3"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-partlabel/nixos-root";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd:3"
      "noatime"
    ];
    depends = [ "/" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-partlabel/nixos-root";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:5"
      "noatime"
      "autodefrag"
    ];
    depends = [ "/" ];
    neededForBoot = false;
  };

  fileSystems."/mnt/external_storage" = {
    device = "/dev/disk/by-partlabel/file-storage";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
      "compress=zstd"
      "autodefrag"
      "x-systemd.automount"
      "x-systemd.idle-timeout=380"
      "noauto"
    ];
    depends = [ "/" ];
    neededForBoot = false;
  };

  fileSystems."/home/${username}/Downloads" = {
    device = "/mnt/external_storage/Downloads";
    fsType = "none";
    options = [
      "bind"
      "x-systemd.automount"
      "x-systemd.idle-timeout=380"
      "noauto"
      "nofail"
    ];
    neededForBoot = false;
    depends = [ "/mnt/external_storage/Downloads" ];
  };

  systemd.tmpfiles.rules = [
    "d /home/${username}/Downloads 0755 ${username} users -"
  ];

  swapDevices = [{ device = "/dev/disk/by-partlabel/swap"; }];

  networking.useDHCP = lib.mkDefault true;

  hardware.enableRedistributableFirmware = true;

  hardware.firmware = [
    pkgs.linux-firmware
  ];

  hardware.i2c.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
