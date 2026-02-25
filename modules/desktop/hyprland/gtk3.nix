# Aspect: desktop-hyprland-gtk3 (NixOS only)
# GTK 3.0 settings, bookmarks, and folder icons for Hyprland.
_:
{
  flake.modules.nixos.desktop-hyprland-gtk3 =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.gtk3;

      # Bookmark entry type
      bookmarkType = lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path to the bookmarked folder";
            example = "/home/user/Documents";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Display name for the bookmark in Thunar sidebar";
            example = "Documents";
          };
          icon = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Icon name for the folder. Set to null for default folder icon.

              Common Flat-Remix icons:
              - Types: folder-development, folder-git, folder-github, folder-cloud,
                       folder-documents, folder-download, folder-pictures, folder-videos,
                       folder-music, folder-games, folder-steam, folder-script
              - Colors: folder-blue, folder-cyan, folder-green, folder-magenta,
                        folder-orange, folder-red, folder-teal, folder-violet,
                        folder-yellow, folder-brown, folder-grey, folder-black
              - Colored types: folder-blue-development, folder-green-git, etc.
            '';
            example = "folder-blue-development";
          };
        };
      };

      # Generate bookmarks file content from declarative config
      bookmarksContent = lib.concatStringsSep "\n" (map (b: "file://${b.path} ${b.name}") cfg.bookmarks);

      # Merge folder icons from both sources
      allFolderIcons =
        cfg.folderIcons
        // (lib.listToAttrs (
          lib.filter (x: x.value != null) (
            map
              (b: {
                name = b.path;
                value = b.icon;
              })
              cfg.bookmarks
          )
        ));

      # Generate gio set commands for folder icons
      folderIconCommands = lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (path: icon: ''
            if [ -d "${path}" ]; then
              if ${pkgs.glib}/bin/gio set "${path}" metadata::custom-icon-name "${icon}" 2>/dev/null; then
                echo "Set icon '${icon}' for ${path}"
              fi
            fi
          '')
          allFolderIcons
      );

      # Build the config directory with settings.ini and optional bookmarks
      configDir = pkgs.runCommand "gtk-3.0-config" { } ''
        mkdir -p $out
        cp ${./assets/gtk3/settings.ini} $out/settings.ini
        ${lib.optionalString (cfg.bookmarks != [ ]) ''
            cat > $out/bookmarks << 'EOF'
          ${bookmarksContent}
          EOF
        ''}
      '';
    in
    {
      options.jvf.desktop.hyprland.gtk3 = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure gtk3 wrapper";
        };

        bookmarks = lib.mkOption {
          type = lib.types.listOf bookmarkType;
          default = [ ];
          example = lib.literalExpression ''
            [
              { path = "/home/user/Documents"; name = "Documents"; icon = "folder-documents"; }
              { path = "/home/user/Workspace"; name = "Workspace"; icon = "folder-cyan-development"; }
              { path = "/home/user/.config/nix"; name = "NixConfig"; icon = "folder-orange-git"; }
            ]
          '';
          description = ''
            Declarative GTK bookmarks with optional custom icons.
            Each bookmark specifies path, display name, and optional icon.
            Icons are applied via gio metadata and displayed in Thunar/Nautilus.
          '';
        };

        folderIcons = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = lib.literalExpression ''
            {
              "/home/user/Workspace" = "folder-development";
              "/home/user/.config/nix" = "folder-git";
            }
          '';
          description = ''
            Additional folder paths mapped to icon names (for folders not in bookmarks).
            Uses gio metadata to set custom icons.
            Common icon names: folder-development, folder-git, folder-cloud,
            folder-documents, folder-download, folder-pictures, folder-videos.
          '';
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs."gtk-3.0" = {
          packages = [ ];
          configs = {
            "gtk-3.0" = configDir;
          };
          postInstall = lib.mkIf (allFolderIcons != { }) folderIconCommands;
        };
      };
    };
}
