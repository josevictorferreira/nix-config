{ inputs, ... }:

{
  imports = inputs.lib.filesystem.modulesInDir ./.;
}
