{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  inherit (lib) mkIf;
  json = pkgs.formats.json { };
  cfg = config.jvf.programs.opencode;
  configPath = json.generate "opencode-config.json" cfg.settings;
  sanitize = name: lib.replaceStrings [ "/" " " ] [ "_" "-" ] name;
  aiTools = import ../../common/ai-tools { inherit lib pkgs; };
  agentEntries = lib.mapAttrsToList (name: text: {
    rel = "agent/${sanitize name}.md";
    src = pkgs.writeText "agent-${sanitize name}.md" text;
  }) aiTools.agents;
  commandEntries = lib.mapAttrsToList (name: text: {
    rel = "command/${sanitize name}.md";
    src = pkgs.writeText "command-${sanitize name}.md" text;
  }) aiTools.commands;
  installAgents = lib.concatStringsSep "\n" (
    map (e: ''
      install -m 0644 -D ${e.src} "$dest/${e.rel}"
    '') agentEntries
  );
  installCommands = lib.concatStringsSep "\n" (
    map (e: ''
      install -m 0644 -D ${e.src} "$dest/${e.rel}"
    '') commandEntries
  );
  opencodePkg = pkgs.writeShellScriptBin "opencode" ''
    ${pkgs.bun}/bin/bunx opencode-ai@latest "$@"
  '';
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

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Settings written to ~/.config/opencode/config.json";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ opencodePkg ];

    jvf.programs.opencode.settings = {
      theme = "one-dark";
      model = "deepseek/deepseek-v3.2-exp";
      autoshare = false;
      autoupdate = false;
    };

    system.activationScripts.opencode = lib.stringAfter [ "users" ] ''
      set -euo pipefail
      user="${username}"
      home="$(getent passwd "$user" | cut -d: -f6 || true)"
      if [ -n "$home" ] && [ -d "$home" ]; then
        dest="$home/.config/opencode"

        group="$(id -gn "$user" 2>/dev/null || echo users)"

        mkdir -p "$dest" "$dest/agent" "$dest/command"

        # config.json
        install -m 0644 -D ${configPath} "$dest/config.json"

        # agents
        ${installAgents}

        # commands
        ${installCommands}

        chown -R "$user":"$group" "$dest"
      else
        echo "opencode: user '$user' not found or has no home directory" >&2
      fi
    '';
  };
}
