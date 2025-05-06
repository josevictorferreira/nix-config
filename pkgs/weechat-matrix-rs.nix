{ lib, pkgs, ... }:

let
  rustPlatform = pkgs.rust.packages.stable.rustPlatform;
in
rustPlatform.buildRustPackage {
  pname = "weechat-matrix-rs";
  version = "0.1.0";
  src = pkgs.fetchFromGitHub {
    owner = "poljar";
    repo = "weechat-matrix-rs";
    rev = "2b093a7ff1c75650467d61335b90e4a6ce1fa210";
    sha256 = "P9SLZ2EefZ+ITYV3BRvtVsdbZaGeLZI0k67TdtGQMgs=";
  };
  nativeBuildInputs = [ pkgs.pkg-config pkgs.cmake ];
  buildInputs = [ pkgs.openssl pkgs.libclang ];
  cargoHash = "sha256-WJ9/Rj9KuKhGORsZf7fugTq3zOF5b0q8uA/VhqYpYos=";
  PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  buildPhase = ''
    export HOME=/tmp
    export CARGO_HOME=~/.cargo
    make install
  '';
}
