# === Services Configuration Module ===
# Centralized module that imports and manages all service modules
#
# Usage in host config:
#   jvf.services = {
#     active = [ "smb" "cephFs" ... ];
#   };
#
# This module will:
# 1. Import all child service modules
# 2. Set enable = true for each service listed in the 'active' array
#
# Available services:
# - cephFs - CephFS distributed filesystem
# - smb - SMB/CIFS file sharing

{ config, lib, ... }:
let
  availableServices = {
    cephFs = ./cephfs.nix;
    smb = ./smb.nix;
  };

  isServiceEnabled = name: builtins.elem name config.jvf.services.active;

  mkServiceEnables = lib.mkMerge (
    map (
      name:
      lib.mkIf (isServiceEnabled name) {
        ${name} = {
          enable = true;
        };
      }
    ) (builtins.attrNames availableServices)
  );
in
{
  options.jvf.services = with lib; {
    active = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "smb"
        "cephFs"
      ];
      description = ''
        List of services to enable. Each service will be automatically
        enabled if its name appears in this list. Available services:
        ${lib.generators.toPretty { } (builtins.attrNames availableServices)}
      '';
    };
  };

  imports = builtins.attrValues availableServices;

  config = {
    jvf.services = mkServiceEnables;
  };
}
