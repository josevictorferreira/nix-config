{ lib, ... }:

let
  kebabToHuman =
    str:
    lib.concatMapStringsSep " "
      (
        word: lib.toUpper (lib.substring 0 1 word) + lib.substring 1 (-1) word
      )
      (lib.splitString "-" str);
in
{
  inherit kebabToHuman;
}
