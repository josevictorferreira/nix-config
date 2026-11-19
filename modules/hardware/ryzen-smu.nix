# Aspect: hardware-ryzen-smu
# ryzen_smu kernel driver: exposes the Ryzen SMU so BIOS tuning (PBO limits,
# Curve Optimizer offsets, PM table) can be inspected from Linux.
# NixOS-only (no Darwin equivalent).
_: {
  flake.modules.nixos.hardware-ryzen-smu = _: {
    hardware.cpu.amd.ryzen-smu.enable = true;
  };
}
