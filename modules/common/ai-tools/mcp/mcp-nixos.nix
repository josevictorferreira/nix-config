{ lib, pkgs, config, system, ... }:

let
  isDarwin = builtins.match "*-darwin" system != null;
  cfg = config.jvf.aiTools.mcp."mcp-nixos";
in
lib.mkIf (!isDarwin) {
  options.jvf.aiTools.mcp."mcp-nixos" = {
    enable = lib.mkEnableOption "NixOS MCP server (Linux only)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.mcp-nixos;
      description = lib.mdDoc "Package providing the NixOS MCP server.";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc "Additional arguments passed to the MCP executable.";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = lib.mdDoc "Environment variables for the MCP server.";
    };

    _output = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      readOnly = true;
      description = lib.mdDoc "Computed consumer output.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.aiTools.mcp."mcp-nixos"._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [ (lib.getExe cfg.package) ] ++ cfg.args;
        env = cfg.env;
      };
    };
  };
}

