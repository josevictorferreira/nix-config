# Aspect: programs-lsp-mcp
# User-level config for `language-server-mcp` (the `lsp` MCP server wired into
# Pi via pi-mcp-adapter, see roles/ai-development.nix).
#
# The MCP server resolves a language-server command in this order:
#   configured `command` -> system PATH -> cached managed install -> download.
# Downloads of prebuilt archives do not run on NixOS (wrong dynamic linker), so
# servers that are not in the MCP server's built-in registry get an explicit
# store-path command here. Registry built-ins (gopls, rust-analyzer,
# typescript-language-server, ...) already resolve from PATH because
# programs-neovim installs them into the user profile.
_:
let
  mkConfig =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.lsp-mcp;
    in
    {
      options.jvf.programs.lsp-mcp = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to install the lsp-mcp configuration.";
        };
      };

      config = {
        jvf.home.users.${cfg.username}.items.".config/lsp-mcp/config.json" = {
          kind = "file";
          mode = "copy";
          json = {
            lsp.servers = {
              # Not a built-in registry entry, so declared as a custom stdio
              # server. `.lua` deliberately excluded -- it belongs to lua_ls.
              luau-lsp = {
                command = lib.getExe pkgs.luau-lsp;
                args = [ "lsp" ];
                languageIds = [ "luau" ];
                extensions = [ ".luau" ];
              };
            };
          };
        };
      };
    };
in
{
  flake.modules.nixos.programs-lsp-mcp = mkConfig;
  flake.modules.darwin.programs-lsp-mcp = mkConfig;
}
