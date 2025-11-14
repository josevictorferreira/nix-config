{
  # === System Configuration Modules ===
  nix-daemon = ./nix-daemon.nix;
  nixpkgs = ./nixpkgs.nix;
  networking = ./networking.nix;
  locale = ./locale.nix;
  base-programs = ./base-programs.nix;
  base-services = ./base-services.nix;
  audio = ./audio.nix;
  security = ./security.nix;
  environment = ./environment.nix;
  xdg = ./xdg.nix;
  firewall = ./firewall.nix;
  logind = ./logind.nix;
  flatpak = ./flatpak.nix;
  power-management = ./power-management.nix;
}
