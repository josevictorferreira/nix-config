{ lib, ... }:

{
  toTOML =
    let
      # Escape a TOML key; if it is a string that's a valid identifier, we don't
      # need to add quotes
      tomlEscapeKey =
        val:
        # Identifier regex taken from https://toml.io/en/v1.0.0-rc.1#keyvalue-pair
        if builtins.isString val && builtins.match "[A-Za-z0-9_-]+" val != null then
          val
        else
          lib.generators.toJSON val;

      # Escape a TOML value
      tomlEscapeValue = lib.generators.toJSON;

      # Render a TOML value that appears on the right hand side of an equals
      tomlValue =
        v:
        if builtins.isList v then
          "[${lib.string.concatMapSep ", " tomlValue v}]"
        else if builtins.isAttrs v then
          "{${lib.string.concatMapSep ", " ({ name, value }: tomlKV name value) (lib.set.toList v)}}"
        else
          tomlEscapeValue v;

      # Render an inline TOML "key = value" pair
      tomlKV = k: v: "${tomlEscapeKey k} = ${tomlValue v}";

      # Turn a prefix like [ "foo" "bar" ] into an escaped header value like
      # "foo.bar"
      dots = lib.string.concatMapSep "." tomlEscapeKey;

      # Render a TOML table with a header
      tomlTable =
        oldPrefix: k: v:
        let
          prefix = oldPrefix ++ [ k ];
          rest = go prefix v;
        in
        "[${dots prefix}]" + lib.string.optional (rest != "") "\n${rest}";

      # Render a TOML array of attrsets using [[]] notation. 'subtables' should
      # be a list of attrsets.
      tomlTableArray =
        oldPrefix: k: subtables:
        let
          prefix = oldPrefix ++ [ k ];
        in
        lib.string.concatMapSep "\n\n" (
          v:
          let
            rest = go prefix v;
          in
          "[[${dots prefix}]]" + lib.string.optional (rest != "") "\n${rest}"
        ) subtables;

      # Wrap a string in a list, yielding the empty list if the string is empty
      optionalNonempty = str: lib.list.optional (str != "") str;

      # Render an attrset into TOML; when nested, 'prefix' will be a list of the
      # keys we're currently in
      go =
        prefix: attrs:
        let
          attrList = lib.set.toList attrs;

          # Render values that are objects using tables
          tableSplit = lib.list.partition ({ value, ... }: builtins.isAttrs value) attrList;
          tablesToml = lib.string.concatMapSep "\n\n" (
            { name, value }: tomlTable prefix name value
          ) tableSplit._0;

          # Use [[]] syntax only on arrays of attrsets
          tableArraySplit = lib.list.partition (
            { value, ... }: builtins.isList value && value != [ ] && lib.list.all builtins.isAttrs value
          ) tableSplit._1;
          tableArraysToml = lib.string.concatMapSep "\n\n" (
            { name, value }: tomlTableArray prefix name value
          ) tableArraySplit._0;

          # Everything else becomes bare "key = value" pairs
          pairsToml = lib.string.concatMapSep "\n" ({ name, value }: tomlKV name value) tableArraySplit._1;
        in
        lib.string.concatSep "\n\n" (
          lib.list.concatMap optionalNonempty [
            pairsToml
            tablesToml
            tableArraysToml
          ]
        );
    in
    go [ ];
}
