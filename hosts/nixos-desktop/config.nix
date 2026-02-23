{ ... }:
{
  imports = [
    ./hardware.nix
  ];

  # Core identity - hardcoded per-host
  jvf.core = {
    username = "josevictor";
    host = "nixos-desktop";
    os = "nixos";
  };

  # User configuration
  jvf.users.josevictor = {
    enable = true;
    description = "Jose Victor Ferreira";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
    ];
  };

  # Desktop
  jvf.desktop.hyprland.enable = true;
  jvf.desktop.hyprland.waybar.enable = true;

  # === MODULE ACTIVATIONS ===
  # All system modules are now enabled via dendritic aspects in modules/hosts/nixos-desktop.nix
  jvf.system.locale.enable = true;

  # XDG user directories (fixes Brave "Open folder" for Downloads)
  jvf.system.xdg.userDirs = {
    DESKTOP = "$HOME/Desktop";
    DOWNLOAD = "$HOME/Downloads";
    DOCUMENTS = "$HOME/Documents";
    MUSIC = "$HOME/Music";
    PICTURES = "$HOME/Pictures";
    VIDEOS = "$HOME/Videos";
    TEMPLATES = "$HOME/Templates";
    PUBLICSHARE = "$HOME/Public";
  };

  # Enable dendritic security aspect (replaces legacy "security" module)
  jvf.system.security.enable = true;

  # Enable nixpkgs config (required for allowUnfree to take effect)
  jvf.system.nixpkgs.enable = true;

  # Enable nix-daemon (required for nix-ld dynamic linking support)
  jvf.system.nix-daemon.enable = true;

  # Static IP configuration (kept raw for now - very host-specific)
  networking.interfaces.enp4s0.ipv4.addresses = [
    {
      address = "10.10.10.10";
      prefixLength = 24;
    }
  ];
  networking.interfaces.enp4s0.useDHCP = false;
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.100" ];

  jvf.hardware = {
    boot.enable = true;
    btrfs.enable = true;
    amd-gpu.enable = true;
    bluetooth.enable = true;
    logitech.enable = true;
    openrgb.enable = true;
  };

  jvf.roles = {
    base.enable = true;
    desktop.enable = true;
    development.enable = true;
    ai-development.enable = true;
    local-ai.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
    designing.enable = true;
    media.enable = true;
    gaming.enable = true;
    networkStorage.enable = true;
    documenting.enable = true;
    privacy.enable = true;
  };

  system.stateVersion = "24.05";
}
