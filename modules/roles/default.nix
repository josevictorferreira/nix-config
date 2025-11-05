{ jvfLib, ... }:

{
  imports = jvfLib.filesystem.modulesInDir ./.;
}
