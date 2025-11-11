{ lib, pkgs, ... }:

let
  toConfigFormat =
    settings:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: value:
        if builtins.isBool value then if value then key else "" else "${key} = ${builtins.toString value}"
      ) settings
    );

  toYAML = data: builtins.readFile ((pkgs.formats.yaml { }).generate "." data);

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
          throw "\"null\" is not supported by TOML"
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

  # Recursively flatten nested attribute sets into dot-separated keys
  flattenConfig =
    attrs:
    lib.foldl' (
      acc: nameValue:
      let
        name = nameValue.name;
        value = nameValue.value;
      in
      if builtins.isAttrs value then
        acc
        // (flattenConfig (
          lib.mapAttrs' (k: v: {
            name = "${name}.${k}";
            value = v;
          }) value
        ))
      else
        acc // { "${name}" = value; }
    ) { } (lib.attrsToList attrs);

  toFileFormatStr =
    type: content:
    if type == "yaml" || type == "yml" then
      toYAML content
    else if type == "json" then
      builtins.toJSON content
    else if type == "ini" then
      lib.generators.toINIWithGlobalSection { } { globalSection = flattenConfig content; }
    else if type == "conf" || type == "cfg" then
      lib.generators.toINIWithGlobalSection { } { globalSection = flattenConfig content; }
    else if type == "toml" then
      toTOML content
    else
      content;
in
{
  inherit
    toConfigFormat
    toTOML
    toFileFormatStr
    flattenConfig
    ;
}
