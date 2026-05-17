# Binary-release derivation for vix (https://github.com/kirby88/vix-releases).
# Upstream ships prebuilt tarballs containing `vix` and `vixd`; we just fetch
# the right one for the host platform and run autoPatchelfHook on Linux so the
# binaries find glibc's ld-linux. Darwin binaries are used as-is.
#
# To bump the version: change `version`, then update each entry's `sha256`
# (run `nix-prefetch-url <url>` or copy the hex digest from the GitHub
# release's checksums.txt — fetchurl accepts hex directly).
{ pkgs }:
let
  version = "0.2.2";

  sources = {
    "x86_64-linux" = {
      asset = "vix-linux-amd64";
      sha256 = "fbe58317ae032acaaa64b70f1124ffa662c0a684051942b54ab611c7ad9da482";
    };
    "aarch64-linux" = {
      asset = "vix-linux-arm64";
      sha256 = "daa3fc19cf1326ccddc7f24fc4fc23464e5bdb8fda212f589c1fd0eecba4c2dd";
    };
    "aarch64-darwin" = {
      asset = "vix-darwin-arm64";
      sha256 = "6eb8fbb13bce87929d552aafca23b2682a1fe0b8400cfbfb8ac66301b5cc132b";
    };
  };

  system = pkgs.stdenv.hostPlatform.system;
  source =
    sources.${system}
      or (throw "vix: unsupported system '${system}' (supported: ${
        builtins.concatStringsSep ", " (builtins.attrNames sources)
      })");

  inherit (pkgs.stdenv) isDarwin;
in
pkgs.stdenv.mkDerivation {
  pname = "vix";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/kirby88/vix-releases/releases/download/v${version}/${source.asset}.tar.gz";
    inherit (source) sha256;
  };

  sourceRoot = source.asset;

  nativeBuildInputs = pkgs.lib.optionals (!isDarwin) [
    pkgs.autoPatchelfHook
  ];

  # Most Go binaries are statically linked, but autoPatchelfHook is cheap
  # insurance — and stdenv.cc.cc.lib covers the libstdc++/libgcc_s case if
  # any cgo dependency sneaks in.
  buildInputs = pkgs.lib.optionals (!isDarwin) [
    pkgs.stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 vix  $out/bin/vix
    install -Dm755 vixd $out/bin/vixd
    runHook postInstall
  '';

  meta = {
    description = "Sleek, fast, and token-efficient AI coding agent";
    homepage = "https://github.com/kirby88/vix-releases";
    license = pkgs.lib.licenses.unfree;
    platforms = builtins.attrNames sources;
    mainProgram = "vix";
    maintainers = [ ];
  };
}
