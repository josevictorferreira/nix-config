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
    description = "Jose Victor Ferreira";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVNsxVT6rzeyqZVlJVdQgKEzK2z0fOFNRZMAvQvBxbX josevictorferreira@macos-macbook"
    ];
  };

  # XDG user directories (host-specific override)
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

  # Static IP configuration (host-specific)
  networking.interfaces.enp4s0.ipv4.addresses = [
    {
      address = "10.10.10.10";
      prefixLength = 24;
    }
  ];
  networking.interfaces.enp4s0.useDHCP = false;
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.100" ];

  system.stateVersion = "24.05";
}
