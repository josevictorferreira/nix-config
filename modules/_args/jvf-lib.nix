{ lib, pkgs, ... }:

{
  _module.args.jvfLib = import ../../lib {
    inherit lib pkgs;
  };
}
