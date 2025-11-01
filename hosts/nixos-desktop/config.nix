{
  pkgs,
  lib,
  host,
  options,
  configRoot,
  username,
  ...
}:
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
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
      ];
      packages = [ ];
    };

    defaultUserShell = pkgs.zsh;
  };

  imports = [
    "${configRoot}/modules/security/sops.nix"
    "${configRoot}/modules/security/polkit.nix"
    "${configRoot}/modules/hardware/local-hardware-clock.nix"
    "${configRoot}/modules/hardware/hp-1020-drivers.nix"
    "${configRoot}/modules/roles"
    "${configRoot}/modules/desktop/hyprland"
    ./hardware.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
        ];
    };
  };

  # Extra Module Options
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
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
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
      cpufrequtils
      duf
      glib # for gsettings to work
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

      brave

      # System Tools
      gparted
      p7zip

      # Gaming
      lutris
      # protonup
      protonup-qt
      wine64
      winetricks
      wine-wayland

      # Containers
      gcc
      gnumake
      podman
      podman-compose

      ntfs3g
    ];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
    };
  };

  # Services to start
  services = {
    greetd = {
      enable = true;
      settings = {
        default_session = {
          user = username;
          command = "hyprland";
        };
      };
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
      packages = [ ];
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
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  xdg = {
    mime = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "application/x-pdf" = "org.pwmt.zathura.desktop";
        "application/epub+zip" = "org.koreader.koreader.desktop";
        "application/x-mobipocket-ebook" = "org.koreader.koreader.desktop";
        "application/x-chrome-extension" = "org.chromium.Chromium.desktop";
        "application/x-xpinstall" = "org.chromium.Chromium.desktop";
        "inode/directory" = "thunar.desktop";
        "text/plain" = "org.xfce.mousepad.desktop";
        "text/csv" = "calc.desktop";
        "application/octet-stream" = "vlc.desktop";
      };
    };
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

  services.logind = {
    settings.Login = {
      HandleLidSwitch = "lock";
      HandleSuspendKey = "lock";
      HandleHibernateKey = "lock";
    };
  };

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    loadModels = [
      "dolphin-mixtral:8x7b"
      "goekdenizguelmez/JOSIEFIED-Qwen3:14b"
    ];
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    polkit.extraConfig = ''
       polkit.addRule(function(action, subject) {
         if (
           subject.isInGroup("users")
             && (
               action.id == "org.freedesktop.login1.reboot" ||
               action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
               action.id == "org.freedesktop.login1.power-off" ||
               action.id == "org.freedesktop.login1.power-off-multiple-sessions"
             )
           )
         {
           return polkit.Result.YES;
         }
      })
    '';
  };
  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  console.keyMap = "${keyboardLayout}";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8000 ];
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  system.activationScripts = { };
  system.stateVersion = "24.05";

  jvf.roles = {
    networkStorage.enable = true;
    development.enable = true;
    aiDevelopment.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
    designing.enable = true;
    media.enable = true;
  };

  jvf.desktop.hyprland.enable = true;
}
