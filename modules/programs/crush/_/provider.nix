# _/provider.nix - Translate opencode's omniroute provider to Crush's crush.json format.
# Lives under _/ so import-tree skips it; ../default.nix imports it explicitly
# into the programs-crush aspect (where pkgs/options are properly in scope).
# Requires programs-opencode to be co-imported (e.g. via roles/ai-development.nix)
# so that config.jvf.programs.opencode.settings.provider is in scope.
{ config, lib, ... }:
let
  # opencode's `npm` SDK package -> Crush's `type` enum.
  # See: https://github.com/charmbracelet/crush#custom-providers
  mapType =
    npm:
    if npm == "@ai-sdk/openai-compatible" then
      "openai-compat"
    else if npm == "@ai-sdk/anthropic" then
      "anthropic"
    else
      null;

  # opencode wraps env refs as "{env:VAR}"; Crush uses "$VAR".
  toCrushEnv =
    s:
    let
      m = builtins.match "[{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" s;
    in
    if m != null then "$" + builtins.elemAt m 0 else s;

  # opencode models are attrs (id -> attrs); Crush wants a list.
  toCrushModels =
    models:
    lib.mapAttrsToList
      (
        id: model: { inherit id; } // lib.optionalAttrs (model ? name) { inherit (model) name; }
      )
      models;

  translateProvider =
    name: provider:
    let
      type = mapType (provider.npm or "");
      baseUrl = provider.options.baseURL or null;
      apiKeyRaw = provider.options.apiKey or null;
    in
    if type == null || baseUrl == null then
      null
    else
      {
        inherit type;
        base_url = baseUrl;
        api_key = if apiKeyRaw != null then toCrushEnv apiKeyRaw else "";
        models = toCrushModels (provider.models or { });
      };

  # Only extract omniroute from opencode's provider config
  omniroute = config.jvf.programs.opencode.settings.provider."omniroute" or null;
  omnirouteCrush = lib.optionalAttrs (omniroute != null) {
    providers."omniroute" = translateProvider "omniroute" omniroute;
  };
in
{
  config.jvf.programs.crush.settings = lib.mkMerge [
    (lib.mkIf (omniroute != null) omnirouteCrush)
  ];
}
