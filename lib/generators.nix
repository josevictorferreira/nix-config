{ lib, ... }:

let
  toConfigFormat =
    settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (
          key: value:
          if builtins.isBool value then if value then key else "" else "${key} = ${builtins.toString value}"
        )
        settings
    );

  toTOML =
    let
      inherit (builtins)
        toJSON
        concatStringsSep
        isAttrs
        isList
        isFloat
        ;
      inherit (lib) isStringLike concatMapStringsSep mapAttrsToList;

      inf = 1.0e308 * 10;

      toTopLevel =
        obj: concatStringsSep "" (mapAttrsToList (name: value: "${toJSON name}=${toInline value}\n") obj);

      toInline =
        obj:
        if isAttrs obj && !isStringLike obj then
          "{${concatStringsSep "," (mapAttrsToList (name: value: "${toJSON name}=${toInline value}") obj)}}"
        else if isList obj then
          "[${concatMapStringsSep "," toInline obj}]"
        else if obj == null then
          throw "“null” is not supported by TOML"
        else if !isFloat obj then
          toJSON obj
        else if obj == inf then
          "inf"
        else if obj == -inf then
          "-inf"
        else if obj != obj then
          "nan"
        else
          toJSON obj;
    in
    toTopLevel;

  toFileFormatStr =
    type: content:
    if type == "yaml" || type == "yml" then
      lib.generators.toYAML { } content
    else if type == "ini" then
      lib.generators.toINIWithGlobalSection { } { globalSection = content; }
    else if type == "toml" then
      toTOML content
    else
      content;
in
{
  inherit toConfigFormat toTOML toFileFormatStr;
}
