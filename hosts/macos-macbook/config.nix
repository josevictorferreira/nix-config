{ ... }:

{
  jvf.core = {
    username = "josevictorferreira";
    host = "macos-macbook";
    os = "macos";
  };

  system.primaryUser = "josevictorferreira";

  jvf.users.josevictorferreira = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAXdWHFx9UwUOXlapiVD0mzM0KL9VsMlblMAc46D9PV josevictor@josevictor-nixos"
    ];
  };

  system.stateVersion = 4;
}
