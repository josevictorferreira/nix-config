{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.gtk3;

  # Generate gio set commands for folder icons
  # Note: This may fail during system activation if gvfs isn't running.
  # Icons will be set on next user login when gvfs is available.
  folderIconCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (path: icon: ''
        if [ -d "${path}" ]; then
          if ${pkgs.glib}/bin/gio set "${path}" metadata::custom-icon-name "${icon}" 2>/dev/null; then
            echo "Set icon '${icon}' for ${path}"
          fi
        fi
      '')
      cfg.folderIcons
  );
in
{
  options.jvf.desktop.hyprland.gtk3 = {
    enable = lib.mkEnableOption "Gtk 3.0 settings.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure gtk3 wrapper";
    };
    folderIcons = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          "/home/user/Workspace" = "folder-development";
          "/home/user/.config/nix" = "folder-nix";
        }
      '';
      description = ''
        Folder paths mapped to icon names. Uses gio metadata to set custom icons.
        Common icon names: folder-development, folder-git, folder-cloud,
        folder-documents, folder-download, folder-pictures, folder-videos.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs."gtk-3.0" = {
      packages = [ ];
      configs = {
        "gtk-3.0" = ./.;
      };
      postInstall = lib.mkIf (cfg.folderIcons != { }) folderIconCommands;
    };
  };
}
