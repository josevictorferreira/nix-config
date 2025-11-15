{ lib
, pkgs
, config
, username
, ...
}:
let
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;

  aiTools = import ../../common/ai-tools { inherit lib pkgs; };

  mkMdConfigs =
    prefix: attrset:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = value;
      })
      attrset;
in
{
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./mcp.nix
    ./provider.nix
    ./permission.nix
  ];

  options.jvf.programs.opencode = {
    enable = lib.mkEnableOption "Install opencode and write per-user ~/.config/opencode/config.json";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.opencode = {
      packages = [
        pkgs.opencode
      ];
      configs = lib.mkMerge [
        (mkMdConfigs "agent" aiTools.agents)
        (mkMdConfigs "command" aiTools.commands)
        {
          "config.json" = cfg.settings;
        }
      ];
    };
  };
}
