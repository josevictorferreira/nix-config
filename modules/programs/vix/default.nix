# Aspect: programs-vix
# Defines jvf.programs.vix options for vix (kirby88/vix-releases), an AI coding
# agent shipped as a prebuilt binary. The derivation lives in ./_/package.nix
# (excluded from import-tree by the /_/ segment) and is exposed to the user
# via jvf.wrappers, putting both `vix` and `vixd` on PATH.
#
# Runtime expectation: vix requires ANTHROPIC_API_KEY in the environment. Set
# it via your shell config or sops-nix — this module deliberately doesn't.
_:
let
  vixModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.vix;
      vixPkg = import ./_/package.nix { inherit pkgs; };
    in
    {
      options.jvf.programs.vix = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username to install vix for.";
        };
      };

      config = {
        # No `command` set → packages land in users.users.<u>.packages, which
        # exposes both vix and vixd on PATH (see modules/wrappers.nix).
        jvf.wrappers.users.${cfg.username}.programs.vix.packages = [ vixPkg ];
      };
    };
in
{
  flake.modules.nixos.programs-vix = vixModule;
  flake.modules.darwin.programs-vix = vixModule;
}
