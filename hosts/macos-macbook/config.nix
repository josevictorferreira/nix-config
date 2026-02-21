{
  pkgs,
  username,
  host,
  os,
  ...
}:

{
  # Core identity (transitional: fed from specialArgs, consumed by modules via config)
  jvf.core = {
    inherit username host os;
  };

  networking.computerName = "${host}";
  networking.localHostName = "${host}";

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';

  security.pam.services.sudo_local.enable = true; # manage the file
  security.pam.services.sudo_local.reattach = true; # install pam_reattach
  security.pam.services.sudo_local.touchIdAuth = true; # install pam_tid

  system.primaryUser = username;

  # system.defaults and system.keyboard provided by darwin-defaults aspect

  environment.systemPackages = with pkgs; [
    m-cli
    mas
    pam-reattach
  ];

  jvf.programs = {
    zsh.enable = true;
    starship.enable = true;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    jetbrains-mono
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.droid-sans-mono
  ];

  jvf.users.${username} = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAXdWHFx9UwUOXlapiVD0mzM0KL9VsMlblMAc46D9PV josevictor@josevictor-nixos"
    ];
  };
  system.stateVersion = 4;

  jvf.system = {
    hostName = host;
    modules = [
      "nixpkgs"
      "nix-daemon"
      "security"
    ];
  };

  jvf.roles.active = [
    "networkStorage"
    "development"
    "aiDevelopment"
    "opsDevelopment"
    "monitoring"
    "communication"
  ];
}
