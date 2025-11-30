# === Roles Configuration Module ===
# Centralized module that imports and manages all role modules
#
# Usage in host config:
#   jvf.roles = {
#     roles = [ "development" "aiDevelopment" "media" ... ];
#   };
#
# This module will:
# 1. Import all role modules
# 2. Set enable = true for each role listed in the 'roles' array
#
# Available roles:
# - aiDevelopment - AI/vibe coding tools (Cursor, Goose, OpenCode, etc.)
# - communication - Chat and communication applications
# - designing - Design and creative tools
# - development - Core development tools (editors, terminals, utilities)
# - documenting - Documentation tools
# - gaming - Gaming platforms (Steam, Wine, Lutris) - NixOS only
# - media - Media tools and consumption
# - monitoring - System monitoring and observability
# - networkStorage - NAS and storage management
# - opsDevelopment - DevOps tools (kubectl, helm, awscli, etc.)

{
  config,
  lib,
  username,
  ...
}:
let
  availableRoles = {
    aiDevelopment = ./ai-development.nix;
    communication = ./communication.nix;
    designing = ./designing.nix;
    development = ./development.nix;
    documenting = ./documenting.nix;
    gaming = ./gaming.nix;
    localAi = ./local-ai.nix;
    media = ./media.nix;
    monitoring = ./monitoring.nix;
    networkStorage = ./network-storage.nix;
    opsDevelopment = ./ops-development.nix;
    privacy = ./privacy.nix;
  };

  isRoleEnabled = name: builtins.elem name config.jvf.roles.active;

  mkRoleEnables = lib.mkMerge (
    map (
      name:
      lib.mkIf (isRoleEnabled name) {
        ${name} = {
          enable = true;
          inherit username;
        };
      }
    ) (builtins.attrNames availableRoles)
  );
in
{
  options.jvf.roles = with lib; {
    active = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "development"
        "aiDevelopment"
        "media"
        "opsDevelopment"
      ];
      description = ''
        List of roles to enable. Each role will be automatically
        enabled if its name appears in this list. Available roles:
        ${lib.generators.toPretty { } (builtins.attrNames availableRoles)}
      '';
    };
  };

  imports = builtins.attrValues availableRoles;

  config = {
    jvf.roles = mkRoleEnables;
  };
}
