{
  host,
  inputs,
  username,
  ...
}:
let
  inherit (inputs) self;
in
let
  inherit (import ./variables.nix) gitUsername;
in
{
  imports = [
    # Core modules
    "${self}/modules/users"
    "${self}/modules/system"
    "${self}/modules/roles"
    "${self}/modules/services"
    "${self}/modules/hardware"
    "${self}/modules/desktop/hyprland"

    # Machine-specific hardware configuration
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
    ];
  };

  jvf.services.active = [
    "sops"
    "polkit"
    "ollama"
    "virtualization"
  ];

  jvf.hardware.active = [
    "bluetooth"
    "logitech"
  ];

  # Role
  jvf.roles.active = [
    "development"
    "aiDevelopment"
    "webDevelopment"
    "aiDevelopment"
    "opsDevelopment"
    "monitoring"
    "communication"
    "designing"
    "media"
    "gaming"
    "networkStorage"
  ];

  system.stateVersion = "24.05";
}
