# === Core Identity Options ===
# Provides jvf.core.{username, host, os} so modules can access
# host identity via config instead of specialArgs.
#
# Set these in each host's config.nix:
#   jvf.core = {
#     username = "josevictor";
#     host = "nixos-desktop";
#     os = "nixos";
#   };

{ lib, ... }:
{
  options.jvf.core = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary username for this host.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname identifier (e.g. nixos-desktop, macos-macbook).";
    };

    os = lib.mkOption {
      type = lib.types.str;
      description = "OS type: nixos, darwin, or macos.";
    };
  };
}
