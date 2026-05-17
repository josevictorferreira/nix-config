# buildGoModule derivation for commandcode-proxy. Imported by ../default.nix.
{ buildGoModule, lib }:
buildGoModule {
  pname = "commandcode-proxy";
  version = "0.1.0";
  src = ./src;
  # No third-party Go deps yet; stdlib only.
  vendorHash = null;
  meta = {
    description = "Minimal OpenAI Chat Completions <-> Command Code translation proxy";
    mainProgram = "commandcode-proxy";
    license = lib.licenses.mit;
  };
}
