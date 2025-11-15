# === System Configuration Module ===
# Centralized module that imports and manages all system-level modules
#
# Usage in host config:
#   jvf.system = {
#     enable = true;
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
  # Map of module name to file path
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

  # Helper: Check if a module is enabled
  isModuleEnabled = name: builtins.elem name config.jvf.system.modules;

  # Build enable settings for all modules
  mkModuleEnables = lib.mkMerge (
    map (name: lib.mkIf (isModuleEnabled name) {
      ${name} = {
        enable = true;
      } // lib.optionalAttrs (name == "networking") {
        hostName = config.jvf.system.hostName;
      };
    }) (builtins.attrNames availableModules)
  );
in
{
  # === OPTIONS ===
  options.jvf.system = with lib; {
    enable = mkEnableOption "jvf system module management" // {
      description = ''
        Enable the jvf.system module which provides centralized management
        of all system-level configuration modules.
      '';
    };

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
      example = [ "audio" "security" "networking" "base-programs" ];
      description = ''
        List of system modules to enable. Each module will be automatically
        enabled if its name appears in this list. Available modules:
        ${lib.generators.toPretty {} (builtins.attrNames availableModules)}
      '';
    };
  };

  # === CONFIG ===
  # Import all available system modules
  imports = builtins.attrValues availableModules;

  config = lib.mkIf config.jvf.system.enable {
    # Enable all modules specified in the modules array
    jvf.system = mkModuleEnables // {
      # Provide hostName for the networking module
      hostName = lib.mkDefault config.jvf.system.hostName;
    };
  };
}

