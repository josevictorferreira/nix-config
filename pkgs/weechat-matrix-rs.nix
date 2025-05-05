{ lib, pkgs, ... }:

let
  rustPlatform = pkgs.rust.packages.stable.rustPlatform;
in
rustPlatform.buildRustPackage {
  pname = "weechat-matrix-rs";
  version = "master";
  src = builtins.fetchFromGitHub {
    owner = "poljar";
    repo = "weechat-matrix-rs";
    rev = "2b093a7ff1c75650467d61335b90e4a6ce1fa210";
    sha256 = "P9SLZ2EefZ+ITYV3BRvtVsdbZaGeLZI0k67TdtGQMgs=";
  };
  nativeBuildInputs = [ pkgs.pkg-config pkgs.cmake ];
  buildInputs = [ pkgs.weechat pkgs.openssl pkgs.libclang pkgs.libcxx pkgs.glibc ];
  cargoSha256 = "gwUBpSBCLDYiXtkFdeDBQDqfInY/ZVK3tP5V3CZEzD0=";
  PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  LIBCLANG_PATH = "${lib.getLib pkgs.libclang}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${lib.getVersion pkgs.clang}/include";
  WEECHAT_BUNDLED = true;
}
