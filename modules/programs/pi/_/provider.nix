# _/provider.nix - Translate opencode providers to pi's models.json.
# Lives under _/ so import-tree skips it; ../default.nix imports it explicitly
# into the programs-pi aspect (where pkgs/options are properly in scope).
# Requires programs-opencode to be co-imported (e.g. via roles/ai-development.nix)
# so that config.jvf.programs.opencode.settings.provider is in scope.
{ config, lib, ... }:
let
  # opencode's `npm` SDK package -> pi's `api` enum.
  # Returns null for providers pi can't route (e.g. opencode's built-in
  # `huggingface` which has no `npm`/`baseURL` -- pi has its own builtin too).
  mapApi =
    npm:
    if npm == "@ai-sdk/anthropic" then
      "anthropic-messages"
    else if npm == "@ai-sdk/openai-compatible" then
      "openai-completions"
    else if npm == "@ai-sdk/nvidia" then
      "openai-completions"
    else
      null;

  # opencode wraps env refs as "{env:VAR}"; pi takes a bare env var name.
  stripEnvWrap =
    s:
    let
      m = builtins.match "[{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" s;
    in
    if m != null then builtins.elemAt m 0 else s;

  hasThinking = model: (model.options.thinking.type or null) == "enabled";

  # opencode variants (thinker/fast) have no direct pi equivalent and are dropped;
  # the base model is still registered.
  translateModel =
    id: model:
    {
      inherit id;
    }
    // lib.optionalAttrs (model ? name) { inherit (model) name; }
    // lib.optionalAttrs (hasThinking model) { reasoning = true; }
    // lib.optionalAttrs (model ? modalities.input) { input = model.modalities.input; }
    // lib.optionalAttrs (model ? limit.context) { contextWindow = model.limit.context; }
    // lib.optionalAttrs (model ? limit.output) { maxTokens = model.limit.output; }
    // lib.optionalAttrs (model ? max_tokens) { maxTokens = model.max_tokens; };

  translateProvider =
    _name: provider:
    let
      api = mapApi (provider.npm or "");
      baseUrl = provider.options.baseURL or null;
      apiKeyRaw = provider.options.apiKey or null;
    in
    if api == null || baseUrl == null then
      null
    else
      {
        inherit baseUrl api;
        # Pi requires apiKey when models are defined; auth-less local servers
        # ignore the value, so a literal placeholder is fine.
        apiKey = if apiKeyRaw != null then stripEnvWrap apiKeyRaw else "local";
        models = lib.mapAttrsToList translateModel (provider.models or { });
      };

  omniroute = config.jvf.programs.opencode.settings.provider."omniroute" or null;
  piProviders = lib.optionalAttrs (omniroute != null) {
    "omniroute" = translateProvider "omniroute" omniroute;
  };
in
{
  config.jvf.programs.pi.models = lib.mkIf (piProviders != { }) {
    providers = piProviders;
  };
}
