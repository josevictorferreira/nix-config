{ lib
, ...
}:

let
  # Retrieves a list of modules inside a dir
  modulesInDir =
    dir:
    let
      allFileNames = builtins.attrNames (builtins.readDir dir);
      nixFileNames = lib.filter
        (
          fileName: (lib.strings.hasSuffix ".nix" fileName) && (fileName != "default.nix")
        )
        allFileNames;
    in
    lib.map (fileName: dir + "/${fileName}") nixFileNames;

in
{
  inherit
    modulesInDir
    ;
}
