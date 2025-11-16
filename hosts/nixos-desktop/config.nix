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

    # Services
    "${self}/modules/services/sops.nix"
    "${self}/modules/services/polkit.nix"
    "${self}/modules/services/ollama.nix"
    "${self}/modules/services/virtualization.nix"

    # Hardware
    "${self}/modules/hardware/bluetooth.nix"
    "${self}/modules/hardware/logitech.nix"

    # Desktop environment
    "${self}/modules/desktop/hyprland"

    # Machine-specific hardware configuration
    ./hardware.nix
  ];

  jvf.users.${username} = {
    enable = true;
    description = gitUsername;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
    ];
  };

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

  # Services
  jvf.services = {
    sops.enable = true;
    polkit.enable = true;
    ollama.enable = true;
  };

  # Hardware
  jvf.hardware = {
    bluetooth.enable = true;
    logitech.enable = true;
  };

  # Desktop
  jvf.desktop.hyprland.enable = true;

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
