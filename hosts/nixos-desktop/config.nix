{
  host,
  username,
  os,
  ...
}:
let
  inherit (import ./variables.nix) gitUsername;
in
{
  imports = [
    ./hardware.nix
  ];

  # Core identity (transitional: fed from specialArgs, consumed by modules via config)
  jvf.core = {
    inherit username host os;
  };

  # User configuration
  jvf.users.${username} = {
    enable = true;
    description = gitUsername;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
    ];
  };

  # Desktop
  jvf.desktop.hyprland.enable = true;

  # === MODULE ACTIVATIONS ===
  # All system modules are now enabled via dendritic aspects in modules/hosts/nixos-desktop.nix
  jvf.system.networking = {
    enable = true;
    hostName = host;
  };

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

  # Static IP configuration
  networking.interfaces.enp4s0.ipv4.addresses = [
    {
      address = "10.10.10.10";
      prefixLength = 24;
    }
  ];
  networking.interfaces.enp4s0.useDHCP = false;
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.100" ];

  # Hardware aspects (Phase 6 - enabled via dendritic aspects in nixos-desktop.nix)
  jvf.hardware = {
    amd-gpu.enable = true;
    bluetooth.enable = true;
    logitech.enable = true;
    openrgb.enable = true;
  };

  # Roles (Phase 7 - dendritic: enable directly instead of jvf.roles.active)
  jvf.roles = {
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
