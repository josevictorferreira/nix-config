{ ... }:

{
  jvf.core = {
    username = "josevictorferreira";
    host = "macos-macbook";
    os = "macos";
  };

  system.primaryUser = "josevictorferreira";

  jvf.programs = {
    zsh.enable = true;
    starship.enable = true;
  };

  jvf.users.josevictorferreira = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAXdWHFx9UwUOXlapiVD0mzM0KL9VsMlblMAc46D9PV josevictor@josevictor-nixos"
    ];
  };

  system.stateVersion = 4;

  jvf.roles = {
    networkStorage.enable = true;
    development.enable = true;
    ai-development.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
  };
}
