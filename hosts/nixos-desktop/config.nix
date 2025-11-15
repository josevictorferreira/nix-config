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
  # === IMPORTS ===
  # System modules - Phase 1 & 2 of refactoring
  imports = [
    # Core system modules
    "${self}/modules/system/nix-daemon.nix"
    "${self}/modules/system/nixpkgs.nix"
    "${self}/modules/system/networking.nix"
    "${self}/modules/system/locale.nix"
    "${self}/modules/system/base-programs.nix"
    "${self}/modules/system/base-services.nix"
    "${self}/modules/system/audio.nix"
    "${self}/modules/system/logind.nix"
    "${self}/modules/system/security.nix"
    "${self}/modules/system/environment.nix"
    "${self}/modules/system/xdg.nix"
    "${self}/modules/system/firewall.nix"
    "${self}/modules/system/flatpak.nix"
    "${self}/modules/system/power-management.nix"

    # Services
    "${self}/modules/services/sops.nix"
    "${self}/modules/services/polkit.nix"
    "${self}/modules/services/ollama.nix"
    "${self}/modules/services/virtualization.nix"

    # Hardware
    "${self}/modules/hardware/bluetooth.nix"
    "${self}/modules/hardware/logitech.nix"

    # Roles (all role modules)
    "${self}/modules/roles"

    # Desktop environment
    "${self}/modules/desktop/hyprland"

    # Machine-specific hardware configuration
    ./hardware.nix
  ];

  # === HOST-SPECIFIC CONFIGURATION ===
  # Only truly host-specific settings should remain here
  networking.hostName = host;

  # User configuration (remains here as it's user-specific)
  users.users."${username}" = {
    homeMode = "755";
    isNormalUser = true;
    description = gitUsername;
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

  users = {
    mutableUsers = true;
  };

  # Desktop/X11 configuration (host-specific graphics setup)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = username;
        command = "hyprland";
      };
    };
  };

  services.xserver = {
    enable = true;
    xkb.options = "repeat:delay=250,rate=40";
    xkb = {
      layout = keyboardLayout;
      variant = "";
    };
  };

  console.useXkbConfig = true;

  # System shell configuration
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];

  # === MODULE ACTIVATIONS ===
  # All system modules (Phase 1 & 2)
  jvf.system = {
    nix-daemon.enable = true;
    nixpkgs.enable = true;
    networking.enable = true;
    locale.enable = true;
    base-programs.enable = true;
    base-services.enable = true;
    audio.enable = true;
    security.enable = true;
    logind.enable = true;
    environment.enable = true;
    xdg.enable = true;
    firewall.enable = true;
    flatpak.enable = true;
    power-management.enable = true;
  };

  # Services
  jvf.services = {
    sops.enable = true;
    polkit.enable = true;
    ollama.enable = true;
    virtualization.enable = true;
  };

  # Hardware
  jvf.hardware = {
    bluetooth.enable = true;
    logitech.enable = true;
  };

  # Desktop
  jvf.desktop.hyprland.enable = true;

  # === ROLE ACTIVATIONS ===
  # Based on current roles configuration
  jvf.roles = {
    development.enable = true;
    aiDevelopment.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
    designing.enable = true;
    media.enable = true;
    gaming.enable = true;
    networkStorage.enable = true;
  };

  # === MINIMAL SYSTEM PACKAGES ===
  # Only core system utilities remain
  environment.systemPackages = with pkgs; [
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
  ];

  system.stateVersion = "24.05";
}
