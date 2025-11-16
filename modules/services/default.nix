# === Services Configuration Module ===
# Centralized module that imports and manages all service modules
#
# Usage in host config:
#   jvf.services = {
#     active = [ "sops" "virtualization" "ollama" ... ];
#   };
#
# This module will:
# 1. Import all child service modules
# 2. Set enable = true for each service listed in the 'active' array
#
# Available services:
# - cephfs - CephFS distributed filesystem
# - ollama - Local AI model server
# - polkit - PolicyKit authentication framework
# - smb - SMB/CIFS file sharing
# - sops - Secret management with age encryption
# - virtualization - libvirtd and podman with Docker compatibility

{ config, lib, username, system, ... }:
let
  availableServices = {
    cephfs = ./cephfs.nix;
    ollama = ./ollama.nix;
    polkit = ./polkit.nix;
    smb = ./smb.nix;
    sops = ./sops.nix;
    virtualization = ./virtualization.nix;
  };

  isServiceEnabled = name: builtins.elem name config.jvf.services.active;

  mkServiceEnables = lib.mkMerge (
    map (
      name:
      lib.mkIf (isServiceEnabled name) {
        ${name} = {
          enable = true;
          inherit username;
        }
        // lib.optionalAttrs (name == "virtualization") {
          inherit system;
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
        "sops"
        "virtualization"
        "ollama"
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
