# Machine-specific hardware configuration
{ config
, lib
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Hardware-specific kernel modules detected by nixos-generate-config
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];

  # Machine-specific filesystems (partlabels/UUIDs)
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

  fileSystems."/home/${config.jvf.core.username}/Downloads" = {
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
    "d /home/${config.jvf.core.username}/Downloads 0755 ${config.jvf.core.username} users -"
  ];

  swapDevices = [{ device = "/dev/disk/by-partlabel/swap"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
