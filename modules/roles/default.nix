{ jvfLib, ... }:

{
  imports = jvfLib.filesystem.importModulesInDir ./.;
}
