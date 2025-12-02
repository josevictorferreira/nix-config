{
  lib,
  pkgs,
  config,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.privacy;
  isDarwin = builtins.match ".*-darwin" system != null;
  protonmail = pkgs.protonmail-desktop;

  protonmailWrapped = pkgs.stdenv.mkDerivation {
    pname = "protonmail-desktop-wrapped";
    version = "1.9.1-with-ozone-x11";

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ protonmail ];

    unpackPhase = "true";

    installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/share/applications
          mkdir -p $out/share/icons/hicolor/256x256/apps

          cat > $out/bin/proton-mail <<'EOF'
      #!${pkgs.runtimeShell}
      exec ${protonmail}/bin/proton-mail --ozone-platform=x11 "$@"
      EOF
          chmod +x $out/bin/proton-mail

          cat > $out/share/applications/proton-mail.desktop <<EOF
          [Desktop Entry]
          Name=Proton Mail
          GenericName=Email Client
          Exec=$out/bin/proton-mail %U
          Terminal=false
          Type=Application
          Icon=proton-mail
          Categories=Network;Email;
          MimeType=x-scheme-handler/mailto;
          EOF

          cp ${protonmail}/share/pixmaps/proton-mail.png \
             $out/share/icons/hicolor/256x256/apps/proton-mail.png
    '';
  };
in
{
  options.jvf.roles.privacy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable some privacy related tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {

    users.users."${cfg.username}".packages = lib.mkMerge (
      lib.optional (!isDarwin) [
        pkgs.proton-pass
        pkgs.proton-authenticator
        pkgs.protonvpn-gui
        protonmailWrapped
      ]
    );
  };
}
