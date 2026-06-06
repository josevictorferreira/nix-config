# Aspect: desktop-hyprland-gtk3 (NixOS only)
# GTK 3.0 settings, bookmarks, and folder icons for Hyprland.
# Theme adapter: generates settings.ini from jvf.theme.{gtk, fonts}.
# Profile artifacts: dark/light GTK configs for runtime theme switching.
_: {
  flake.modules.nixos.desktop-hyprland-gtk3 =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.gtk3;

      darkPreset = config.jvf.theme.presets.tokyonight-night;
      lightPreset = config.jvf.theme.presets.tokyonight-day;

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

      # Theme adapter: generate settings.ini from a preset's gtk + fonts config
      mkGtkConf =
        preset:
        let
          gtkPreset = preset.gtk;
          fontsPreset = preset.fonts;
        in
        pkgs.writeText "settings.ini" ''
          [Settings]
          gtk-theme-name=${gtkPreset.theme}
          gtk-icon-theme-name=${gtkPreset.iconTheme}
          gtk-font-name=${fontsPreset.sansSerif} Semi-Bold ${toString fontsPreset.size}
          gtk-cursor-theme-name=${gtkPreset.cursorTheme}
          gtk-cursor-theme-size=${toString gtkPreset.cursorSize}
          gtk-toolbar-style=GTK_TOOLBAR_ICONS
          gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
          gtk-button-images=1
          gtk-menu-images=1
          gtk-enable-event-sounds=1
          gtk-enable-input-feedback-sounds=0
          gtk-xft-antialias=1
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintslight
          gtk-xft-rgba=rgb
          gtk-application-prefer-dark-theme=${if gtkPreset.applicationPreferDarkTheme then "1" else "0"}
        '';

      # Current active config (for jvf.home deployment)
      generatedSettingsIni = mkGtkConf config.jvf.theme;

      # Build the config directory with generated settings.ini and optional bookmarks
      configDir = pkgs.runCommand "gtk-3.0-config" { } ''
        mkdir -p $out
        cp ${generatedSettingsIni} $out/settings.ini
        ${lib.optionalString (cfg.bookmarks != [ ]) ''
            cat > $out/bookmarks << 'EOF'
          ${bookmarksContent}
          EOF
        ''}
      '';

      # Profile artifacts for dual-theme runtime switching
      darkGtkArtifact = pkgs.runCommand "theme-gtk-dark" { } ''
        mkdir -p $out
        cp ${mkGtkConf darkPreset} $out/settings.ini
      '';
      lightGtkArtifact = pkgs.runCommand "theme-gtk-light" { } ''
        mkdir -p $out
        cp ${mkGtkConf lightPreset} $out/settings.ini
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
        };

        jvf.home.users.${cfg.username}.items.".config/gtk-3.0" = {
          kind = "dir";
          mode = "copy";
          source = configDir;
          postInstall = lib.mkIf (allFolderIcons != { }) folderIconCommands;
        };

        # Profile artifacts for dual-theme runtime switching
        jvf.theme.profileArtifacts.dark.gtk = darkGtkArtifact;
        jvf.theme.profileArtifacts.light.gtk = lightGtkArtifact;
      };
    };
}
