{
  pkgs,
  lib,
  host,
  options,
  inputs,
  username,
  ...
}:
let
  inherit (inputs) self;
in
let

  inherit (import ./variables.nix) gitUsername keyboardLayout;
in
{
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

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
    "${self}/modules/services/sops.nix"
    "${self}/modules/services/polkit.nix"
    "${self}/modules/services/ollama.nix"
    "${self}/modules/services/virtualisation.nix"
    "${self}/modules/system/power-management.nix"
    "${self}/modules/hardware/bluetooth.nix"
    "${self}/modules/hardware/logitech.nix"
    "${self}/modules/roles"
    "${self}/modules/desktop/hyprland"
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

    nm-applet.indicator = true;

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
      btrfs-progs
      cpufrequtils
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

      # Containers
      gcc
      gnumake
      podman
      podman-compose

      ntfs3g
    ];
    variables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
      XDG_CONFIG_HOME = "$HOME/.config";
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

  console.useXkbConfig = true;

  environment.variables.NIXOS_OZONE_WL = "1";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8000 ];
  };

  system.activationScripts = { };
  system.stateVersion = "24.05";

  jvf.services = {
    sops.enable = true;
    polkit.enable = true;
  };

  jvf.system.power-management.enable = true;
  jvf.hardware.bluetooth.enable = true;
  jvf.hardware.logitech.enable = true;

  jvf.desktop.hyprland.enable = true;

  jvf.roles = {
    networkStorage.enable = true;
    development.enable = true;
    aiDevelopment.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
    designing.enable = true;
    media.enable = true;
    gaming.enable = true;
  };
}
