{ lib }:

let
  types = lib.types;
  packageType = types.package;
  pathType = types.path;
in
rec {

  agentType = types.submodule ({ ... }: {
    options = {
      enable = lib.mkEnableOption "AI agent";

      name = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Display name for the agent.";
      };

      description = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Short description of the agent's focus.";
      };

      tools = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "List of tools the agent may use.";
      };

      prompt = lib.mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc "Multi-line prompt defining the agent.";
      };

      _output = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        readOnly = true;
        description = lib.mdDoc "Computed consumer output (reserved).";
      };
    };

    freeformType = types.attrsOf types.anything;
  });

  commandType = types.submodule ({ ... }: {
    options = {
      enable = lib.mkEnableOption "AI command";

      name = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Display name for the command.";
      };

      description = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Short description of the command.";
      };

      tools = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "List of tools the command may use.";
      };

      prompt = lib.mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc "Multi-line prompt defining the command.";
      };

      _output = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        readOnly = true;
        description = lib.mdDoc "Computed consumer output (reserved).";
      };
    };

    freeformType = types.attrsOf types.anything;
  });

  mcpLocalType = types.submodule ({ ... }: {
    options = {
      enable = lib.mkEnableOption "Local MCP server";

      package = lib.mkOption {
        type = types.nullOr packageType;
        default = null;
        description = lib.mdDoc "Package providing the MCP server.";
      };

      executable = lib.mkOption {
        type = types.nullOr pathType;
        default = null;
        description = lib.mdDoc "Executable path for the MCP server.";
      };

      args = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "Arguments passed to the MCP executable.";
      };

      env = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = lib.mdDoc "Environment variables for the MCP server.";
      };

      _output = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        readOnly = true;
        description = lib.mdDoc "Computed consumer output (reserved).";
      };
    };

    freeformType = types.attrsOf types.anything;
  });

  mcpRemoteType = types.submodule ({ ... }: {
    options = {
      enable = lib.mkEnableOption "Remote MCP server";

      url = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Remote MCP endpoint URL.";
      };

      headers = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = lib.mdDoc "HTTP headers to send to the MCP server.";
      };

      _output = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        readOnly = true;
        description = lib.mdDoc "Computed consumer output (reserved).";
      };
    };

    freeformType = types.attrsOf types.anything;
  });

  mcpType = types.either mcpLocalType mcpRemoteType;
}
