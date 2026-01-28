{ host
, inputs
, username
, ...
}:
let
  inherit (inputs) self;
in
let
  inherit (import ./variables.nix) gitUsername;
in
{
  imports = [
    "${self}/modules/desktop/hyprland"

    ./hardware.nix
  ];

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
  # All system modules (Phase 1 & 2)
  jvf.system = {
    hostName = host;
    modules = [
      "audio"
      "base-programs"
      "base-services"
      "display"
      "environment"
      "firewall"
      "flatpak"
      "locale"
      "logind"
      "networking"
      "nix-daemon"
      "nixpkgs"
      "power-management"
      "security"
      "xdg"
      "virtualization"
    ];

    # XDG user directories (fixes Brave "Open folder" for Downloads)
    xdg.userDirs = {
      DESKTOP = "$HOME/Desktop";
      DOWNLOAD = "$HOME/Downloads";
      DOCUMENTS = "$HOME/Documents";
      MUSIC = "$HOME/Music";
      PICTURES = "$HOME/Pictures";
      VIDEOS = "$HOME/Videos";
      TEMPLATES = "$HOME/Templates";
      PUBLICSHARE = "$HOME/Public";
    };
  };

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
