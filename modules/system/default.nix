# === System Configuration Module ===
# Centralized module that imports and manages all system-level modules
#
# Usage in host config:
#   jvf.system = {
#     hostName = "myhost";
#     modules = [ "audio" "security" "networking" "base-programs" ... ];
#   };
#
# This module will:
# 1. Import all child system modules
# 2. Set enable = true for each module listed in the 'modules' array
# 3. Pass hostName through to the networking module

{ config, lib, ... }:
let
  availableModules = {
    audio = ./audio.nix;
    base-programs = ./base-programs.nix;
    base-services = ./base-services.nix;
    display = ./display.nix;
    environment = ./environment.nix;
    firewall = ./firewall.nix;
    flatpak = ./flatpak.nix;
    locale = ./locale.nix;
    logind = ./logind.nix;
    networking = ./networking.nix;
    nix-daemon = ./nix-daemon.nix;
    nixpkgs = ./nixpkgs.nix;
    power-management = ./power-management.nix;
    security = ./security.nix;
    xdg = ./xdg.nix;
  };

  isModuleEnabled = name: builtins.elem name config.jvf.system.modules;

  mkModuleEnables = lib.mkMerge (
    map (
      name:
      lib.mkIf (isModuleEnabled name) {
        ${name} = {
          enable = true;
        }
        // lib.optionalAttrs (name == "networking") {
          hostName = config.jvf.system.hostName;
        };
      }
    ) (builtins.attrNames availableModules)
  );
in
{
  options.jvf.system = with lib; {
    hostName = mkOption {
      type = types.str;
      default = config.networking.hostName or "localhost";
      description = ''
        Hostname for this machine. Will be passed to the networking module
        if it's activated.
      '';
    };

    modules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "audio"
        "security"
        "networking"
        "base-programs"
      ];
      description = ''
        List of system modules to enable. Each module will be automatically
        enabled if its name appears in this list. Available modules:
        ${lib.generators.toPretty { } (builtins.attrNames availableModules)}
      '';
    };
  };

  imports = builtins.attrValues availableModules;

  config = {
    jvf.system = mkModuleEnables // {
      hostName = lib.mkDefault config.jvf.system.hostName;
    };
  };
}
