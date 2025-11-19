# === Hardware Configuration Module ===
# Centralized module that imports and manages all hardware modules
#
# Usage in host config:
#   jvf.hardware = {
#     active = [ "bluetooth" "logitech" ... ];
#   };
#
# This module will:
# 1. Import all child hardware modules
# 2. Set enable = true for each hardware config listed in the 'active' array
#
# Available hardware modules:
# - amd-gpu - AMD GPU support with ROCm runtime
# - bluetooth - Bluetooth hardware support with bluez stack
# - logitech - Logitech hardware (mice, keyboards, peripherals)

{ config, lib, ... }:
let
  availableHardware = {
    amd-gpu = ./amd-gpu.nix;
    bluetooth = ./bluetooth.nix;
    logitech = ./logitech.nix;
  };

  isHardwareEnabled = name: builtins.elem name config.jvf.hardware.active;

  mkHardwareEnables = lib.mkMerge (
    map (
      name:
      lib.mkIf (isHardwareEnabled name) {
        ${name} = {
          enable = true;
        };
      }
    ) (builtins.attrNames availableHardware)
  );
in
{
  options.jvf.hardware = with lib; {
    active = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "bluetooth"
        "logitech"
      ];
      description = ''
        List of hardware configurations to enable. Each hardware module will be
        automatically enabled if its name appears in this list. Available hardware:
        ${lib.generators.toPretty { } (builtins.attrNames availableHardware)}
      '';
    };
  };

  imports = builtins.attrValues availableHardware;

  config = {
    jvf.hardware = mkHardwareEnables;
  };
}
