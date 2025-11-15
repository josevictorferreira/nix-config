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
    "${self}/modules/users"
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
    "${self}/modules/system/display.nix"

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
    networking = {
      enable = true;
      hostName = host;
    };
    nix-daemon.enable = true;
    nixpkgs.enable = true;
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
    display.enable = true;
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

  system.stateVersion = "24.05";
}
