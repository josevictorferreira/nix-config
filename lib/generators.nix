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

  mkValueString =
    v:
    if v == true then
      "True"
    else if v == false then
      "False"
    else if builtins.isNull v then
      "\"\"" # explicit empty string
    else if builtins.typeOf v == "string" then
      # quote and escape " and \
      let
        esc = lib.strings.escape [ "\"" "\\" ] v;
      in
      "\"${esc}\""
    else
      builtins.toString v;

  mkKeyValue = name: v: "${name} = ${mkValueString v}";

  toCONF =
    content:
    lib.generators.toINIWithGlobalSection
      {
        mkKeyValue = mkKeyValue;
      }
      {
        globalSection = flattenConfig content;
      };

  toFileFormatStr =
    type: content:
    if type == "yaml" || type == "yml" then
      toYAML content
    else if type == "json" then
      builtins.toJSON content
    else if type == "ini" then
      lib.generators.toINIWithGlobalSection { } { globalSection = flattenConfig content; }
    else if type == "conf" || type == "cfg" then
      toCONF content
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
