{ config, pkgs, host, options, configRoot, username, ... }:
let

  inherit (import ./variables.nix) gitUsername keyboardLayout;
in
{
  users = {
    users."${username}" = {
      homeMode = "755";
      isNormalUser = true;
      description = "${gitUsername}";
      extraGroups = [
        "networkmanager"
        "wheel"
        "libvirtd"
        "scanner"
        "lp"
        "video"
        "input"
        "audio"
      ];
      packages = [ ]; # Packages handled by Home Manager
    };

    defaultUserShell = pkgs.zsh;
  };

  imports = [
    "${configRoot}/modules/security/sops.nix"
    "${configRoot}/modules/security/polkit.nix"
    "${configRoot}/modules/hardware/amd-drivers.nix"
    "${configRoot}/modules/hardware/nvidia-drivers.nix"
    "${configRoot}/modules/hardware/nvidia-prime-drivers.nix"
    "${configRoot}/modules/hardware/intel-drivers.nix"
    "${configRoot}/modules/hardware/vm-guest-services.nix"
    "${configRoot}/modules/hardware/local-hardware-clock.nix"
    "${configRoot}/modules/hardware/hp-1020-drivers.nix"
    "${configRoot}/modules/hardware/shared-storage.nix"
    ./hardware.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # BOOT related stuff
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Kernel

    kernelParams = [
      "systemd.mask=systemd-vconsole-setup.service"
      "systemd.mask=dev-tpmrm0.device" #this is to mask that stupid 1.5 mins systemd bug
      "nowatchdog"
      "modprobe.blacklist=sp5100_tco" #watchdog for AMD
      "modprobe.blacklist=iTCO_wdt" #watchdog for Intel
    ];

    # This is for OBS Virtual Cam Support
    kernelModules = [ "v4l2loopback" "i2c-dev" "i2c-piix4" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
    };

    # Needed For Some Steam Games
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };

    ## BOOT LOADERS: NOT USE ONLY 1. either systemd or grub  
    # Bootloader SystemD
    loader.systemd-boot.enable = false;

    loader.efi = {
      #efiSysMountPoint = "/efi"; #this is if you have separate /efi partition
      canTouchEfiVariables = true;
    };

    loader.timeout = 1;

    # Bootloader GRUB
    loader.grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      gfxmodeBios = "auto";
      memtest86.enable = true;
      extraGrubInstallArgs = [ "--bootloader-id=${host}" ];
      configurationName = "${host}";
      useOSProber = true;
    };

    # Bootloader GRUB theme, configure below

    ## -end of BOOTLOADERS----- ##

    # Make /tmp a tmpfs
    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
    };

    # Appimage Support
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = true;
      registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        recognitionType = "magic";
        offset = 0;
        mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
        magicOrExtension = ''\x7fELF....AI\x02'';
      };
    };

    plymouth.enable = true;
  };

  # GRUB Bootloader theme. Of course you need to enable GRUB above.. duh!
  distro-grub-themes = {
    enable = true;
    theme = "nixos";
  };


  # Extra Module Options
  drivers.amdgpu.enable = true;
  drivers.intel.enable = false;
  drivers.nvidia.enable = false;
  drivers.nvidia-prime = {
    enable = false;
    intelBusID = "";
    nvidiaBusID = "";
  };
  vm.guest-services.enable = false;
  local.hardware-clock.enable = false;

  # networking
  networking.networkmanager.enable = true;
  networking.hostName = "${host}";
  networking.timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = options.programs.nix-ld.libraries.default;
    };

    zsh.enable = true;
    firefox.enable = true;
    git.enable = true;
    nm-applet.indicator = true;

    thunar.enable = true;
    thunar.plugins = with pkgs.xfce; [
      exo
      mousepad
      thunar-archive-plugin
      thunar-volman
      tumbler
    ];

    virt-manager.enable = false;

    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  users = {
    mutableUsers = true;
  };

  environment = {
    shells = with pkgs; [ zsh ];
    systemPackages = with pkgs; [
      # System Packages
      baobab
      btrfs-progs
      clang
      cpufrequtils
      duf
      glib #for gsettings to work
      gsettings-qt
      killall
      libappindicator
      libnotify
      pciutils
      xdg-user-dirs
      xdg-utils

      nfs-utils

      (mpv.override { scripts = [ mpvScripts.mpris ]; }) # with tray

      samba
      sambaFull
      gvfs
      hplip

      # System Tools
      gparted
      p7zip

      # Gaming
      lutris
      protonup
      wine64
      winetricks
      wine-wayland

      # Containers
      podman
      buildah
      qemu
      qemu_kvm

      # LLM
      ollama
    ];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    };
  };

  # Services to start
  services = {
    greetd = {
      enable = true;
      vt = 3;
      settings = {
        default_session = {
          user = username;
          command = "Hyprland";
        };
      };
    };

    ollama = {
      enable = false;
      loadModels = [ ];
      host = "0.0.0.0";
      port = 11434;
    };

    pulseaudio.enable = false;

    xserver = {
      enable = true;
      xkb.options = "repeat:delay=250,rate=40";
      xkb = {
        layout = "${keyboardLayout}";
        variant = "";
      };
    };

    lorri = {
      enable = true;
    };

    smartd = {
      enable = false;
      autodetect = true;
    };

    gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };
    tumbler.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    udev = {
      enable = true;
      packages = [ pkgs.openrgb-with-all-plugins ];
    };

    envfs.enable = true;
    dbus.enable = true;

    fstrim = {
      enable = true;
      interval = "weekly";
    };

    libinput.enable = true;

    rpcbind.enable = true;

    nfs.server.enable = false;

    openssh.enable = true;
    flatpak.enable = false;

    blueman.enable = true;

    hardware.openrgb.enable = true;
    hardware.openrgb.motherboard = "amd";

    fwupd.enable = true;

    upower.enable = true;

    gnome.gnome-keyring.enable = true;
  };

  systemd.services.flatpak-repo = {
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # zram
  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 30;
    swapDevices = 1;
    algorithm = "zstd";
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  # Extra Logitech Support
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = false;

  # Bluetooth
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
  };

  # Cachix, Optimization settings and garbage collection automation
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = false;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal
      ];
    };
  };

  security = {
    pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
    sudo.extraConfig = ''
      Defaults pwfeedback
    '';
  };

  # OpenGL
  hardware.graphics = {
    enable = true;
  };

  console.keyMap = "${keyboardLayout}";

  # For Electron apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  networking.firewall = {
    enable = true;
    # Ollama port
    allowedTCPPorts = [ 11434 57621 ];
    allowedUDPPorts = [ 5353 ];
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  system.activationScripts = { };
  system.stateVersion = "24.05";
}
