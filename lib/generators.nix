{ pkgs, ... }:

{
  toTOML = name: src: (pkgs.formats.toml { }).generate name src;
}
