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
  jvf.system.networking.hostName = host;

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

  jvf.hardware.active = [
    "amd-gpu"
    "bluetooth"
    "logitech"
  ];

  # Role
  jvf.roles.active = [
    "development"
    "aiDevelopment"
    "localAi"
    "webDevelopment"
    "aiDevelopment"
    "opsDevelopment"
    "monitoring"
    "communication"
    "designing"
    "media"
    "gaming"
    "networkStorage"
    "documenting"
    "privacy"
  ];

  system.stateVersion = "24.05";
}
